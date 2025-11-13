// StatusView.mc
//
// Main status view showing connection state and navigation menu

using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

class StatusView extends WatchUi.View {
    private var _bleManager;
    private var _messageHandler;
    private var _viewManager;
    private var _systemMonitor;
    private var _reconnectManager;
    private var _statusMessage = "";

    function initialize(bleManager, messageHandler, viewManager, systemMonitor, reconnectManager) {
        View.initialize();
        _bleManager = bleManager;
        _messageHandler = messageHandler;
        _viewManager = viewManager;
        _systemMonitor = systemMonitor;
        _reconnectManager = reconnectManager;

        // Set PIN callback on BLE manager
        _bleManager.setPinCallback(method(:onPinRequested));
    }

    function onPinRequested(device, callback) {
        // Show PIN entry view
        _viewManager.showPinEntryView(callback);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var y = 40;

        // App title and system status
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 15, Graphics.FONT_SMALL, "Meshtastic", Graphics.TEXT_JUSTIFY_CENTER);

        // Battery and unread count in top corners
        _systemMonitor.update();
        var battery = _systemMonitor.getBatteryLevel();
        var batteryColor = battery < 20 ? Graphics.COLOR_RED : Graphics.COLOR_LT_GRAY;
        dc.setColor(batteryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(10, 15, Graphics.FONT_TINY, battery + "%", Graphics.TEXT_JUSTIFY_LEFT);

        var unreadCount = _messageHandler.getUnreadCount();
        if (unreadCount > 0) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(width - 15, 22, 12);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width - 15, 15, Graphics.FONT_TINY, unreadCount.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Connection status
        var state = _bleManager.getConnectionState();
        var statusText = "";
        var statusColor = Graphics.COLOR_RED;

        switch (state) {
            case BleManager.STATE_DISCONNECTED:
                statusText = "Disconnected";
                statusColor = Graphics.COLOR_RED;
                break;
            case BleManager.STATE_SCANNING:
                statusText = "Scanning...";
                statusColor = Graphics.COLOR_YELLOW;
                break;
            case BleManager.STATE_CONNECTING:
                statusText = "Connecting...";
                statusColor = Graphics.COLOR_YELLOW;
                break;
            case BleManager.STATE_CONNECTED:
                statusText = "Connected";
                statusColor = Graphics.COLOR_ORANGE;
                break;
            case BleManager.STATE_SYNCING:
                statusText = "Syncing...";
                statusColor = Graphics.COLOR_ORANGE;
                break;
            case BleManager.STATE_READY:
                statusText = "Ready";
                statusColor = Graphics.COLOR_GREEN;
                break;
        }

        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 60, Graphics.FONT_MEDIUM, statusText, Graphics.TEXT_JUSTIFY_CENTER);

        // Node count and reconnect status
        if (_bleManager.isConnected()) {
            var nodeCount = _messageHandler.getNodeCount();
            var messageCount = _messageHandler.getMessages().size();

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, 100, Graphics.FONT_SMALL,
                       nodeCount + " nodes | " + messageCount + " msgs",
                       Graphics.TEXT_JUSTIFY_CENTER);
        } else if (_reconnectManager.getReconnectAttempts() > 0) {
            // Show reconnect attempts
            var attempts = _reconnectManager.getReconnectAttempts();
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, 100, Graphics.FONT_SMALL,
                       "Reconnecting (" + attempts + "/5)...",
                       Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Status message
        if (_statusMessage.length() > 0) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, 130, Graphics.FONT_TINY, _statusMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Menu options
        y = height - 100;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_TINY, "UP: Messages | DOWN: Nodes", Graphics.TEXT_JUSTIFY_CENTER);
        y += 20;
        dc.drawText(centerX, y, Graphics.FONT_TINY, "SELECT: Compose", Graphics.TEXT_JUSTIFY_CENTER);
        y += 20;

        if (state == BleManager.STATE_DISCONNECTED) {
            dc.drawText(centerX, y, Graphics.FONT_TINY, "START: Connect", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (state == BleManager.STATE_READY) {
            dc.drawText(centerX, y, Graphics.FONT_TINY, "MENU: Disconnect", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function setStatusMessage(message) {
        _statusMessage = message;
        WatchUi.requestUpdate();
    }

    function getBleManager() {
        return _bleManager;
    }

    function getMessageHandler() {
        return _messageHandler;
    }

    function getViewManager() {
        return _viewManager;
    }
}

class StatusViewDelegate extends WatchUi.BehaviorDelegate {
    private var _view;
    private var _viewManager;

    function initialize(view, viewManager) {
        BehaviorDelegate.initialize();
        _view = view;
        _viewManager = viewManager;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_UP) {
            // Show message list
            _viewManager.showMessageListView();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            // Show node list
            _viewManager.showNodeListView();
            return true;
        } else if (key == WatchUi.KEY_ENTER) {
            // Show compose view
            _viewManager.showComposeView();
            return true;
        } else if (key == WatchUi.KEY_START) {
            // Connect/scan
            handleConnect();
            return true;
        } else if (key == WatchUi.KEY_MENU) {
            // Disconnect
            handleDisconnect();
            return true;
        }

        return false;
    }

    function handleConnect() {
        var bleManager = _view.getBleManager();
        var state = bleManager.getConnectionState();

        if (state == BleManager.STATE_DISCONNECTED) {
            _view.setStatusMessage("Starting scan...");
            bleManager.startScan(method(:onConnectionResult));
        }
    }

    function handleDisconnect() {
        var bleManager = _view.getBleManager();
        if (bleManager.isConnected()) {
            bleManager.disconnect();
            _view.setStatusMessage("Disconnected");
        }
    }

    function onConnectionResult(success, error) {
        if (success) {
            _view.setStatusMessage("Connected! Syncing...");

            // Send want_config_id to initiate handshake
            var messageHandler = _view.getMessageHandler();
            var configRequest = messageHandler.createWantConfigRequest();
            if (configRequest != null) {
                _view.getBleManager().sendData(configRequest, null);
            }
        } else {
            _view.setStatusMessage(error != null ? error : "Connection failed");
        }
    }
}
