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
        System.println(">>> StatusView.initialize() START");
        View.initialize();
        System.println(">>> StatusView: Storing manager references...");
        _bleManager = bleManager;
        _messageHandler = messageHandler;
        _viewManager = viewManager;
        _systemMonitor = systemMonitor;
        _reconnectManager = reconnectManager;

        // Set PIN callback on BLE manager
        System.println(">>> StatusView: Setting PIN callback...");
        _bleManager.setPinCallback(method(:onPinRequested));
        System.println(">>> StatusView.initialize() COMPLETE");
    }

    function onPinRequested(device, callback) {
        // Show PIN entry view
        _viewManager.showPinEntryView(callback);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        System.println(">>> StatusView.onUpdate() called");
        try {
            System.println(">>> Setting colors and clearing screen");
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.clear();

            System.println(">>> Getting screen dimensions");
            var width = dc.getWidth();
            var height = dc.getHeight();
            var centerX = width / 2;
            var y = 40;

            // App title and system status
            System.println(">>> Drawing title");
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, 15, Graphics.FONT_SMALL, "Meshtastic", Graphics.TEXT_JUSTIFY_CENTER);

            // Battery and unread count in top corners
            System.println(">>> Updating system monitor");
            _systemMonitor.update();
            System.println(">>> Getting battery level");
            var battery = _systemMonitor.getBatteryLevel();
            System.println(">>> Battery: " + battery + "%");
            var batteryColor = battery < 20 ? Graphics.COLOR_RED : Graphics.COLOR_LT_GRAY;
            dc.setColor(batteryColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(10, 15, Graphics.FONT_TINY, battery + "%", Graphics.TEXT_JUSTIFY_LEFT);

            System.println(">>> Getting unread count");
            var unreadCount = _messageHandler.getUnreadCount();
            System.println(">>> Unread count: " + unreadCount);
            if (unreadCount > 0) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(width - 15, 22, 12);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width - 15, 15, Graphics.FONT_TINY, unreadCount.toString(), Graphics.TEXT_JUSTIFY_CENTER);
            }

            // Connection status
            System.println(">>> Getting connection state");
            var state = _bleManager.getConnectionState();
            System.println(">>> Connection state: " + state);
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

            System.println(">>> Drawing status: " + statusText);
            dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, 60, Graphics.FONT_MEDIUM, statusText, Graphics.TEXT_JUSTIFY_CENTER);

            // Node count and reconnect status
            System.println(">>> Checking if connected");
            if (_bleManager.isConnected()) {
                System.println(">>> Getting node and message counts");
                var nodeCount = _messageHandler.getNodeCount();
                var messageCount = _messageHandler.getMessages().size();

                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, 100, Graphics.FONT_SMALL,
                           nodeCount + " nodes | " + messageCount + " msgs",
                           Graphics.TEXT_JUSTIFY_CENTER);
            } else if (_reconnectManager.getReconnectAttempts() > 0) {
                System.println(">>> Drawing reconnect status");
                // Show reconnect attempts
                var attempts = _reconnectManager.getReconnectAttempts();
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, 100, Graphics.FONT_SMALL,
                           "Reconnecting (" + attempts + "/5)...",
                           Graphics.TEXT_JUSTIFY_CENTER);
            }

            // Status message
            System.println(">>> Drawing status message if present");
            if (_statusMessage.length() > 0) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, 130, Graphics.FONT_TINY, _statusMessage, Graphics.TEXT_JUSTIFY_CENTER);
            }

            // Menu options - split into two lines to fit on screen
            System.println(">>> Drawing menu options");
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);

            System.println(">>> Drawing state-specific menu items");
            if (state == BleManager.STATE_DISCONNECTED) {
                // Line 1: Navigation
                dc.drawText(centerX, height - 50, Graphics.FONT_XTINY, "UP:Msgs  DN:Nodes", Graphics.TEXT_JUSTIFY_CENTER);
                // Line 2: Action
                dc.drawText(centerX, height - 35, Graphics.FONT_XTINY, "SELECT:Connect", Graphics.TEXT_JUSTIFY_CENTER);
            } else if (state == BleManager.STATE_READY) {
                // Line 1: Navigation
                dc.drawText(centerX, height - 50, Graphics.FONT_XTINY, "UP:Msgs  DN:Nodes", Graphics.TEXT_JUSTIFY_CENTER);
                // Line 2: Action
                dc.drawText(centerX, height - 35, Graphics.FONT_XTINY, "SELECT:Compose", Graphics.TEXT_JUSTIFY_CENTER);
            }

            System.println(">>> StatusView.onUpdate() COMPLETE");
        } catch (ex) {
            System.println("!!! StatusView.onUpdate() CRASHED!");
            System.println("!!! Exception: " + ex);
            System.println("!!! Error message: " + ex.getErrorMessage());
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

    // Handle UP button - navigate to messages
    function onPreviousPage() {
        _viewManager.showMessageListView();
        return true;
    }

    // Handle DOWN button - navigate to nodes
    function onNextPage() {
        _viewManager.showNodeListView();
        return true;
    }

    // Handle SELECT button (primary action)
    function onSelect() {
        var bleManager = _view.getBleManager();
        var state = bleManager.getConnectionState();

        if (state == BleManager.STATE_DISCONNECTED) {
            // When disconnected, SELECT connects
            _view.setStatusMessage("Scanning for devices...");
            handleConnect();
        } else if (state == BleManager.STATE_READY) {
            // When connected, SELECT shows compose
            _viewManager.showComposeView();
        }
        return true;
    }

    // Handle MENU button
    function onMenu() {
        var bleManager = _view.getBleManager();
        if (bleManager.isConnected()) {
            handleDisconnect();
        } else {
            _viewManager.showSettingsView();
        }
        return true;
    }

    // Handle BACK button
    function onBack() {
        // Exit app or return to watch face
        return false;
    }

    // Legacy key handler for compatibility
    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_UP) {
            return onPreviousPage();
        } else if (key == WatchUi.KEY_DOWN) {
            return onNextPage();
        } else if (key == WatchUi.KEY_ENTER) {
            return onSelect();
        } else if (key == WatchUi.KEY_MENU) {
            return onMenu();
        } else if (key == WatchUi.KEY_ESC) {
            return onBack();
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
