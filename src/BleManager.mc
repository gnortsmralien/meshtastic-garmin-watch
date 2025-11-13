// BleManager.mc
//
// Core BLE management class for Meshtastic communication
// Handles scanning, connection, and GATT profile registration

using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;

class BleManager {
    // Meshtastic BLE Service and Characteristic UUIDs
    static const MESH_SERVICE_UUID = Ble.stringToUuid("6ba1b218-15a8-461f-9fa8-5dcae273eafd");
    static const TO_RADIO_UUID = Ble.stringToUuid("f75c76d2-82c7-455b-9721-6b7538f49493");
    static const FROM_RADIO_UUID = Ble.stringToUuid("26432193-4482-4648-b425-4c07c409e0e5");
    static const FROM_NUM_UUID = Ble.stringToUuid("18cd4359-5506-4560-8d81-1b038a838e00");
    
    // Connection states
    enum ConnectionState {
        STATE_DISCONNECTED,
        STATE_SCANNING,
        STATE_CONNECTING,
        STATE_CONNECTED,
        STATE_SYNCING,
        STATE_READY
    }
    
    private var _delegate;
    private var _profileRegistered = false;
    private var _connectionState = STATE_DISCONNECTED;
    private var _connectedDevice = null;
    private var _meshtasticService = null;
    private var _toRadioChar = null;
    private var _fromRadioChar = null;
    private var _fromNumChar = null;
    private var _scanTimer = null;
    private var _connectionCallback = null;
    private var _dataCallback = null;
    private var _pinCallback = null;
    private var _defaultPin = "123456"; // Default Meshtastic PIN

    function initialize() {
        _delegate = new BleManagerDelegate(self);
        Ble.setDelegate(_delegate);
    }

    function setDefaultPin(pin) {
        _defaultPin = pin;
    }

    function setPinCallback(callback) {
        _pinCallback = callback;
    }
    
    function registerProfile() {
        if (_profileRegistered) { 
            return true; 
        }
        
        var profile = {
            :uuid => MESH_SERVICE_UUID,
            :characteristics => [
                { 
                    :uuid => TO_RADIO_UUID
                },
                { 
                    :uuid => FROM_RADIO_UUID,
                    :descriptors => [Ble.cccdUuid()]
                },
                { 
                    :uuid => FROM_NUM_UUID,
                    :descriptors => [Ble.cccdUuid()]
                }
            ]
        };
        
        try {
            Ble.registerProfile(profile);
            _profileRegistered = true;
            System.println("BLE profile registered successfully");
            return true;
        } catch (exception) {
            System.println("Failed to register BLE profile: " + exception.getErrorMessage());
            return false;
        }
    }
    
    function startScan(callback) {
        if (_connectionState != STATE_DISCONNECTED) {
            System.println("Cannot scan while not disconnected");
            return false;
        }
        
        _connectionCallback = callback;
        _connectionState = STATE_SCANNING;
        
        try {
            Ble.setScanState(Ble.SCAN_STATE_SCANNING);
            System.println("BLE scan started");
            
            // Set a timeout for scanning
            if (_scanTimer != null) {
                _scanTimer.stop();
            }
            _scanTimer = new Timer.Timer();
            var scanTimeoutMethod = new Lang.Method(self, :scanTimeout);
            _scanTimer.start(scanTimeoutMethod, 30000, false); // 30 second timeout
            
            return true;
        } catch (exception) {
            System.println("Failed to start scan: " + exception.getErrorMessage());
            _connectionState = STATE_DISCONNECTED;
            return false;
        }
    }
    
    function stopScan() {
        if (_scanTimer != null) {
            _scanTimer.stop();
            _scanTimer = null;
        }
        
        try {
            Ble.setScanState(Ble.SCAN_STATE_OFF);
            System.println("BLE scan stopped");
        } catch (exception) {
            System.println("Failed to stop scan: " + exception.getErrorMessage());
        }
        
        if (_connectionState == STATE_SCANNING) {
            _connectionState = STATE_DISCONNECTED;
        }
    }
    
    function scanTimeout() {
        System.println("Scan timeout reached");
        stopScan();
        
        if (_connectionCallback != null) {
            _connectionCallback.invoke(false, "Scan timeout - no Meshtastic devices found");
        }
    }
    
