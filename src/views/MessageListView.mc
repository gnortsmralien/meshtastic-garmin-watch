// MessageListView.mc
//
// Displays a scrollable list of received messages

using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

class MessageListView extends WatchUi.View {
    private var _messageHandler;
    private var _viewManager;
    private var _scrollIndex = 0;
    private var _itemsPerPage = 3;

    function initialize(messageHandler, viewManager) {
        View.initialize();
        _messageHandler = messageHandler;
        _viewManager = viewManager;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var centerX = width / 2;

        // Title
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 10, Graphics.FONT_SMALL, "Messages", Graphics.TEXT_JUSTIFY_CENTER);

        // Get messages
        var messages = _messageHandler.getMessages();
        var messageCount = messages.size();

        if (messageCount == 0) {
            // No messages
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, dc.getHeight() / 2, Graphics.FONT_SMALL,
                       "No messages yet", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            // Draw messages
            var y = 45;
            var lineHeight = 60;

            // Calculate which messages to show
            var startIdx = _scrollIndex;
            var endIdx = startIdx + _itemsPerPage;
            if (endIdx > messageCount) {
                endIdx = messageCount;
            }

            for (var i = startIdx; i < endIdx; i++) {
                var message = messages[i];
                drawMessage(dc, message, y, i == _scrollIndex);
                y += lineHeight;
            }

            // Scroll indicator
            if (messageCount > _itemsPerPage) {
                var scrollText = (_scrollIndex + 1) + "/" + messageCount;
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, dc.getHeight() - 40, Graphics.FONT_TINY,
                           scrollText, Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        // Instructions
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, dc.getHeight() - 20, Graphics.FONT_TINY,
                   "UP/DOWN: Scroll | BACK: Return", Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawMessage(dc, message, y, isSelected) {
        var centerX = dc.getWidth() / 2;

        // Highlight if selected
        if (isSelected) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            dc.fillRectangle(5, y - 5, dc.getWidth() - 10, 50);
        }

        // From address
        var from = message[:from];
        var fromText = "From: " + from.format("%08X");
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_TINY, fromText, Graphics.TEXT_JUSTIFY_CENTER);

        // Message text (truncated)
        var text = message[:text];
        if (text.length() > 25) {
            text = text.substring(0, 22) + "...";
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y + 15, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER);

        // Timestamp (simple format)
        var timestamp = message[:timestamp];
        var timeText = formatTime(timestamp);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y + 35, Graphics.FONT_XTINY, timeText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function formatTime(timestamp) {
        // Simple time formatting
        var now = System.getTimer() / 1000;
        var diff = now - timestamp;

        if (diff < 60) {
            return "Just now";
        } else if (diff < 3600) {
            return (diff / 60) + "m ago";
        } else if (diff < 86400) {
            return (diff / 3600) + "h ago";
        } else {
            return (diff / 86400) + "d ago";
        }
    }

    function scrollUp() {
        if (_scrollIndex > 0) {
            _scrollIndex--;
            WatchUi.requestUpdate();
        }
    }

    function scrollDown() {
        var messageCount = _messageHandler.getMessages().size();
        if (_scrollIndex < messageCount - 1) {
            _scrollIndex++;
            WatchUi.requestUpdate();
        }
    }
}

class MessageListViewDelegate extends WatchUi.BehaviorDelegate {
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
        } else if (key == WatchUi.KEY_ESC) {
            _viewManager.goBack();
            return true;
        }

        return false;
    }
}
