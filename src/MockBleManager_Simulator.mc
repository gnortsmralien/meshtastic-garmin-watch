// MockBleManager_Simulator.mc
//
// Mock BLE manager for simulator testing - simulates BLE behavior without real hardware
// This file provides a BleManager class for simulator builds to avoid crashes

using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using ProtoBuf;

class BleManager {
    // Connection states (same as real BleManager)
    enum ConnectionState {
        STATE_DISCONNECTED,
        STATE_SCANNING,
        STATE_CONNECTING,
        STATE_CONNECTED,
        STATE_SYNCING,
        STATE_READY
    }

    private var _connectionState = STATE_DISCONNECTED;
    private var _profileRegistered = false;
    private var _scanTimer = null;
    private var _connectTimer = null;
    private var _dataCallback = null;
    private var _connectionCallback = null;
    private var _pinCallback = null;
    private var _settingsManager = null;
    private var _encoder = null;
    
    // Mock devices that will be "found" during scanning
    private var _mockDevices = [
        { :name => "Meshtastic_1234", :address => "AA:BB:CC:DD:EE:01", :rssi => -45 },
        { :name => "Meshtastic_5678", :address => "AA:BB:CC:DD:EE:02", :rssi => -62 },
        { :name => "Meshtastic_ABCD", :address => "AA:BB:CC:DD:EE:03", :rssi => -78 }
    ];
    
    function initialize(settingsManager) {
        _settingsManager = settingsManager;
        _encoder = new ProtoBuf.Encoder();
        System.println("[MOCK] BLE Manager initialized");
    }

    function setPinCallback(callback) {
        _pinCallback = callback;
    }

    function registerProfile() {
        System.println("[MOCK] Registering BLE profile...");

        // Simulate successful profile registration (no crash!)
        _profileRegistered = true;
        System.println("[MOCK] ✓ BLE profile registered successfully (simulated)");
        return true;
    }

    function getConnectionState() {
        return _connectionState;
    }

    function isConnected() {
        return _connectionState == STATE_READY;
    }

    function startScan(callback) {
        if (_connectionState != STATE_DISCONNECTED) {
            System.println("[MOCK] Cannot scan while not disconnected");
            return false;
        }

        _connectionCallback = callback;
        System.println("[MOCK] Starting BLE scan...");
        _connectionState = STATE_SCANNING;

        // Simulate finding devices after a delay
        if (_scanTimer != null) {
            _scanTimer.stop();
        }
        _scanTimer = new Timer.Timer();
        _scanTimer.start(method(:simulateScanResults), 3000, false); // Find devices after 3 seconds

        return true;
    }

    function simulateScanResults() as Void {
        System.println("[MOCK] Scan complete - found " + _mockDevices.size() + " devices");

        for (var i = 0; i < _mockDevices.size(); i++) {
            var device = _mockDevices[i];
            System.println("[MOCK] Found: " + device[:name] + " RSSI: " + device[:rssi]);
        }

        // Auto-connect to first device
        connectToDevice(0);
    }
    
    function stopScan() {
        System.println("[MOCK] Stopping BLE scan");
        
        if (_scanTimer != null) {
            _scanTimer.stop();
            _scanTimer = null;
        }
        
        if (_connectionState == STATE_SCANNING) {
            _connectionState = STATE_DISCONNECTED;
        }
    }
    
    function connectToDevice(deviceIndex) {
        if (deviceIndex < 0 || deviceIndex >= _mockDevices.size()) {
            System.println("[MOCK] Invalid device index");
            return false;
        }
        
        var device = _mockDevices[deviceIndex];
        System.println("[MOCK] Connecting to " + device[:name] + "...");
        
        _connectionState = STATE_CONNECTING;
        
        // Simulate connection process
        if (_connectTimer != null) {
            _connectTimer.stop();
        }
        _connectTimer = new Timer.Timer();
        var connectMethod = new Lang.Method(self, :simulateConnectionComplete);
        _connectTimer.start(connectMethod, 1500, false); // Connect after 1.5 seconds
        
        return true;
    }
    