    function connectToDevice(device) {
        if (_connectionState != STATE_SCANNING && _connectionState != STATE_DISCONNECTED) {
            System.println("Invalid state for connection");
            return false;
        }

        stopScan();
        _connectionState = STATE_CONNECTING;
        _connectedDevice = device;

        try {
            // Set pairing type to require passkey
            Ble.setPairingType(Ble.PAIRING_TYPE_PASSKEY);
            Ble.pairDevice(device);
            System.println("Pairing initiated with device");
            return true;
        } catch (exception) {
            System.println("Failed to pair device: " + exception.getErrorMessage());
            _connectionState = STATE_DISCONNECTED;
            _connectedDevice = null;
            return false;
        }
    }

    // Called by delegate when PIN is requested
    function onPinRequested(device) {
        System.println("PIN requested for device");

        if (_pinCallback != null) {
            // Ask user for PIN
            _pinCallback.invoke(device, method(:onPinProvided));
        } else {
            // Use default PIN
            System.println("Using default PIN: " + _defaultPin);
            onPinProvided(_defaultPin);
        }
    }

    function onPinProvided(pin) {
        if (pin != null && _connectedDevice != null) {
            try {
                System.println("Providing PIN for pairing");
                Ble.setPairingPasskey(pin);
            } catch (exception) {
                System.println("Error setting PIN: " + exception.getErrorMessage());
            }
        } else {
            System.println("PIN entry cancelled or device not found");
            disconnect();
            if (_connectionCallback != null) {
                _connectionCallback.invoke(false, "PIN entry cancelled");
            }
        }
    }
    
    function disconnect() {
        if (_connectedDevice != null) {
            try {
                Ble.unpairDevice(_connectedDevice);
            } catch (exception) {
                System.println("Error during disconnect: " + exception.getErrorMessage());
            }
        }
        
        _connectionState = STATE_DISCONNECTED;
        _connectedDevice = null;
        _meshtasticService = null;
        _toRadioChar = null;
        _fromRadioChar = null;
        _fromNumChar = null;
    }
    
    function sendData(data, callback) {
        if (_connectionState != STATE_READY || _toRadioChar == null) {
            System.println("Not ready to send data");
            if (callback != null) {
                callback.invoke(false, "Not connected");
            }
            return false;
        }
        
        try {
            _toRadioChar.requestWrite(data, {:writeType => Ble.WRITE_TYPE_DEFAULT});
            if (callback != null) {
                callback.invoke(true, null);
            }
            return true;
        } catch (exception) {
            System.println("Failed to send data: " + exception.getErrorMessage());
            if (callback != null) {
                callback.invoke(false, exception.getErrorMessage());
            }
            return false;
        }
    }
    
    function setDataCallback(callback) {
        _dataCallback = callback;
    }
    
    function getConnectionState() {
        return _connectionState;
    }
    
    function isConnected() {
        return _connectionState == STATE_READY;
    }
    
    // Called by delegate when device is connected
    function onDeviceConnected(device) {
        System.println("Device connected, initializing service");
        _connectionState = STATE_CONNECTED;
        _connectedDevice = device;
        
        // Get the Meshtastic service
        _meshtasticService = device.getService(MESH_SERVICE_UUID);
        if (_meshtasticService == null) {
            System.println("Meshtastic service not found on device");
            disconnect();
            if (_connectionCallback != null) {
                _connectionCallback.invoke(false, "Meshtastic service not found");
            }
            return;
        }
        
        // Get characteristics
        _toRadioChar = _meshtasticService.getCharacteristic(TO_RADIO_UUID);
        _fromRadioChar = _meshtasticService.getCharacteristic(FROM_RADIO_UUID);
        _fromNumChar = _meshtasticService.getCharacteristic(FROM_NUM_UUID);
        
        if (_toRadioChar == null || _fromRadioChar == null || _fromNumChar == null) {
            System.println("Required characteristics not found");
            disconnect();
            if (_connectionCallback != null) {
                _connectionCallback.invoke(false, "Required characteristics not found");
            }
            return;
        }
        
        // Enable notifications
        enableNotifications();
    }
    
