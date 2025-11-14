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
    private var _messageHandler;
    private var _viewManager;
    private var _notificationManager;
    private var _systemMonitor;
    private var _reconnectManager;
    private var _settingsManager;

    function initialize() {
        System.println(">>> MeshtasticApp.initialize() START");
        AppBase.initialize();
        System.println(">>> Creating SettingsManager...");
        _settingsManager = new SettingsManager();

        // Create BLE manager - BleManager or MockBleManager depending on jungle file
        System.println(">>> Creating BLE Manager...");
        _bleManager = new BleManager(_settingsManager);

        System.println(">>> Creating MessageHandler...");
        _messageHandler = new MessageHandler();
        System.println(">>> Creating SystemMonitor...");
        _systemMonitor = new SystemMonitor();
        System.println(">>> Creating ReconnectManager...");
        _reconnectManager = new ReconnectManager(_bleManager, _messageHandler);
        System.println(">>> Creating ViewManager...");
        _viewManager = new ViewManager(_bleManager, _messageHandler, _systemMonitor, _reconnectManager, _settingsManager);
        System.println(">>> Creating NotificationManager...");
        _notificationManager = new NotificationManager();
        System.println(">>> MeshtasticApp.initialize() COMPLETE");
    }

    function onStart(state as Lang.Dictionary?) as Void {
        System.println(">>> MeshtasticApp.onStart() START");
        System.println("=== Meshtastic App Starting ===");

        // Register BLE profile
        // Note: BLE crashes in simulator on macOS - this is a known Garmin SDK bug
        System.println(">>> Registering BLE profile...");
        try {
            if (_bleManager.registerProfile()) {
                System.println("BLE profile registered successfully");
            } else {
                System.println("Failed to register BLE profile");
            }
        } catch (ex) {
            System.println("BLE registration failed (expected in simulator): " + ex.getErrorMessage());
        }

        // Set up message handler callbacks
        System.println(">>> Setting up callbacks...");
        _messageHandler.setMessageCallback(method(:onMessageReceived));
        _messageHandler.setConfigCompleteCallback(method(:onConfigComplete));

        // Set up data callback for BLE
        _bleManager.setDataCallback(method(:onDataReceived));

        // Set up reconnect manager callback
        _reconnectManager.setCallback(method(:onReconnectStatus));

        // Update system monitor
        System.println(">>> Updating system monitor...");
        _systemMonitor.update();
        System.println(">>> MeshtasticApp.onStart() COMPLETE");
    }

    function onStop(state as Lang.Dictionary?) as Void {
        System.println(">>> MeshtasticApp.onStop() START");
        System.println("=== Meshtastic App Stopping ===");
        _reconnectManager.cancel(); // Cancel any pending reconnect
        _bleManager.disconnect();
        System.println(">>> MeshtasticApp.onStop() COMPLETE");
    }

    function getInitialView() {
        System.println(">>> MeshtasticApp.getInitialView() START");
        // Return the status view as the initial view
        System.println(">>> Creating StatusView...");
        var view = new StatusView(_bleManager, _messageHandler, _viewManager, _systemMonitor, _reconnectManager);
        System.println(">>> Creating StatusViewDelegate...");
        var delegate = new StatusViewDelegate(view, _viewManager);
        System.println(">>> MeshtasticApp.getInitialView() COMPLETE");
        return [ view, delegate ];
    }
    
    function onDataReceived(data, error) {
        if (error != null) {
            System.println("Data receive error: " + error);
            return;
        }

        if (data != null) {
            System.println("Received data: " + data.size() + " bytes");

            // Process through message handler
            try {
                _messageHandler.processReceivedData(data);
                // Request UI update for any visible view
                WatchUi.requestUpdate();
            } catch (exception) {
                System.println("Error processing received data: " + exception.getErrorMessage());
            }
        }
    }

    function onMessageReceived(message) {
        System.println("App: New message from " + message[:from].format("%08X") + ": " + message[:text]);

        // Notify user of new message
        _notificationManager.notifyNewMessage();

        // Trigger UI update
        WatchUi.requestUpdate();
    }

    function onConfigComplete() {
        System.println("App: Config sync complete, ready to send messages");
        System.println("Loaded " + _messageHandler.getNodeCount() + " nodes");

        // Notify connection successful
        _notificationManager.notifyConnected();
        _reconnectManager.onConnected();

        // Trigger UI update
        WatchUi.requestUpdate();
    }

    function onReconnectStatus(success, message) {
        System.println("Reconnect status: " + message);
        WatchUi.requestUpdate();
    }

    // Public accessors for managers
    function getNotificationManager() {
        return _notificationManager;
    }

    function getSystemMonitor() {
        return _systemMonitor;
    }

    function getReconnectManager() {
        return _reconnectManager;
    }
}