    function simulateConnectionComplete() as Void {
        System.println("[MOCK] ✓ Connection established!");
        _connectionState = STATE_CONNECTED;

        // Notify success
        if (_connectionCallback != null) {
            _connectionCallback.invoke(true, null);
        }

        // Simulate moving to syncing then ready state
        _connectionState = STATE_SYNCING;
        var readyTimer = new Timer.Timer();
        readyTimer.start(method(:simulateHandshakeComplete), 1000, false);
    }

    function simulateHandshakeComplete() as Void {
        System.println("[MOCK] ✓ Handshake complete - ready for messaging");
        _connectionState = STATE_READY;

        // Simulate receiving initial config data with mock node info
        if (_dataCallback != null) {
            simulateInitialConfig();
        }
    }

    // Simulate initial config sync with node database
    function simulateInitialConfig() as Void {
        System.println("[MOCK] Simulating initial config sync...");

        // Skip node info to avoid watchdog timeout
        // Just send config complete directly after a short delay
        var completeTimer = new Timer.Timer();
        completeTimer.start(method(:simulateConfigComplete), 500, false);
    }

    function simulateNodeDatabase() as Void {
        System.println("[MOCK] Sending node database");

        // Simulate fewer nodes to avoid watchdog timeout
        // Just send config complete directly
        simulateConfigComplete();
    }

    function simulateConfigComplete() as Void {
        System.println("[MOCK] Sending config_complete");

        // Use minimal encoding to avoid watchdog timeout
        // Just set the config complete flag directly in MessageHandler
        // by sending a simple hand-crafted message
        var mockData = buildSimpleConfigComplete();
        if (_dataCallback != null && mockData != null) {
            _dataCallback.invoke(mockData, null);
        }
    }

    // Build a very simple config complete message without heavy encoding
    function buildSimpleConfigComplete() {
        // Minimal FromRadio with just config_complete_id field
        // Field 6, varint, value 1
        var proto = [0x30, 0x01]b;  // Field 6 (0x30 = field 6 << 3 | wiretype 0), value 1

        // Wrap with streaming header
        var wrapped = [
            0x94, 0xC3,  // START1, START2
            0x00, 0x02   // Length = 2
        ]b;

        return wrapped.addAll(proto);
    }

    // Build mock protobuf messages using real encoder
    function buildMockMyNodeInfo(nodeNum) {
        var myInfo = {
            :my_node_num => nodeNum
        };

        var fromRadio = {
            :my_info => _encoder.encode(myInfo, ProtoBuf.SCHEMA_MYNODEINFO)
        };

        var encoded = _encoder.encode(fromRadio, ProtoBuf.SCHEMA_FROMRADIO);
        return ProtoBuf.wrap(encoded);
    }

    function buildMockNodeInfo(node) {
        var user = {
            :long_name => node[:name].toUtf8Array(),
            :short_name => node[:name].substring(0, 4).toUtf8Array()
        };

        var nodeInfo = {
            :num => node[:num],
            :user => _encoder.encode(user, ProtoBuf.SCHEMA_USER)
        };

        var fromRadio = {
            :node_info => _encoder.encode(nodeInfo, ProtoBuf.SCHEMA_NODEINFO)
        };

        var encoded = _encoder.encode(fromRadio, ProtoBuf.SCHEMA_FROMRADIO);
        return ProtoBuf.wrap(encoded);
    }

    function buildMockConfigComplete(configId) {
        var fromRadio = {
            :config_complete_id => configId
        };

        var encoded = _encoder.encode(fromRadio, ProtoBuf.SCHEMA_FROMRADIO);
        return ProtoBuf.wrap(encoded);
    }
    
    function disconnect() {
        System.println("[MOCK] Disconnecting...");
        
        if (_scanTimer != null) {
            _scanTimer.stop();
            _scanTimer = null;
        }
        if (_connectTimer != null) {
            _connectTimer.stop();
            _connectTimer = null;
        }
        
        _connectionState = STATE_DISCONNECTED;
        System.println("[MOCK] ✓ Disconnected");
    }
    
