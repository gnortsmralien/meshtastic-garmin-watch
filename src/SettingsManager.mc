// SettingsManager.mc
//
// Manages persistent app settings using Application.Storage

using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.System;
using Config;

class SettingsManager {
    // Storage keys
    private const KEY_BLE_PIN = "ble_pin";
    private const KEY_AUTO_RECONNECT = "auto_reconnect";
    private const KEY_AUTO_RETRY = "auto_retry";

    function initialize() {
        // Ensure default values are set on first run
        if (Storage.getValue(KEY_BLE_PIN) == null) {
            Storage.setValue(KEY_BLE_PIN, Config.DEFAULT_MESHTASTIC_PIN);
        }
        if (Storage.getValue(KEY_AUTO_RECONNECT) == null) {
            Storage.setValue(KEY_AUTO_RECONNECT, true);
        }
        if (Storage.getValue(KEY_AUTO_RETRY) == null) {
            Storage.setValue(KEY_AUTO_RETRY, true);
        }
    }

    // ============================================
    // BLE PIN
    // ============================================

    function getBlePin() {
        var pin = Storage.getValue(KEY_BLE_PIN);
        if (pin == null) {
            pin = Config.DEFAULT_MESHTASTIC_PIN;
            Storage.setValue(KEY_BLE_PIN, pin);
        }
        return pin;
    }

    function setBlePin(pin) {
        if (pin != null && pin.length() > 0) {
            Storage.setValue(KEY_BLE_PIN, pin);
            System.println("BLE PIN saved: " + pin);
            return true;
        }
        return false;
    }

    // ============================================
    // Auto-Reconnect
    // ============================================

    function getAutoReconnect() {
        var value = Storage.getValue(KEY_AUTO_RECONNECT);
        return value != null ? value : true;
    }

    function setAutoReconnect(enabled) {
        Storage.setValue(KEY_AUTO_RECONNECT, enabled);
        System.println("Auto-reconnect: " + enabled);
    }

    // ============================================
    // Auto-Retry Wrong Device
    // ============================================

    function getAutoRetry() {
        var value = Storage.getValue(KEY_AUTO_RETRY);
        return value != null ? value : true;
    }

    function setAutoRetry(enabled) {
        Storage.setValue(KEY_AUTO_RETRY, enabled);
        System.println("Auto-retry wrong device: " + enabled);
    }

    // ============================================
    // Reset to Defaults
    // ============================================

    function resetToDefaults() {
        Storage.setValue(KEY_BLE_PIN, Config.DEFAULT_MESHTASTIC_PIN);
        Storage.setValue(KEY_AUTO_RECONNECT, true);
        Storage.setValue(KEY_AUTO_RETRY, true);
        System.println("Settings reset to defaults");
    }
}
