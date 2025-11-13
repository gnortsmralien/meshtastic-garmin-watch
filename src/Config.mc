// Config.mc
//
// Configuration settings for the application

module Config {
    // Build configuration flags
    // Set to true for simulator testing, false for hardware deployment
    const SIMULATOR_MODE = true;
    
    // Other configuration options
    const DEBUG_ENABLED = true;
    const SCAN_TIMEOUT_MS = 15000;
    const CONNECTION_TIMEOUT_MS = 10000;
    const DEFAULT_MESHTASTIC_PIN = "123456";
}