    function sendData(data, callback) {
        if (_connectionState != STATE_READY) {
            System.println("[MOCK] Not ready to send data");
            if (callback != null) {
                callback.invoke(false, "Not connected");
            }
            return false;
        }

        System.println("[MOCK] Sending " + data.size() + " bytes...");

        // Simulate successful send
        if (callback != null) {
            var sendTimer = new Timer.Timer();
            sendTimer.start(method(:notifySendSuccess), 100, false);
        }

        // Simulate receiving ACK after a short delay
        var ackTimer = new Timer.Timer();
        ackTimer.start(method(:simulateMessageAck), 1500, false);

        return true;
    }

    function notifySendSuccess() as Void {
        // Callback for successful write was passed in, but we can't easily store it
        // In real implementation, we'd track pending callbacks
        System.println("[MOCK] ✓ Data sent successfully");
    }

    function simulateMessageAck() as Void {
        System.println("[MOCK] Simulating message ACK from node");

        // Simulate receiving an ACK packet
        // In Meshtastic, ACKs are routing packets with routing.error_reason = NONE
        var mockAck = buildMockAck(0x87654321); // ACK from "Base Station"

        if (_dataCallback != null && mockAck != null) {
            _dataCallback.invoke(mockAck, null);
        }

        // Also simulate receiving a text reply after a bit
        var replyTimer = new Timer.Timer();
        replyTimer.start(method(:simulateTextReply), 2000, false);
    }

    function simulateTextReply() as Void {
        System.println("[MOCK] Simulating text message reply");

        var mockReply = buildMockTextMessage(
            0x87654321,  // From "Base Station"
            "Message received! Testing mock mesh network."
        );

        if (_dataCallback != null && mockReply != null) {
            _dataCallback.invoke(mockReply, null);
        }
    }

    function buildMockAck(fromNode) {
        // Simplified ACK packet
        var data = [
            0x94, 0xC3,  // Streaming header
            0x00, 0x0C,  // Length
            0x18, 0x01,  // Field 3 (packet)
            // From node
            (fromNode >> 24) & 0xFF,
            (fromNode >> 16) & 0xFF,
            (fromNode >> 8) & 0xFF,
            fromNode & 0xFF,
            // ACK indicator
            0x20, 0x00, 0x00, 0x00
        ]b;
        return data;
    }

    function buildMockTextMessage(fromNode, text) {
        // This is extremely simplified - real protobuf encoding is much more complex
        // Just enough to trigger the message handler
        var data = [
            0x94, 0xC3,  // Streaming header
            0x00, 0x20,  // Length (32 bytes - simplified)
            0x18, 0x01,  // Field 3 (packet - MeshPacket)
            // From node number
            (fromNode >> 24) & 0xFF,
            (fromNode >> 16) & 0xFF,
            (fromNode >> 8) & 0xFF,
            fromNode & 0xFF,
            // Simplified decoded data field with text
            0x08, 0x01,  // Portnum (TEXT_MESSAGE_APP)
            // Text payload (first 16 chars)
            0x54, 0x65, 0x73, 0x74, 0x20, 0x6D, 0x73, 0x67,
            0x20, 0x66, 0x72, 0x6F, 0x6D, 0x20, 0x6D, 0x6F,
            0x63, 0x6B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        ]b;
        return data;
    }
    
    function setDataCallback(callback) {
        _dataCallback = callback;
    }
    
    // Mock-specific methods for testing
    function getMockDevices() {
        return _mockDevices;
    }
    
    function simulateDeviceFound(name, rssi) {
        var newDevice = {
            :name => name,
            :address => "AA:BB:CC:DD:EE:" + (_mockDevices.size() + 1),
            :rssi => rssi
        };
        _mockDevices.add(newDevice);
        System.println("[MOCK] Added device: " + name);
    }
}