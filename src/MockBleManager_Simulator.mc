// MockBleManager_Simulator.mc
//
// Mock BLE manager for simulator testing - simulates BLE behavior without real hardware
// This file provides a BleManager class for simulator builds to avoid crashes

using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;

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
    
    // Mock devices that will be "found" during scanning
    private var _mockDevices = [
        { :name => "Meshtastic_1234", :address => "AA:BB:CC:DD:EE:01", :rssi => -45 },
        { :name => "Meshtastic_5678", :address => "AA:BB:CC:DD:EE:02", :rssi => -62 },
        { :name => "Meshtastic_ABCD", :address => "AA:BB:CC:DD:EE:03", :rssi => -78 }
    ];
    
    function initialize(settingsManager) {
        _settingsManager = settingsManager;
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

        // Simulate receiving some mock data
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