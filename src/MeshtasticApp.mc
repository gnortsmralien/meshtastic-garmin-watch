// MeshtasticApp.mc
//
// Main Meshtastic application for Garmin devices
// Demonstrates BLE connection and basic messaging

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics;
using ProtoBuf;

class MeshtasticApp extends Application.AppBase {
    private var _bleManager;
    private var _mainView;
    
    function initialize() {
        AppBase.initialize();
        _bleManager = new BleManager();
    }
    
    function onStart(state as Lang.Dictionary?) as Void {
        System.println("=== Meshtastic App Starting ===");
        
        // Register BLE profile
        if (_bleManager.registerProfile()) {
            System.println("BLE profile registered successfully");
        } else {
            System.println("Failed to register BLE profile");
        }
        
        // Set up data callback
        _bleManager.setDataCallback(method(:onDataReceived));
    }
    
    function onStop(state as Lang.Dictionary?) as Void {
        System.println("=== Meshtastic App Stopping ===");
        _bleManager.disconnect();
    }
    
    function getInitialView() {
        _mainView = new MeshtasticMainView(_bleManager);
        return [ _mainView ];
    }
    
    function onDataReceived(data, error) {
        if (error != null) {
            System.println("Data receive error: " + error);
            return;
        }
        
        if (data != null) {
            System.println("Received data: " + data.size() + " bytes");
            
            // Try to unwrap and decode the data
            try {
                var unwrapped = ProtoBuf.unwrap(data);
                if (unwrapped != null) {
                    System.println("Unwrapped payload: " + unwrapped.size() + " bytes");
                    // TODO: Decode FromRadio message
                }
            } catch (exception) {
                System.println("Error processing received data: " + exception.getErrorMessage());
            }
        }
    }
    
    function getBleManager() {
        return _bleManager;
    }
}

class MeshtasticMainView extends WatchUi.View {
    private var _bleManager;
    private var _statusText = "Disconnected";
    private var _messageText = "";
    
    function initialize(bleManager) {
        View.initialize();
        _bleManager = bleManager;
    }
    
    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }
    
    function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Update status based on connection state
        var state = _bleManager.getConnectionState();
        switch (state) {
            case BleManager.STATE_DISCONNECTED:
                _statusText = "Disconnected";
                break;
            case BleManager.STATE_SCANNING:
                _statusText = "Scanning...";
                break;
            case BleManager.STATE_CONNECTING:
                _statusText = "Connecting...";
                break;
            case BleManager.STATE_CONNECTED:
                _statusText = "Connected";
                break;
            case BleManager.STATE_SYNCING:
                _statusText = "Syncing...";
                break;
            case BleManager.STATE_READY:
                _statusText = "Ready";
                break;
        }
        
        // Draw status
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/3, 
                   Graphics.FONT_MEDIUM, _statusText, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw any message
        if (_messageText.length() > 0) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 20, 
                       Graphics.FONT_SMALL, _messageText, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw instructions
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 40, 
                   Graphics.FONT_TINY, "Press START to scan", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function onKey(keyEvent) {
        if (keyEvent.getKey() == WatchUi.KEY_START) {
            handleStartKey();
            return true;
        }
        return false;
    }
    
    function handleStartKey() {
        var state = _bleManager.getConnectionState();
        
        if (state == BleManager.STATE_DISCONNECTED) {
            // Start scanning
            _messageText = "Starting scan...";
            WatchUi.requestUpdate();
            
            _bleManager.startScan(method(:onConnectionResult));
        } else if (state == BleManager.STATE_READY) {
            // Send a test message
            sendTestMessage();
        } else {
            // Disconnect if in any other state
            _bleManager.disconnect();
            _messageText = "";
            WatchUi.requestUpdate();
        }
    }
    
    function onConnectionResult(success, error) {
        if (success) {
            _messageText = "Connected!";
            // TODO: Send initial config request
        } else {
            _messageText = error != null ? error : "Connection failed";
        }
        WatchUi.requestUpdate();
    }
    
    function sendTestMessage() {
        // Create a simple text message
        var text = "Hello Meshtastic!";
        var textBytes = text.toUtf8Array();
        
        // Build Data message
        var dataMessage = {
            :portnum => 1,  // TEXT_MESSAGE_APP
            :payload => textBytes
        };
        
        // Encode it
        var encoder = new ProtoBuf.Encoder();
        var encoded = encoder.encode(dataMessage, ProtoBuf.SCHEMA_DATA);
        
        // Wrap in MeshPacket
        var meshPacket = {
            :to => 0xFFFFFFFF,  // Broadcast
            :decoded => encoded,
            :id => System.getTimer() & 0xFFFFFFFF
        };
        
        // TODO: Encode MeshPacket and wrap in ToRadio
        
        _messageText = "Message sent!";
        WatchUi.requestUpdate();
    }
}