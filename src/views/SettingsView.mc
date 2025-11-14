// SettingsView.mc
//
// Settings configuration screen

using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

class SettingsView extends WatchUi.View {
    private var _settingsManager;
    private var _viewManager;
    private var _selectedIndex = 0;
    private var _menuItems = [
        "BLE PIN",
        "Auto-Reconnect",
        "Auto-Retry",
        "Reset Defaults"
    ];

    function initialize(settingsManager, viewManager) {
        View.initialize();
        _settingsManager = settingsManager;
        _viewManager = viewManager;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        // Title
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 15, Graphics.FONT_SMALL, "Settings", Graphics.TEXT_JUSTIFY_CENTER);

        // Menu items
        var y = 50;
        var itemHeight = 35;

        for (var i = 0; i < _menuItems.size() && i < 4; i++) {
            var itemY = y + (i * itemHeight);

            // Highlight selected item
            if (i == _selectedIndex) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(0, itemY - 5, width, itemHeight - 5);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            }

            // Menu item text
            var itemText = _menuItems[i];
            dc.drawText(10, itemY, Graphics.FONT_SMALL, itemText, Graphics.TEXT_JUSTIFY_LEFT);

            // Show current value for settings
            if (i == 0) {  // BLE PIN
                var pin = _settingsManager.getBlePin();
                var displayPin = "";
                for (var j = 0; j < pin.length(); j++) {
                    displayPin += "*";
                }
                dc.drawText(width - 10, itemY, Graphics.FONT_TINY, displayPin, Graphics.TEXT_JUSTIFY_RIGHT);
            } else if (i == 1) {  // Auto-Reconnect
                var enabled = _settingsManager.getAutoReconnect();
                dc.drawText(width - 10, itemY, Graphics.FONT_TINY,
                           enabled ? "ON" : "OFF", Graphics.TEXT_JUSTIFY_RIGHT);
            } else if (i == 2) {  // Auto-Retry
                var enabled = _settingsManager.getAutoRetry();
                dc.drawText(width - 10, itemY, Graphics.FONT_TINY,
                           enabled ? "ON" : "OFF", Graphics.TEXT_JUSTIFY_RIGHT);
            }
        }

        // Instructions
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 40, Graphics.FONT_TINY,
                   "UP/DOWN: Navigate", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height - 25, Graphics.FONT_TINY,
                   "SELECT: Change | BACK: Exit", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function moveUp() {
        _selectedIndex = (_selectedIndex - 1 + _menuItems.size()) % _menuItems.size();
        WatchUi.requestUpdate();
    }

    function moveDown() {
        _selectedIndex = (_selectedIndex + 1) % _menuItems.size();
        WatchUi.requestUpdate();
    }

    function selectItem() {
        switch (_selectedIndex) {
            case 0:  // BLE PIN
                showPinEntry();
                break;
            case 1:  // Auto-Reconnect
                toggleAutoReconnect();
                break;
            case 2:  // Auto-Retry
                toggleAutoRetry();
                break;
            case 3:  // Reset Defaults
                resetDefaults();
                break;
        }
    }

    private function showPinEntry() {
        var currentPin = _settingsManager.getBlePin();
        var textPicker = new WatchUi.TextPicker(currentPin);
        var delegate = new SettingsPinDelegate(_settingsManager);
        WatchUi.pushView(textPicker, delegate, WatchUi.SLIDE_UP);
    }

    private function toggleAutoReconnect() {
        var current = _settingsManager.getAutoReconnect();
        _settingsManager.setAutoReconnect(!current);
        WatchUi.requestUpdate();
    }

    private function toggleAutoRetry() {
        var current = _settingsManager.getAutoRetry();
        _settingsManager.setAutoRetry(!current);
        WatchUi.requestUpdate();
    }

    private function resetDefaults() {
        _settingsManager.resetToDefaults();
        WatchUi.requestUpdate();
    }

    function getViewManager() {
        return _viewManager;
    }
}

class SettingsViewDelegate extends WatchUi.BehaviorDelegate {
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
            _view.moveUp();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            _view.moveDown();
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            _viewManager.goBack();
            return true;
        }

        return false;
    }

    function onSelect() {
        _view.selectItem();
        return true;
    }
}

// Delegate for PIN text picker in settings
class SettingsPinDelegate extends WatchUi.TextPickerDelegate {
    private var _settingsManager;

    function initialize(settingsManager) {
        TextPickerDelegate.initialize();
        _settingsManager = settingsManager;
    }

    function onTextEntered(text, changed) {
        if (text != null && text.length() > 0) {
            _settingsManager.setBlePin(text);
            System.println("New PIN set: " + text);
        }
        return true;
    }
}
