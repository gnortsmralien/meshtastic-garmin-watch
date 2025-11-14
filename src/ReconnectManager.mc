// ReconnectManager.mc
//
// Handles automatic reconnection when BLE connection is lost

using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;

class ReconnectManager {
    private var _bleManager;
    private var _messageHandler;
    private var _reconnectTimer = null;
    private var _reconnectAttempts = 0;
    private var _maxReconnectAttempts = 5;
    private var _reconnectDelay = 5000; // 5 seconds
    private var _autoReconnectEnabled = true;
    private var _lastDisconnectTime = 0;
    private var _callback = null;

    function initialize(bleManager, messageHandler) {
        _bleManager = bleManager;
        _messageHandler = messageHandler;
    }

    // Called when connection is lost
    function onDisconnected() {
        if (!_autoReconnectEnabled) {
            System.println("Auto-reconnect disabled");
            return;
        }

        _lastDisconnectTime = System.getTimer();

        if (_reconnectAttempts >= _maxReconnectAttempts) {
            System.println("Max reconnect attempts reached");
            if (_callback != null) {
                _callback.invoke(false, "Max reconnect attempts reached");
            }
            return;
        }

        System.println("Scheduling reconnect attempt " + (_reconnectAttempts + 1) + " of " + _maxReconnectAttempts);

        // Schedule reconnect
        if (_reconnectTimer != null) {
            _reconnectTimer.stop();
        }

        _reconnectTimer = new Timer.Timer();
        _reconnectTimer.start(method(:attemptReconnect), _reconnectDelay, false);
    }

    function attemptReconnect() as Void {
        _reconnectAttempts++;
        System.println("Attempting to reconnect (" + _reconnectAttempts + "/" + _maxReconnectAttempts + ")");

        if (_callback != null) {
            _callback.invoke(true, "Reconnecting...");
        }

        // Start scanning
        _bleManager.startScan(method(:onReconnectResult));
    }

    function onReconnectResult(success, error) {
        if (success) {
            System.println("Reconnection successful!");
            _reconnectAttempts = 0; // Reset counter

            // Send want_config_id to re-sync
            var configRequest = _messageHandler.createWantConfigRequest();
            if (configRequest != null) {
                _bleManager.sendData(configRequest, null);
            }

            if (_callback != null) {
                _callback.invoke(true, "Reconnected!");
            }
        } else {
            System.println("Reconnection failed: " + error);

            if (_reconnectAttempts < _maxReconnectAttempts) {
                // Try again
                onDisconnected();
            } else {
                System.println("All reconnect attempts exhausted");
                if (_callback != null) {
                    _callback.invoke(false, "Reconnect failed");
                }
            }
        }
    }

    // Called when connection is successful (reset attempts)
    function onConnected() {
        _reconnectAttempts = 0;
        if (_reconnectTimer != null) {
            _reconnectTimer.stop();
            _reconnectTimer = null;
        }
    }

    // Cancel any pending reconnect
    function cancel() {
        if (_reconnectTimer != null) {
            _reconnectTimer.stop();
            _reconnectTimer = null;
        }
        _reconnectAttempts = 0;
    }

    function setAutoReconnectEnabled(enabled) {
        _autoReconnectEnabled = enabled;
        if (!enabled) {
            cancel();
        }
    }

    function setMaxAttempts(max) {
        _maxReconnectAttempts = max;
    }

    function setReconnectDelay(delayMs) {
        _reconnectDelay = delayMs;
    }

    function setCallback(callback) {
        _callback = callback;
    }

    function getReconnectAttempts() {
        return _reconnectAttempts;
    }

    function isAutoReconnectEnabled() {
        return _autoReconnectEnabled;
    }
}
