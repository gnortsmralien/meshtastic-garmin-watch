// CustomMessageView.mc
//
// View for composing custom messages character-by-character

using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

class CustomMessageView extends WatchUi.View {
    private var _bleManager;
    private var _messageHandler;
    private var _viewManager;
    private var _messageText = "";
    private var _statusMessage = "";

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
        dc.drawText(centerX, 15, Graphics.FONT_SMALL, "Custom Message", Graphics.TEXT_JUSTIFY_CENTER);

        // Current message text
        if (_messageText.length() > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

            // Word wrap the text
            var lines = wordWrap(_messageText, 18); // ~18 chars per line
            var y = 50;
            for (var i = 0; i < lines.size() && i < 3; i++) {
                dc.drawText(centerX, y, Graphics.FONT_SMALL, lines[i], Graphics.TEXT_JUSTIFY_CENTER);
                y += 25;
            }

            if (lines.size() > 3) {
                dc.drawText(centerX, y, Graphics.FONT_TINY, "...", Graphics.TEXT_JUSTIFY_CENTER);
            }
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2 - 20, Graphics.FONT_SMALL,
                       "(empty)", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Status message
        if (_statusMessage.length() > 0) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height - 60, Graphics.FONT_TINY, _statusMessage, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Instructions - split into multiple lines to fit screen
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 50, Graphics.FONT_XTINY,
                   "SELECT: Edit Text", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height - 35, Graphics.FONT_XTINY,
                   "ENTER: Send", Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function wordWrap(text, maxChars) {
        var lines = [];
        var currentLine = "";
        var words = splitString(text, " ");

        for (var i = 0; i < words.size(); i++) {
            var word = words[i];

            if (currentLine.length() + word.length() + 1 <= maxChars) {
                if (currentLine.length() > 0) {
                    currentLine += " ";
                }
                currentLine += word;
            } else {
                if (currentLine.length() > 0) {
                    lines.add(currentLine);
                }
                currentLine = word;
            }
        }

        if (currentLine.length() > 0) {
            lines.add(currentLine);
        }

        return lines;
    }

    private function splitString(text, delimiter) {
        var words = [];
        var currentWord = "";

        for (var i = 0; i < text.length(); i++) {
            var char = text.substring(i, i + 1);
            if (char.equals(delimiter)) {
                if (currentWord.length() > 0) {
                    words.add(currentWord);
                    currentWord = "";
                }
            } else {
                currentWord += char;
            }
        }

        if (currentWord.length() > 0) {
            words.add(currentWord);
        }

        return words;
    }

    function setMessageText(text) {
        _messageText = text;
        _statusMessage = "";
        WatchUi.requestUpdate();
    }

    function sendMessage() {
        if (_messageText.length() == 0) {
            _statusMessage = "Message is empty";
            WatchUi.requestUpdate();
            return;
        }

        if (!_bleManager.isConnected() || !_messageHandler.isConfigComplete()) {
            _statusMessage = "Not ready to send";
            WatchUi.requestUpdate();
            return;
        }

        var packet = _messageHandler.createTextMessage(
            _messageText,
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
            _messageText = ""; // Clear after sending
            WatchUi.requestUpdate();
        } else {
            _statusMessage = "Send failed";
            WatchUi.requestUpdate();
        }
    }

    function getViewManager() {
        return _viewManager;
    }

    function getMessageText() {
        return _messageText;
    }
}

class CustomMessageViewDelegate extends WatchUi.BehaviorDelegate {
    private var _view;
    private var _viewManager;

    function initialize(view, viewManager) {
        BehaviorDelegate.initialize();
        _view = view;
        _viewManager = viewManager;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_ENTER) {
            // Send the message
            _view.sendMessage();
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            _viewManager.goBack();
            return true;
        }

        return false;
    }

    function onSelect() {
        // SELECT button opens text input
        showTextInput();
        return true;
    }

    function showTextInput() {
        // Use TextPicker which provides a full keyboard on modern devices
        var textPicker = new WatchUi.TextPicker(_view.getMessageText());
        WatchUi.pushView(textPicker, new $.TextPickerDelegate(_view), WatchUi.SLIDE_UP);
    }
}

class TextPickerDelegate extends WatchUi.TextPickerDelegate {
    private var _view;

    function initialize(view) {
        TextPickerDelegate.initialize();
        _view = view;
    }

    function onTextEntered(text, changed) {
        // Always save the text, even if empty (allows clearing)
        if (text != null) {
            _view.setMessageText(text);
        }
        return true;
    }

    function onCancel() {
        // User cancelled - don't change the text
        return true;
    }
}
