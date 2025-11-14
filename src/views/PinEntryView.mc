// PinEntryView.mc
//
// View for entering Meshtastic device PIN during pairing
// Now uses TextPicker for easy keyboard input

using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

class PinEntryView extends WatchUi.View {
    private var _pin = "";
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
        dc.drawText(centerX, height / 2 - 60, Graphics.FONT_SMALL, _message, Graphics.TEXT_JUSTIFY_CENTER);

        // Current PIN (shown as asterisks for security, or actual digits)
        if (_pin.length() > 0) {
            // Show asterisks for security
            var displayPin = "";
            for (var i = 0; i < _pin.length(); i++) {
                displayPin += "*";
            }

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2 - 20, Graphics.FONT_LARGE, displayPin, Graphics.TEXT_JUSTIFY_CENTER);

            // Show actual PIN below in smaller font
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2 + 15, Graphics.FONT_SMALL, _pin, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2, Graphics.FONT_MEDIUM, "(empty)", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Instructions
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 50, Graphics.FONT_TINY,
                   "SELECT: Enter PIN", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, height - 35, Graphics.FONT_TINY,
                   "ENTER: Submit | BACK: Cancel", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function setPin(pin) {
        _pin = pin != null ? pin : "";
        WatchUi.requestUpdate();
    }

    function getPin() {
        return _pin;
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
            // Submit current PIN
            _view.submit();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            // Cancel PIN entry
            _view.cancel();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        }

        return false;
    }

    function onSelect() {
        // Open keyboard/text picker for PIN entry
        var textPicker = new WatchUi.TextPicker(_view.getPin());
        var delegate = new PinTextPickerDelegate(_view);
        WatchUi.pushView(textPicker, delegate, WatchUi.SLIDE_UP);
        return true;
    }
}

// Delegate for TextPicker (keyboard input)
class PinTextPickerDelegate extends WatchUi.TextPickerDelegate {
    private var _view;

    function initialize(view) {
        TextPickerDelegate.initialize();
        _view = view;
    }

    function onTextEntered(text, changed) {
        if (text != null) {
            _view.setPin(text);
        }
        return true;
    }
}
