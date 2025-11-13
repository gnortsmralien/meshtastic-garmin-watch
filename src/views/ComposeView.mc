// ComposeView.mc
//
// View for composing and sending messages (pre-defined quick messages)

using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

class ComposeView extends WatchUi.View {
    private var _bleManager;
    private var _messageHandler;
    private var _viewManager;
    private var _selectedIndex = 0;
    private var _statusMessage = "";

    // Pre-defined quick messages
    private var _quickMessages = [
        "OK",
        "Yes",
        "No",
        "Help needed",
        "On my way",
        "Arrived",
        "Where are you?",
        "All clear",
        "Standing by",
        "Copy that",
        "[Custom Message...]"  // Last option opens custom input
    ];

    function initialize(bleManager, messageHandler, viewManager) {
        View.initialize();
        _bleManager = bleManager;
        _messageHandler = messageHandler;
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
        dc.drawText(centerX, 10, Graphics.FONT_SMALL, "Send Message", Graphics.TEXT_JUSTIFY_CENTER);

        // Check if ready to send
        if (!_bleManager.isConnected()) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2, Graphics.FONT_SMALL,
                       "Not connected", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2 + 25, Graphics.FONT_TINY,
                       "Connect first", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        if (!_messageHandler.isConfigComplete()) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2, Graphics.FONT_SMALL,
                       "Syncing...", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2 + 25, Graphics.FONT_TINY,
                       "Please wait", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // Display message options (3 at a time)
        var y = 50;
        var lineHeight = 35;
        var displayCount = 3;
        var startIdx = _selectedIndex;

        // Adjust to show selected message in middle if possible
        if (_selectedIndex > 0 && _selectedIndex < _quickMessages.size() - 1) {
            startIdx = _selectedIndex - 1;
        }

        var endIdx = startIdx + displayCount;
        if (endIdx > _quickMessages.size()) {
            endIdx = _quickMessages.size();
            startIdx = endIdx - displayCount;
            if (startIdx < 0) {
                startIdx = 0;
            }
        }

        for (var i = startIdx; i < endIdx; i++) {
            var isSelected = (i == _selectedIndex);
            drawMessageOption(dc, _quickMessages[i], y, isSelected);
            y += lineHeight;
        }

        // Selection indicator
        var indicatorText = (_selectedIndex + 1) + "/" + _quickMessages.size();
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 60, Graphics.FONT_TINY, indicatorText, Graphics.TEXT_JUSTIFY_CENTER);

        // Status message
        if (_statusMessage.length() > 0) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height - 40, Graphics.FONT_TINY, _statusMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Instructions
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 20, Graphics.FONT_TINY,
                   "UP/DOWN: Select | ENTER: Send", Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawMessageOption(dc, message, y, isSelected) {
        var centerX = dc.getWidth() / 2;

        if (isSelected) {
            // Highlight selected message
            dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_DK_BLUE);
            dc.fillRectangle(10, y - 5, dc.getWidth() - 20, 30);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y + 3, Graphics.FONT_MEDIUM, message, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y + 3, Graphics.FONT_SMALL, message, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function scrollUp() {
        if (_selectedIndex > 0) {
            _selectedIndex--;
            _statusMessage = "";
            WatchUi.requestUpdate();
        }
    }

    function scrollDown() {
        if (_selectedIndex < _quickMessages.size() - 1) {
            _selectedIndex++;
            _statusMessage = "";
            WatchUi.requestUpdate();
        }
    }

    function sendSelectedMessage() {
        if (!_bleManager.isConnected() || !_messageHandler.isConfigComplete()) {
            _statusMessage = "Not ready to send";
            WatchUi.requestUpdate();
            return;
        }

        var message = _quickMessages[_selectedIndex];

        // Check if "Custom Message" option selected
        if (message.equals("[Custom Message...]")) {
            // Navigate to custom message view
            _viewManager.showCustomMessageView();
            return;
        }

        var packet = _messageHandler.createTextMessage(
            message,
            0xFFFFFFFF,  // Broadcast
            false        // No ACK
        );

        if (packet != null) {
            _bleManager.sendData(packet, method(:onSendComplete));
            _statusMessage = "Sending...";
            WatchUi.requestUpdate();
        } else {
            _statusMessage = "Failed to create message";
            WatchUi.requestUpdate();
        }
    }

    function onSendComplete(success, error) {
        if (success) {
            _statusMessage = "Sent!";
            // Auto-return after short delay would be nice, but we'll just update
            WatchUi.requestUpdate();
        } else {
            _statusMessage = "Send failed: " + error;
            WatchUi.requestUpdate();
        }
    }
}

class ComposeViewDelegate extends WatchUi.BehaviorDelegate {
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
            _view.scrollUp();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            _view.scrollDown();
            return true;
        } else if (key == WatchUi.KEY_ENTER) {
            _view.sendSelectedMessage();
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            _viewManager.goBack();
            return true;
        }

        return false;
    }
}
