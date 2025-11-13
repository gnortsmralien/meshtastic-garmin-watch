// InteractiveHardwareTestHardware.mc
//
// Hardware version of the interactive test (copy with SIMULATOR_MODE = false)

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics;
using Toybox.Timer;

class InteractiveHardwareTestApp extends Application.AppBase {
    private var _bleManager;
    private var _mainView;
    
    // Hardware mode - set to false for real BLE
    static const SIMULATOR_MODE = false; // Hardware mode
    
    function initialize() {
        AppBase.initialize();
        
        if (SIMULATOR_MODE) {
            _bleManager = new MockBleManager();
        } else {
            _bleManager = new SimpleBleManager();
        }
    }
    
    function onStart(state as Lang.Dictionary?) as Void {
        System.println("=== Interactive Hardware Test App Starting (HARDWARE MODE) ===");
        
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

// Import the rest of the classes from the original file
// (This is a simplified approach - in practice you'd organize this differently)