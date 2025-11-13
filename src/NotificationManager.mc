// NotificationManager.mc
//
// Handles user notifications (vibrate, tone, alerts)

using Toybox.Lang;
using Toybox.System;
using Toybox.Attention;

class NotificationManager {
    private var _vibrateEnabled = true;
    private var _toneEnabled = true;

    function initialize() {
        // Check if device supports attention features
        if (Attention has :vibrate) {
            System.println("Device supports vibration");
        }
        if (Attention has :playTone) {
            System.println("Device supports tones");
        }
    }

    // Notify user of new message
    function notifyNewMessage() {
        if (_vibrateEnabled && Attention has :vibrate) {
            var vibrateData = [
                new Attention.VibeProfile(50, 200),  // 50% intensity, 200ms
                new Attention.VibeProfile(0, 100),   // Pause 100ms
                new Attention.VibeProfile(75, 200)   // 75% intensity, 200ms
            ];
            Attention.vibrate(vibrateData);
        }

        if (_toneEnabled && Attention has :playTone) {
            Attention.playTone(Attention.TONE_SUCCESS);
        }
    }

    // Notify user of connection event
    function notifyConnected() {
        if (_vibrateEnabled && Attention has :vibrate) {
            var vibrateData = [
                new Attention.VibeProfile(50, 150)
            ];
            Attention.vibrate(vibrateData);
        }

        if (_toneEnabled && Attention has :playTone) {
            Attention.playTone(Attention.TONE_KEY);
        }
    }

    // Notify user of disconnection
    function notifyDisconnected() {
        if (_vibrateEnabled && Attention has :vibrate) {
            var vibrateData = [
                new Attention.VibeProfile(75, 300)
            ];
            Attention.vibrate(vibrateData);
        }

        if (_toneEnabled && Attention has :playTone) {
            Attention.playTone(Attention.TONE_ERROR);
        }
    }

    // Notify user of error
    function notifyError() {
        if (_vibrateEnabled && Attention has :vibrate) {
            var vibrateData = [
                new Attention.VibeProfile(100, 100),
                new Attention.VibeProfile(0, 50),
                new Attention.VibeProfile(100, 100),
                new Attention.VibeProfile(0, 50),
                new Attention.VibeProfile(100, 100)
            ];
            Attention.vibrate(vibrateData);
        }

        if (_toneEnabled && Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALARM);
        }
    }

    // Notify user of sent message
    function notifyMessageSent() {
        if (_vibrateEnabled && Attention has :vibrate) {
            var vibrateData = [
                new Attention.VibeProfile(30, 100)
            ];
            Attention.vibrate(vibrateData);
        }
    }

    function setVibrateEnabled(enabled) {
        _vibrateEnabled = enabled;
    }

    function setToneEnabled(enabled) {
        _toneEnabled = enabled;
    }

    function isVibrateEnabled() {
        return _vibrateEnabled;
    }

    function isToneEnabled() {
        return _toneEnabled;
    }
}
