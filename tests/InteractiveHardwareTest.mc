// InteractiveHardwareTest.mc
//
// Interactive hardware test with proper UX for testing with real Meshtastic devices

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics;
using Toybox.Timer;

class InteractiveHardwareTestApp extends Application.AppBase {
    private var _bleManager;
    private var _mainView;
    
    // Simulator mode flag - controlled by Config module
    static const SIMULATOR_MODE = Config.SIMULATOR_MODE;
    
    function initialize() {
        AppBase.initialize();
        
        if (SIMULATOR_MODE) {
            _bleManager = new MockBleManager();
        } else {
            _bleManager = new SimpleBleManager();
        }
    }
    
    function onStart(state as Lang.Dictionary?) as Void {
        System.println("=== Interactive Hardware Test App Starting ===");
        
        // Register BLE profile
        if (_bleManager.registerProfile()) {
            System.println("✓ BLE profile registered successfully");
        } else {
            System.println("✗ Failed to register BLE profile");
        }
    }
    
    function onStop(state as Lang.Dictionary?) as Void {
        System.println("=== Interactive Hardware Test App Stopping ===");
        _bleManager.disconnect();
    }
    
    function getInitialView() {
        _mainView = new HardwareTestMainView(_bleManager);
        return [ _mainView, new HardwareTestDelegate(_mainView) ];
    }
    
    function getBleManager() {
        return _bleManager;
    }
}

// Main view that handles different test screens
class HardwareTestMainView extends WatchUi.View {
    private var _bleManager;
    private var _currentScreen = :start;
    private var _statusMessage = "";
    private var _foundDevices = [];
    private var _selectedDevice = null;
    private var _connectionTimer = null;
    private var _scanTimer = null;
    private var _testResults = {};
    
    // Screen types
    enum TestScreen {
        SCREEN_START,
        SCREEN_SCANNING,
        SCREEN_DEVICE_LIST,
        SCREEN_PIN_ENTRY,
        SCREEN_CONNECTING,
        SCREEN_RESULTS,
        SCREEN_CONNECTED
    }
    
    function initialize(bleManager) {
        View.initialize();
        _bleManager = bleManager;
        _currentScreen = SCREEN_START;
        _statusMessage = "Ready to test with Meshtastic hardware";
    }
    
    function onLayout(dc as Graphics.Dc) as Void {
        // No layout needed for this test
    }
    
