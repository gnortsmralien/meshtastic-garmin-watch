// HardwareConfig.mc
//
// Configuration settings for hardware deployment
// This file overrides Config.mc for hardware builds

module Config {
    // Build configuration flags
    // Set to false for hardware deployment
    const SIMULATOR_MODE = false;
    
    // Other configuration options
    const DEBUG_ENABLED = true;
    const SCAN_TIMEOUT_MS = 15000;
    const CONNECTION_TIMEOUT_MS = 10000;
    const DEFAULT_MESHTASTIC_PIN = "123456";
}