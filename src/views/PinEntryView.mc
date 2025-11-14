// PinEntryView.mc
//
// View for entering Meshtastic device PIN during pairing

using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

class PinEntryView extends WatchUi.View {
    private var _pin = "";
    private var _maxLength = 6;
    private var _callback = null;
    private var _message = "Enter Device PIN";
    private var _currentDigit = 0; // For digit cycling

    function initialize(callback) {
        View.initialize();
        _callback = callback;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        // Title
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 30, Graphics.FONT_SMALL, _message, Graphics.TEXT_JUSTIFY_CENTER);

        // PIN display with asterisks
        var displayPin = "";
        for (var i = 0; i < _maxLength; i++) {
            if (i < _pin.length()) {
                displayPin += "*";
            } else {
                displayPin += "_";
            }
            displayPin += " ";
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height / 2 - 20, Graphics.FONT_LARGE, displayPin, Graphics.TEXT_JUSTIFY_CENTER);

        // Current PIN and digit selector
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height / 2 + 20, Graphics.FONT_MEDIUM, _pin, Graphics.TEXT_JUSTIFY_CENTER);

        // Show current digit being selected
        if (_pin.length() < _maxLength) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2 + 50, Graphics.FONT_LARGE,
                       "< " + _currentDigit + " >", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Instructions
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 50, Graphics.FONT_TINY,
                   "SELECT: Add | UP/DOWN: Cycle", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height - 35, Graphics.FONT_TINY,
                   "MENU: Delete | BACK: Clear", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height - 20, Graphics.FONT_TINY,
                   "ENTER: Submit", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function addDigit(digit) {
        if (_pin.length() < _maxLength) {
            _pin += digit.toString();
            _currentDigit = 0; // Reset for next digit
            WatchUi.requestUpdate();
        }
    }

    function deleteDigit() {
        if (_pin.length() > 0) {
            _pin = _pin.substring(0, _pin.length() - 1);
            _currentDigit = 0;
            WatchUi.requestUpdate();
        }
    }

    function clearPin() {
        _pin = "";
        _currentDigit = 0;
        WatchUi.requestUpdate();
    }

    function cycleCurrentDigit() {
        _currentDigit = (_currentDigit + 1) % 10;
        WatchUi.requestUpdate();
    }

    function getCurrentDigit() {
        return _currentDigit;
    }

    function submit() {
        if (_pin.length() > 0 && _callback != null) {
            _callback.invoke(_pin);
        }
    }

    function cancel() {
        if (_callback != null) {
            _callback.invoke(null);
        }
    }
}

class PinEntryViewDelegate extends WatchUi.BehaviorDelegate {
    private var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_ENTER) {
            _view.submit();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            _view.clearPin();
            return true;
        } else if (key == WatchUi.KEY_UP) {
            _view.cycleCurrentDigit();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            _view.cycleCurrentDigit();
            return true;
        } else if (key == WatchUi.KEY_MENU) {
            _view.deleteDigit();
            return true;
        }

        return false;
    }

    function onSelect() {
        // Add the current digit to the PIN
        _view.addDigit(_view.getCurrentDigit());
        return true;
    }
}