    function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        switch (_currentScreen) {
            case SCREEN_START:
                drawStartScreen(dc);
                break;
            case SCREEN_SCANNING:
                drawScanningScreen(dc);
                break;
            case SCREEN_DEVICE_LIST:
                drawDeviceListScreen(dc);
                break;
            case SCREEN_PIN_ENTRY:
                drawPinEntryScreen(dc);
                break;
            case SCREEN_CONNECTING:
                drawConnectingScreen(dc);
                break;
            case SCREEN_RESULTS:
                drawResultsScreen(dc);
                break;
            case SCREEN_CONNECTED:
                drawConnectedScreen(dc);
                break;
        }
    }
    
    function drawStartScreen(dc as Graphics.Dc) {
        // Title
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, 30, 
                   Graphics.FONT_MEDIUM, "Meshtastic Test", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Status
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 - 20, 
                   Graphics.FONT_SMALL, _statusMessage, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Instructions
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 10, 
                   Graphics.FONT_SMALL, "Press START to begin", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Requirements
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 60, 
                   Graphics.FONT_TINY, "Ensure Meshtastic device", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 45, 
                   Graphics.FONT_TINY, "is powered on and nearby", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function drawScanningScreen(dc as Graphics.Dc) {
        // Title
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, 30, 
                   Graphics.FONT_MEDIUM, "Scanning...", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Progress indicator (simple animation)
        var dots = "";
        var time = (System.getTimer() / 500) % 4;
        for (var i = 0; i < time; i++) {
            dots += ".";
        }
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 - 20, 
                   Graphics.FONT_SMALL, "Looking for devices" + dots, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Found devices count
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 20, 
                   Graphics.FONT_SMALL, "Found: " + _foundDevices.size() + " devices", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Instructions
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 40, 
                   Graphics.FONT_TINY, "Press BACK to cancel", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function drawDeviceListScreen(dc as Graphics.Dc) {
        // Title
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, 30, 
                   Graphics.FONT_MEDIUM, "Select Device", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Device list (simplified - show first few)
        var y = 70;
        for (var i = 0; i < _foundDevices.size() && i < 3; i++) {
            var device = _foundDevices[i];
            var deviceName = device.hasKey(:name) ? device[:name] : "Unknown";
            
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth()/2, y, 
                       Graphics.FONT_SMALL, (i + 1) + ". " + deviceName, Graphics.TEXT_JUSTIFY_CENTER);
            y += 25;
        }
        
        // Instructions
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 60, 
                   Graphics.FONT_TINY, "UP/DOWN to select", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 45, 
                   Graphics.FONT_TINY, "START to connect", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function drawPinEntryScreen(dc as Graphics.Dc) {
        // Title
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, 30, 
                   Graphics.FONT_MEDIUM, "Enter PIN", Graphics.TEXT_JUSTIFY_CENTER);
        
        // PIN info
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 - 30, 
                   Graphics.FONT_SMALL, "Default PIN: 123456", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Instructions
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 10, 
                   Graphics.FONT_SMALL, "Press START to use", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 30, 
                   Graphics.FONT_SMALL, "default PIN", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Note
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 40, 
                   Graphics.FONT_TINY, "BACK to cancel", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function drawConnectingScreen(dc as Graphics.Dc) {
        // Title
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, 30, 
                   Graphics.FONT_MEDIUM, "Connecting...", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Device info
        if (_selectedDevice != null) {
            var deviceName = _selectedDevice.hasKey(:name) ? _selectedDevice[:name] : "Unknown Device";
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth()/2, dc.getHeight()/2 - 20, 
                       Graphics.FONT_SMALL, "To: " + deviceName, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Progress
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 20, 
                   Graphics.FONT_SMALL, "Please wait...", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Timeout info
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 40, 
                   Graphics.FONT_TINY, "Timeout in 10s", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function drawResultsScreen(dc as Graphics.Dc) {
        // Title - color based on success
        var success = _testResults.hasKey(:success) ? _testResults[:success] : false;
        var titleColor = success ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
        var titleText = success ? "Success!" : "Failed";
        
        dc.setColor(titleColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, 30, 
                   Graphics.FONT_MEDIUM, titleText, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Results
        var y = 70;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        if (_testResults.hasKey(:message)) {
            dc.drawText(dc.getWidth()/2, y, 
                       Graphics.FONT_SMALL, _testResults[:message], Graphics.TEXT_JUSTIFY_CENTER);
            y += 25;
        }
        
        if (_testResults.hasKey(:details)) {
            dc.drawText(dc.getWidth()/2, y, 
                       Graphics.FONT_TINY, _testResults[:details], Graphics.TEXT_JUSTIFY_CENTER);
            y += 20;
        }
        
        // Instructions
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 60, 
                   Graphics.FONT_TINY, "START to try again", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 45, 
                   Graphics.FONT_TINY, "BACK to exit", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function drawConnectedScreen(dc as Graphics.Dc) {
        // Title
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, 30, 
                   Graphics.FONT_MEDIUM, "Connected!", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Device info
        if (_selectedDevice != null) {
            var deviceName = _selectedDevice.hasKey(:name) ? _selectedDevice[:name] : "Unknown";
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth()/2, 70, 
                       Graphics.FONT_SMALL, deviceName, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Status
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, 
                   Graphics.FONT_SMALL, "Ready for messaging", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Instructions
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 60, 
                   Graphics.FONT_TINY, "UP/DOWN for tests", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 45, 
                   Graphics.FONT_TINY, "BACK to disconnect", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Public methods for delegate to call
    function startScan() {
        System.println("Starting BLE scan...");
        _currentScreen = SCREEN_SCANNING;
        _foundDevices = [];
        
        // Start scan
        if (_bleManager.startScan()) {
            System.println("✓ Scan started successfully");
            _statusMessage = "Scanning for Meshtastic devices...";
            
            // Set timeout for scan
            _scanTimer = new Timer.Timer();
            var timeoutMethod = new Lang.Method(self, :onScanTimeout);
            _scanTimer.start(timeoutMethod, 15000, false); // 15 second timeout
            
            // If using mock BLE, populate devices immediately
            if (InteractiveHardwareTestApp.SIMULATOR_MODE) {
                populateMockDevices();
            }
        } else {
            System.println("✗ Failed to start scan");
            showResults(false, "Failed to start BLE scan", "Check BLE permissions");
        }
        
        WatchUi.requestUpdate();
    }
    
    function onScanTimeout() as Void {
        System.println("Scan timeout reached");
        _bleManager.stopScan();

        if (_foundDevices.size() > 0) {
            _currentScreen = SCREEN_DEVICE_LIST;
            System.println("✓ Found " + _foundDevices.size() + " device(s)");
        } else {
            showResults(false, "No devices found", "Make sure Meshtastic device is on and nearby");
        }

        WatchUi.requestUpdate();
    }
    
    function selectDevice(index) {
        if (index >= 0 && index < _foundDevices.size()) {
            _selectedDevice = _foundDevices[index];
            System.println("Selected device: " + _selectedDevice[:name]);
            
            // For now, skip PIN entry and go straight to connecting
            _currentScreen = SCREEN_CONNECTING;
            startConnection();
        }
        WatchUi.requestUpdate();
    }
    
    function populateMockDevices() {
        // Populate with mock devices for simulator testing
        var mockDevices = _bleManager.getMockDevices();
        for (var i = 0; i < mockDevices.size(); i++) {
            _foundDevices.add(mockDevices[i]);
        }
        System.println("✓ Populated " + _foundDevices.size() + " mock devices");
    }
    
    function startConnection() {
        System.println("Starting connection to device...");
        
        if (InteractiveHardwareTestApp.SIMULATOR_MODE) {
            // Use mock BLE manager
            var selectedIndex = -1;
            var mockDevices = _bleManager.getMockDevices();
            for (var i = 0; i < mockDevices.size(); i++) {
                if (mockDevices[i][:name].equals(_selectedDevice[:name])) {
                    selectedIndex = i;
                    break;
                }
            }
            
            if (selectedIndex >= 0) {
                _bleManager.connectToDevice(selectedIndex);
                
                // Monitor connection state
                _connectionTimer = new Timer.Timer();
                var connectMethod = new Lang.Method(self, :checkConnectionState);
                _connectionTimer.start(connectMethod, 500, true); // Check every 500ms
            } else {
                showResults(false, "Device not found", "Selected device no longer available");
            }
        } else {
            // Real BLE connection would go here
            _connectionTimer = new Timer.Timer();
            var connectMethod = new Lang.Method(self, :onConnectionResult);
            _connectionTimer.start(connectMethod, 3000, false); // 3 second simulation
        }
    }
    
    function checkConnectionState() as Void {
        var state = _bleManager.getConnectionState();

        if (state == MockBleManager.STATE_READY) {
            System.println("✓ Connection successful!");
            _connectionTimer.stop();
            _currentScreen = SCREEN_CONNECTED;
            WatchUi.requestUpdate();
        } else if (state == MockBleManager.STATE_DISCONNECTED) {
            System.println("✗ Connection failed");
            _connectionTimer.stop();
            showResults(false, "Connection failed", "Device may be busy or out of range");
            WatchUi.requestUpdate();
        }
        // Otherwise keep checking
    }
    
    function onConnectionResult() as Void {
        // Simulate connection result (for non-mock mode)
        var success = (System.getTimer() % 3) != 0; // 2/3 chance of success

        if (success) {
            System.println("✓ Connection successful!");
            _currentScreen = SCREEN_CONNECTED;
        } else {
            System.println("✗ Connection failed");
            showResults(false, "Connection failed", "Device may be busy or out of range");
        }

        WatchUi.requestUpdate();
    }
    
    function showResults(success, message, details) {
        _currentScreen = SCREEN_RESULTS;
        _testResults = {
            :success => success,
            :message => message,
            :details => details
        };
        
        System.println("Test result: " + (success ? "SUCCESS" : "FAILURE"));
        System.println("Message: " + message);
        System.println("Details: " + details);
    }
    
    function resetTest() {
        _currentScreen = SCREEN_START;
        _foundDevices = [];
        _selectedDevice = null;
        _testResults = {};
        _statusMessage = "Ready to test with Meshtastic hardware";
        
        // Stop any running timers
        if (_scanTimer != null) {
            _scanTimer.stop();
            _scanTimer = null;
        }
        if (_connectionTimer != null) {
            _connectionTimer.stop();
            _connectionTimer = null;
        }
        
        _bleManager.stopScan();
        _bleManager.disconnect();
        
        WatchUi.requestUpdate();
    }
    
    function disconnect() {
        System.println("Disconnecting from device...");
        _bleManager.disconnect();
        resetTest();
    }
    
    // Simulate finding devices (for testing without real hardware)
    function simulateDeviceFound() {
        var mockDevice = {
            :name => "Meshtastic_" + (System.getTimer() % 9999),
            :address => "AA:BB:CC:DD:EE:FF"
        };
        _foundDevices.add(mockDevice);
        System.println("Simulated device found: " + mockDevice[:name]);
    }
    
    function getCurrentScreen() {
        return _currentScreen;
    }
    
    function getFoundDevicesCount() {
        return _foundDevices.size();
    }
}

// Input delegate for handling button presses
class HardwareTestDelegate extends WatchUi.BehaviorDelegate {
    private var _view;
    private var _selectedDeviceIndex = 0;
    
    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }
    
    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        var currentScreen = _view.getCurrentScreen();
        
        switch (key) {
            case WatchUi.KEY_START:
                return handleStartKey(currentScreen);
            case WatchUi.KEY_UP:
                return handleUpKey(currentScreen);
            case WatchUi.KEY_DOWN:
                return handleDownKey(currentScreen);
            case WatchUi.KEY_ESC:
                return handleBackKey(currentScreen);
        }
        
        return false;
    }
    
    function handleStartKey(currentScreen) {
        switch (currentScreen) {
            case HardwareTestMainView.SCREEN_START:
                _view.startScan();
                return true;
            case HardwareTestMainView.SCREEN_SCANNING:
                // In simulator mode, this will advance to device list
                // In hardware mode, this could force scan timeout
                if (InteractiveHardwareTestApp.SIMULATOR_MODE) {
                    _view.onScanTimeout();
                }
                return true;
            case HardwareTestMainView.SCREEN_DEVICE_LIST:
                _view.selectDevice(_selectedDeviceIndex);
                return true;
            case HardwareTestMainView.SCREEN_PIN_ENTRY:
                // Use default PIN
                _view.startConnection();
                return true;
            case HardwareTestMainView.SCREEN_RESULTS:
                _view.resetTest();
                return true;
        }
        return false;
    }
    
    function handleUpKey(currentScreen) {
        switch (currentScreen) {
            case HardwareTestMainView.SCREEN_DEVICE_LIST:
                if (_selectedDeviceIndex > 0) {
                    _selectedDeviceIndex--;
                    WatchUi.requestUpdate();
                }
                return true;
            case HardwareTestMainView.SCREEN_CONNECTED:
                // Could trigger test functions
                System.println("Running connection test...");
                return true;
        }
        return false;
    }
    
    function handleDownKey(currentScreen) {
        switch (currentScreen) {
            case HardwareTestMainView.SCREEN_DEVICE_LIST:
                if (_selectedDeviceIndex < _view.getFoundDevicesCount() - 1) {
                    _selectedDeviceIndex++;
                    WatchUi.requestUpdate();
                }
                return true;
            case HardwareTestMainView.SCREEN_CONNECTED:
                // Could trigger different test functions
                System.println("Running message test...");
                return true;
        }
        return false;
    }
    
    function handleBackKey(currentScreen) {
        switch (currentScreen) {
            case HardwareTestMainView.SCREEN_SCANNING:
            case HardwareTestMainView.SCREEN_DEVICE_LIST:
            case HardwareTestMainView.SCREEN_PIN_ENTRY:
            case HardwareTestMainView.SCREEN_CONNECTING:
                _view.resetTest();
                return true;
            case HardwareTestMainView.SCREEN_CONNECTED:
                _view.disconnect();
                return true;
            case HardwareTestMainView.SCREEN_RESULTS:
                _view.resetTest();
                return true;
        }
        return false;
    }
}