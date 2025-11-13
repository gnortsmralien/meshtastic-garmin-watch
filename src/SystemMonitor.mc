// SystemMonitor.mc
//
// Monitors system resources (battery, memory, etc.)

using Toybox.Lang;
using Toybox.System;

class SystemMonitor {
    private var _batteryLevel = 0;
    private var _memoryUsed = 0;
    private var _memoryTotal = 0;
    private var _memoryPercent = 0;

    function initialize() {
        update();
    }

    // Update all system metrics
    function update() {
        updateBattery();
        updateMemory();
    }

    private function updateBattery() {
        var stats = System.getSystemStats();
        if (stats != null && stats has :battery) {
            _batteryLevel = stats.battery.toNumber();
        } else {
            _batteryLevel = 100; // Assume full if not available
        }
    }

    private function updateMemory() {
        var stats = System.getSystemStats();
        if (stats != null) {
            if (stats has :usedMemory) {
                _memoryUsed = stats.usedMemory;
            }
            if (stats has :totalMemory) {
                _memoryTotal = stats.totalMemory;
            }

            if (_memoryTotal > 0) {
                _memoryPercent = (_memoryUsed * 100) / _memoryTotal;
            }
        }
    }

    // Get battery level (0-100)
    function getBatteryLevel() {
        return _batteryLevel;
    }

    // Get battery status string
    function getBatteryStatus() {
        if (_batteryLevel >= 80) {
            return "Full";
        } else if (_batteryLevel >= 50) {
            return "Good";
        } else if (_batteryLevel >= 20) {
            return "Low";
        } else {
            return "Critical";
        }
    }

    // Get battery icon character (Unicode battery symbols)
    function getBatteryIcon() {
        if (_batteryLevel >= 80) {
            return "■"; // Full
        } else if (_batteryLevel >= 50) {
            return "▣"; // 3/4
        } else if (_batteryLevel >= 20) {
            return "▢"; // 1/2
        } else {
            return "▱"; // Low
        }
    }

    // Check if battery is low
    function isBatteryLow() {
        return _batteryLevel < 20;
    }

    // Get memory usage percent
    function getMemoryUsagePercent() {
        return _memoryPercent;
    }

    // Get memory usage string
    function getMemoryStatus() {
        if (_memoryTotal > 0) {
            var usedKB = _memoryUsed / 1024;
            var totalKB = _memoryTotal / 1024;
            return usedKB + "/" + totalKB + " KB";
        }
        return "Unknown";
    }

    // Check if memory is running low
    function isMemoryLow() {
        return _memoryPercent > 80;
    }

    // Get formatted system info string
    function getSystemInfo() {
        var info = "Battery: " + _batteryLevel + "% (" + getBatteryStatus() + ")\n";
        info += "Memory: " + getMemoryStatus();
        return info;
    }
}
