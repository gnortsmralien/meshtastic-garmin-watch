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
        try {
            if (Storage.getValue(KEY_BLE_PIN) == null) {
                Storage.setValue(KEY_BLE_PIN, Config.DEFAULT_MESHTASTIC_PIN);
            }
            if (Storage.getValue(KEY_AUTO_RECONNECT) == null) {
                Storage.setValue(KEY_AUTO_RECONNECT, true);
            }
            if (Storage.getValue(KEY_AUTO_RETRY) == null) {
                Storage.setValue(KEY_AUTO_RETRY, true);
            }
        } catch (ex) {
            System.println("SettingsManager: Storage initialization failed, using defaults");
        }
    }

    // ============================================
    // BLE PIN
    // ============================================

    function getBlePin() {
        try {
            var pin = Storage.getValue(KEY_BLE_PIN);
            if (pin == null) {
                pin = Config.DEFAULT_MESHTASTIC_PIN;
                try {
                    Storage.setValue(KEY_BLE_PIN, pin);
                } catch (ex) {
                    // Storage write failed, just return default
                }
            }
            return pin;
        } catch (ex) {
            System.println("SettingsManager: Failed to get PIN, using default");
            return Config.DEFAULT_MESHTASTIC_PIN;
        }
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
        try {
            var value = Storage.getValue(KEY_AUTO_RECONNECT);
            return value != null ? value : true;
        } catch (ex) {
            return true;
        }
    }

    function setAutoReconnect(enabled) {
        Storage.setValue(KEY_AUTO_RECONNECT, enabled);
        System.println("Auto-reconnect: " + enabled);
    }

    // ============================================
    // Auto-Retry Wrong Device
    // ============================================

    function getAutoRetry() {
        try {
            var value = Storage.getValue(KEY_AUTO_RETRY);
            return value != null ? value : true;
        } catch (ex) {
            return true;
        }
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