    function enableNotifications() {
        System.println("Enabling notifications");
        _connectionState = STATE_SYNCING;
        
        // Enable notifications on FromRadio characteristic
        var fromRadioCccd = _fromRadioChar.getDescriptor(Ble.cccdUuid());
        if (fromRadioCccd != null) {
            fromRadioCccd.requestWrite([0x01, 0x00]b);
        }
        
        // Enable notifications on FromNum characteristic
        var fromNumCccd = _fromNumChar.getDescriptor(Ble.cccdUuid());
        if (fromNumCccd != null) {
            fromNumCccd.requestWrite([0x01, 0x00]b);
        }
        
        // After enabling notifications, mark as ready
        // In a real implementation, we'd wait for write confirmations
        _connectionState = STATE_READY;
        
        if (_connectionCallback != null) {
            _connectionCallback.invoke(true, null);
            _connectionCallback = null;
        }
    }
    
    // Called by delegate when device is disconnected
    function onDeviceDisconnected() {
        System.println("Device disconnected");
        var wasConnected = (_connectionState == STATE_READY);
        
        _connectionState = STATE_DISCONNECTED;
        _connectedDevice = null;
        _meshtasticService = null;
        _toRadioChar = null;
        _fromRadioChar = null;
        _fromNumChar = null;
        
        if (wasConnected && _dataCallback != null) {
            _dataCallback.invoke(null, "Device disconnected");
        }
    }
    
    // Called by delegate when data is received
    function onDataReceived(characteristic, data) {
        if (_dataCallback != null && data != null) {
            _dataCallback.invoke(data, null);
        }
    }
}

// BLE Delegate implementation
class BleManagerDelegate extends Ble.BleDelegate {
    private var _manager;
    
    function initialize(manager) {
        BleDelegate.initialize();
        _manager = manager;
    }
    
    function onScanResults(scanResults) {
        if (scanResults == null) {
            return;
        }
        
        // Look for Meshtastic devices
        // Note: scanResults is an Iterator, not an array
        var foundMeshtastic = false;
        var candidateDevice = null;
        
        for (var result = scanResults.next(); result != null; result = scanResults.next()) {
            var deviceName = result.getDeviceName();
            
            if (deviceName != null && deviceName.find("Meshtastic") == 0) {
                System.println("Found Meshtastic device: " + deviceName);
                candidateDevice = result;
                
                // Check if it advertises our service
                var serviceUuids = result.getServiceUuids();
                if (serviceUuids != null) {
                    for (var serviceUuid = serviceUuids.next(); serviceUuid != null; serviceUuid = serviceUuids.next()) {
                        if (serviceUuid.equals(BleManager.MESH_SERVICE_UUID)) {
                            System.println("Device advertises Meshtastic service, connecting...");
                            _manager.connectToDevice(result);
                            return;
                        }
                    }
                }
                
                foundMeshtastic = true;
                break; // Exit the loop, we found a candidate
            }
        }
        
        // If we found a Meshtastic device but no service match, try to connect anyway
        if (foundMeshtastic && candidateDevice != null) {
            System.println("Attempting connection to Meshtastic device");
            _manager.connectToDevice(candidateDevice);
        }
    }
    
    function onConnectedStateChanged(device, state) {
        if (state == Ble.CONNECTION_STATE_CONNECTED) {
            System.println("BLE connection established");
            _manager.onDeviceConnected(device);
        } else if (state == Ble.CONNECTION_STATE_DISCONNECTED) {
            System.println("BLE connection lost");
            _manager.onDeviceDisconnected();
        }
    }
    
    function onCharacteristicChanged(characteristic, value) {
        if (characteristic != null && value != null) {
            var uuid = characteristic.getUuid();
            System.println("Characteristic changed: " + uuid.toString());
            _manager.onDataReceived(characteristic, value);
        }
    }
    
    function onCharacteristicRead(characteristic, status, value) {
        if (status == Ble.STATUS_SUCCESS && value != null) {
            _manager.onDataReceived(characteristic, value);
        }
    }
    
    function onCharacteristicWrite(characteristic, status) {
        if (status == Ble.STATUS_SUCCESS) {
            System.println("Characteristic write successful");
        } else {
            System.println("Characteristic write failed with status: " + status);
        }
    }
    
    function onDescriptorWrite(descriptor, status) {
        if (status == Ble.STATUS_SUCCESS) {
            System.println("Descriptor write successful");
        } else {
            System.println("Descriptor write failed with status: " + status);
        }
    }

    function onPairingRequest(device, pairingType) {
        System.println("Pairing request received, type: " + pairingType);

        if (pairingType == Ble.PAIRING_TYPE_PASSKEY) {
            // Forward to manager to handle PIN entry
            _manager.onPinRequested(device);
        } else {
            System.println("Unexpected pairing type");
        }
    }
}