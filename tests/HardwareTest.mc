// HardwareTest.mc
//
// Test app designed for real Garmin hardware with Meshtastic devices

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics;
using Toybox.Timer;

class HardwareTestApp extends Application.AppBase {
    private var _bleManager;
    private var _testTimer;
    private var _testStage = 0;
    private var _testResults = [];
    
    function initialize() {
        AppBase.initialize();
        _bleManager = new SimpleBleManager();
    }
    
    function onStart(state as Lang.Dictionary?) as Void {
        System.println("=== Hardware Test App Starting ===");
        System.println("This test requires actual Meshtastic hardware nearby");
        
        // Set up BLE manager
        _bleManager.registerProfile();
        
        // Start automated test sequence
        startTestSequence();
    }
    
    function onStop(state as Lang.Dictionary?) as Void {
        System.println("=== Hardware Test App Stopping ===");
        if (_testTimer != null) {
            _testTimer.stop();
        }
        _bleManager.disconnect();
    }
    
    function getInitialView() {
        return [ new HardwareTestView(self) ];
    }
    
    function startTestSequence() {
        _testStage = 0;
        _testResults = [];
        
        // Start with a timer to run tests step by step
        _testTimer = new Timer.Timer();
        var testMethod = new Lang.Method(self, :runNextTest);
        _testTimer.start(testMethod, 2000, true); // Run every 2 seconds
    }
    
    function runNextTest() {
        switch (_testStage) {
            case 0:
                testBleProfile();
                break;
            case 1:
                testBleScanning();
                break;
            case 2:
                testConnectionState();
                break;
            case 3:
                testStopScan();
                break;
            case 4:
                printResults();
                _testTimer.stop();
                break;
            default:
                _testTimer.stop();
                break;
        }
        _testStage++;
    }
    
    function testBleProfile() {
        System.println("\n--- Test 1: BLE Profile Registration ---");
        try {
            var result = _bleManager.registerProfile();
            if (result) {
                System.println("✓ BLE profile registered successfully");
                _testResults.add("Profile: SUCCESS");
            } else {
                System.println("✗ BLE profile registration failed");
                _testResults.add("Profile: FAILED");
            }
        } catch (exception) {
            System.println("✗ BLE profile error: " + exception.getErrorMessage());
            _testResults.add("Profile: ERROR - " + exception.getErrorMessage());
        }
    }
    
    function testBleScanning() {
        System.println("\n--- Test 2: BLE Scanning ---");
        try {
            var result = _bleManager.startScan();
            if (result) {
                System.println("✓ BLE scan started successfully");
                System.println("  Scanning for Meshtastic devices...");
                _testResults.add("Scan: SUCCESS");
            } else {
                System.println("✗ BLE scan failed to start");
                _testResults.add("Scan: FAILED");
            }
        } catch (exception) {
            System.println("✗ BLE scan error: " + exception.getErrorMessage());
            _testResults.add("Scan: ERROR - " + exception.getErrorMessage());
        }
    }
    
    function testConnectionState() {
        System.println("\n--- Test 3: Connection State ---");
        try {
            var state = _bleManager.getConnectionState();
            System.println("✓ Connection state: " + state);
            
            var isConnected = _bleManager.isConnected();
            System.println("✓ Is connected: " + isConnected);
            
            _testResults.add("State: " + state);
        } catch (exception) {
            System.println("✗ Connection state error: " + exception.getErrorMessage());
            _testResults.add("State: ERROR - " + exception.getErrorMessage());
        }
    }
    
    function testStopScan() {
        System.println("\n--- Test 4: Stop Scanning ---");
        try {
            _bleManager.stopScan();
            System.println("✓ BLE scan stopped");
            _testResults.add("Stop: SUCCESS");
        } catch (exception) {
            System.println("✗ Stop scan error: " + exception.getErrorMessage());
            _testResults.add("Stop: ERROR - " + exception.getErrorMessage());
        }
    }
    
    function printResults() {
        System.println("\n=== Test Results Summary ===");
        for (var i = 0; i < _testResults.size(); i++) {
            System.println(_testResults[i]);
        }
        System.println("=== Hardware Test Complete ===");
        
        // Additional info
        System.println("\nNOTE: If you have a Meshtastic device nearby:");
        System.println("- Make sure it's powered on and in pairing mode");
        System.println("- Device should be advertising as 'Meshtastic_XXXX'");
        System.println("- Check if BLE delegate callbacks are triggered");
    }
    
    function getBleManager() {
        return _bleManager;
    }
    
    function getTestResults() {
        return _testResults;
    }
}

class HardwareTestView extends WatchUi.View {
    private var _app;
    private var _statusText = "Starting...";
    
    function initialize(app) {
        View.initialize();
        _app = app;
    }
    
    function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Title
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, 30, 
                   Graphics.FONT_MEDIUM, "Hardware Test", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Status
        var bleManager = _app.getBleManager();
        if (bleManager != null) {
            var state = bleManager.getConnectionState();
            switch (state) {
                case SimpleBleManager.STATE_DISCONNECTED:
                    _statusText = "Disconnected";
                    break;
                case SimpleBleManager.STATE_SCANNING:
                    _statusText = "Scanning...";
                    break;
                case SimpleBleManager.STATE_CONNECTING:
                    _statusText = "Connecting...";
                    break;
                case SimpleBleManager.STATE_CONNECTED:
                    _statusText = "Connected";
                    break;
                case SimpleBleManager.STATE_READY:
                    _statusText = "Ready";
                    break;
                default:
                    _statusText = "Unknown";
                    break;
            }
        }
        
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, 
                   Graphics.FONT_SMALL, _statusText, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Instructions
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 60, 
                   Graphics.FONT_TINY, "Check debug console", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 40, 
                   Graphics.FONT_TINY, "for detailed results", Graphics.TEXT_JUSTIFY_CENTER);
    }
}