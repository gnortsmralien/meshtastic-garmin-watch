// BleManagerTest.mc
//
// Test suite for BLE Manager functionality
// Uses mocking to simulate BLE operations

using Toybox.Application;
using Toybox.Lang;
using Toybox.System;
using Toybox.Test;
using Toybox.BluetoothLowEnergy as Ble;

(:test)
class BleManagerTest extends Test.Test {
    private var _bleManager;
    private var _mockDelegate;
    
    function setUp() {
        // Create a new BLE manager for each test
        _bleManager = new BleManager();
        _mockDelegate = new MockBleDelegate();
    }
    
    function tearDown() {
        _bleManager = null;
        _mockDelegate = null;
    }
    
    (:test)
    function testProfileRegistration(logger) {
        logger.debug("Testing BLE profile registration");
        
        // Test initial registration
        var result = _bleManager.registerProfile();
        Test.assert(result);
        
        // Test duplicate registration (should succeed without error)
        result = _bleManager.registerProfile();
        Test.assert(result);
        
        return true;
    }
    
    (:test)
    function testConnectionStates(logger) {
        logger.debug("Testing connection state transitions");
        
        // Initial state should be disconnected
        Test.assertEqual(_bleManager.getConnectionState(), BleManager.STATE_DISCONNECTED);
        Test.assertFalse(_bleManager.isConnected());
        
        // Register profile first
        _bleManager.registerProfile();
        
        // Start scan should change state
        var scanStarted = _bleManager.startScan(method(:mockConnectionCallback));
        Test.assert(scanStarted);
        Test.assertEqual(_bleManager.getConnectionState(), BleManager.STATE_SCANNING);
        
        // Stop scan should return to disconnected
        _bleManager.stopScan();
        Test.assertEqual(_bleManager.getConnectionState(), BleManager.STATE_DISCONNECTED);
        
        return true;
    }
    
    (:test)
    function testDataCallbacks(logger) {
        logger.debug("Testing data callback mechanism");
        
        var receivedData = null;
        var receivedError = null;
        
        // Set up data callback
        _bleManager.setDataCallback(new Lang.Method(self, :mockDataCallback));
        
        // Simulate data reception through delegate
        var testData = [0x01, 0x02, 0x03]b;
        _bleManager.onDataReceived(null, testData);
        
        // Note: In real test, we'd need to verify the callback was invoked
        // For now, we just ensure no exceptions are thrown
        
        return true;
    }
    
    (:test)
    function testSendDataValidation(logger) {
        logger.debug("Testing send data validation");
        
        var testData = [0x01, 0x02, 0x03]b;
        var callbackInvoked = false;
        var callbackSuccess = false;
        
        // Should fail when not connected
        var result = _bleManager.sendData(testData, new Lang.Method(self, :mockSendCallback));
        Test.assertFalse(result);
        
        // Note: Testing actual send would require a connected state,
        // which needs full BLE stack simulation
        
        return true;
    }
    
    function mockConnectionCallback(success, error) {
        System.println("Mock connection callback - success: " + success + ", error: " + error);
    }
    
    function mockDataCallback(data, error) {
        System.println("Mock data callback - data: " + data + ", error: " + error);
    }
    
    function mockSendCallback(success, error) {
        System.println("Mock send callback - success: " + success + ", error: " + error);
    }
}

// Mock BLE Delegate for testing
class MockBleDelegate extends Ble.BleDelegate {
    private var _mockScanResults = [];
    private var _connectionState = Ble.CONNECTION_STATE_DISCONNECTED;
    
    function initialize() {
        BleDelegate.initialize();
    }
    
    function addMockDevice(name, serviceUuids) {
        var mockResult = new MockScanResult(name, serviceUuids);
        _mockScanResults.add(mockResult);
    }
    
    function triggerScanResults() {
        onScanResults(_mockScanResults);
    }
    
    function triggerConnectionStateChange(device, state) {
        _connectionState = state;
        onConnectedStateChanged(device, state);
    }
    
    function triggerCharacteristicChange(uuid, data) {
        var mockChar = new MockCharacteristic(uuid);
        onCharacteristicChanged(mockChar, data);
    }
}

// Mock scan result for testing
class MockScanResult {
    private var _deviceName;
    private var _serviceUuids;
    
    function initialize(name, serviceUuids) {
        _deviceName = name;
        _serviceUuids = serviceUuids;
    }
    
    function getDeviceName() {
        return _deviceName;
    }
    
    function getServiceUuids() {
        return _serviceUuids;
    }
}

// Mock characteristic for testing
class MockCharacteristic {
    private var _uuid;
    
    function initialize(uuid) {
        _uuid = uuid;
    }
    
    function getUuid() {
        return _uuid;
    }
    
    function getDescriptor(uuid) {
        return new MockDescriptor();
    }
    
    function requestWrite(data, options) {
        // Simulate write
        return true;
    }
}

// Mock descriptor for testing
class MockDescriptor {
    function requestWrite(data) {
        // Simulate write
        return true;
    }
}

// Test runner application
(:test)
class BleManagerTestApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }
    
    function onStart(state) {
        System.println("=== BLE Manager Tests ===");
        Test.start();
    }
    
    function onStop(state) {
    }
    
    function getInitialView() {
        return null;
    }
}