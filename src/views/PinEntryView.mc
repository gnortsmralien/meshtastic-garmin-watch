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

        // Current PIN (small text below)
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height / 2 + 20, Graphics.FONT_MEDIUM, _pin, Graphics.TEXT_JUSTIFY_CENTER);

        // Instructions
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 50, Graphics.FONT_TINY,
                   "SELECT: Enter Digit", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height - 35, Graphics.FONT_TINY,
                   "UP: Delete | DOWN: Clear", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height - 20, Graphics.FONT_TINY,
                   "ENTER: Submit | BACK: Cancel", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function addDigit(digit) {
        if (_pin.length() < _maxLength) {
            _pin += digit.toString();
            WatchUi.requestUpdate();
        }
    }

    function deleteDigit() {
        if (_pin.length() > 0) {
            _pin = _pin.substring(0, _pin.length() - 1);
            WatchUi.requestUpdate();
        }
    }

    function clearPin() {
        _pin = "";
        WatchUi.requestUpdate();
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
            _view.cancel();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        } else if (key == WatchUi.KEY_UP) {
            _view.deleteDigit();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            _view.clearPin();
            return true;
        }

        return false;
    }

    function onSelect() {
        // Show number picker for digit entry
        var picker = new WatchUi.NumberPicker(WatchUi.NUMBER_PICKER_NUMBER);
        WatchUi.pushView(picker, new NumberPickerDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }
}

class NumberPickerDelegate extends WatchUi.NumberPickerDelegate {
    private var _view;

    function initialize(view) {
        NumberPickerDelegate.initialize();
        _view = view;
    }

    function onNumberPicked(value) {
        if (value != null) {
            _view.addDigit(value);
        }
    }
}
