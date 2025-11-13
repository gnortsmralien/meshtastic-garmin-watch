// BleTestApp.mc
//
// Simple test app for BLE functionality without complex scanning

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics;

class BleTestApp extends Application.AppBase {
    private var _bleManager;
    
    function initialize() {
        AppBase.initialize();
        _bleManager = new SimpleBleManager();
    }
    
    function onStart(state as Lang.Dictionary?) as Void {
        System.println("=== BLE Test App Starting ===");
        
        // Test BLE profile registration
        if (_bleManager.registerProfile()) {
            System.println("✓ BLE profile registered successfully");
        } else {
            System.println("✗ Failed to register BLE profile");
        }
        
        // Test connection state
        var connectionState = _bleManager.getConnectionState();
        System.println("Initial connection state: " + connectionState);
        
        // Test command queue
        var queue = new BleCommandQueue();
        System.println("Command queue size: " + queue.getSize());
        
        System.println("=== BLE Test Complete ===");
    }
    
    function onStop(state as Lang.Dictionary?) as Void {
        System.println("=== BLE Test App Stopping ===");
        if (_bleManager != null) {
            _bleManager.disconnect();
        }
    }
    
    function getInitialView() {
        return [ new BleTestView() ];
    }
}

class BleTestView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }
    
    function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, 
                   Graphics.FONT_MEDIUM, "BLE Test", Graphics.TEXT_JUSTIFY_CENTER);
                   
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 30, 
                   Graphics.FONT_SMALL, "Check Debug Output", Graphics.TEXT_JUSTIFY_CENTER);
    }
}