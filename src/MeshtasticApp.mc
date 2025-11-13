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

    function initialize() {
        AppBase.initialize();
        _bleManager = new BleManager();
        _messageHandler = new MessageHandler();
        _viewManager = new ViewManager(_bleManager, _messageHandler);
        _notificationManager = new NotificationManager();
        _systemMonitor = new SystemMonitor();
        _reconnectManager = new ReconnectManager(_bleManager, _messageHandler);
    }

    function onStart(state as Lang.Dictionary?) as Void {
        System.println("=== Meshtastic App Starting ===");

        // Register BLE profile
        if (_bleManager.registerProfile()) {
            System.println("BLE profile registered successfully");
        } else {
            System.println("Failed to register BLE profile");
        }

        // Set up message handler callbacks
        _messageHandler.setMessageCallback(method(:onMessageReceived));
        _messageHandler.setConfigCompleteCallback(method(:onConfigComplete));

        // Set up data callback for BLE
        _bleManager.setDataCallback(method(:onDataReceived));

        // Set up reconnect manager callback
        _reconnectManager.setCallback(method(:onReconnectStatus));

        // Update system monitor
        _systemMonitor.update();
    }

    function onStop(state as Lang.Dictionary?) as Void {
        System.println("=== Meshtastic App Stopping ===");
        _reconnectManager.cancel(); // Cancel any pending reconnect
        _bleManager.disconnect();
    }

    function getInitialView() {
        // Return the status view as the initial view
        var view = new StatusView(_bleManager, _messageHandler, _viewManager, _systemMonitor, _reconnectManager);
        var delegate = new StatusViewDelegate(view, _viewManager);
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