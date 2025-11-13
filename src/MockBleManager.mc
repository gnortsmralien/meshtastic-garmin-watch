// MockBleManager.mc
//
// Mock BLE manager for simulator testing - simulates BLE behavior without real hardware

using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;

class MockBleManager {
    // Connection states (same as SimpleBleManager)
    enum ConnectionState {
        STATE_DISCONNECTED,
        STATE_SCANNING,
        STATE_CONNECTING,
        STATE_CONNECTED,
        STATE_READY
    }
    
    private var _connectionState = STATE_DISCONNECTED;
    private var _profileRegistered = false;
    private var _scanTimer = null;
    private var _connectTimer = null;
    private var _dataCallback = null;
    
    // Mock devices that will be "found" during scanning
    private var _mockDevices = [
        { :name => "Meshtastic_1234", :address => "AA:BB:CC:DD:EE:01", :rssi => -45 },
        { :name => "Meshtastic_5678", :address => "AA:BB:CC:DD:EE:02", :rssi => -62 },
        { :name => "Meshtastic_ABCD", :address => "AA:BB:CC:DD:EE:03", :rssi => -78 }
    ];
    
    function initialize() {
        System.println("[MOCK] BLE Manager initialized");
    }
    
    function registerProfile() {
        System.println("[MOCK] Registering BLE profile...");
        
        // Simulate successful profile registration
        _profileRegistered = true;
        System.println("[MOCK] ✓ BLE profile registered successfully");
        return true;
    }
    
    function getConnectionState() {
        return _connectionState;
    }
    
    function isConnected() {
        return _connectionState == STATE_READY;
    }
    
    function startScan() {
        if (_connectionState != STATE_DISCONNECTED) {
            System.println("[MOCK] Cannot scan while not disconnected");
            return false;
        }
        
        System.println("[MOCK] Starting BLE scan...");
        _connectionState = STATE_SCANNING;
        
        // Simulate finding devices after a delay
        if (_scanTimer != null) {
            _scanTimer.stop();
        }
        _scanTimer = new Timer.Timer();
        var scanMethod = new Lang.Method(self, :simulateScanResults);
        _scanTimer.start(scanMethod, 2000, false); // Find devices after 2 seconds
        
        return true;
    }
    
    function simulateScanResults() as Void {
        System.println("[MOCK] Scan results ready - found " + _mockDevices.size() + " devices");

        // In a real implementation, this would trigger the delegate callback
        // For now, we'll just log it
        for (var i = 0; i < _mockDevices.size(); i++) {
            var device = _mockDevices[i];
            System.println("[MOCK] Found: " + device[:name] + " RSSI: " + device[:rssi]);
        }
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
        // Simulate successful connection (80% success rate)
        var success = (System.getTimer() % 10) < 8;

        if (success) {
            System.println("[MOCK] ✓ Connection established!");
            _connectionState = STATE_CONNECTED;

            // Simulate moving to ready state after handshake
            var readyTimer = new Timer.Timer();
            var readyMethod = new Lang.Method(self, :simulateHandshakeComplete);
            readyTimer.start(readyMethod, 1000, false);
        } else {
            System.println("[MOCK] ✗ Connection failed!");
            _connectionState = STATE_DISCONNECTED;
        }
    }
    
    function simulateHandshakeComplete() as Void {
        System.println("[MOCK] ✓ Handshake complete - ready for messaging");
        _connectionState = STATE_READY;

        // Simulate receiving some data
        if (_dataCallback != null) {
            var mockData = [0x94, 0xC3, 0x00, 0x05, 0x01, 0x02, 0x03, 0x04, 0x05]b;
            _dataCallback.invoke(mockData, null);
        }
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
            sendTimer.start(new Lang.Method(callback, :invoke), 100, false);
        }
        
        return true;
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