// Config.mc
//
// Configuration settings for the application

module Config {
    // ============================================
    // Build Configuration
    // ============================================

    // Set to true for simulator testing, false for hardware deployment
    const SIMULATOR_MODE = true;

    // Enable debug logging
    const DEBUG_ENABLED = true;

    // ============================================
    // BLE Pairing Configuration
    // ============================================

    // Default Meshtastic PIN for BLE pairing
    // ⚠️ CHANGE THIS to match your T1000E device PIN ⚠️
    //
    // To find your T1000E PIN:
    //   1. Connect T1000E via USB
    //   2. Run: meshtastic --get bluetooth.fixed_pin
    //   3. OR check T1000E screen during pairing
    //
    // Common PINs:
    //   "123456" - Default Meshtastic PIN
    //   "000000" - Some devices use this
    //   Custom  - Your T1000E might have a custom PIN
    //
    const DEFAULT_MESHTASTIC_PIN = "123456";  // ← CHANGE THIS if needed

    // ============================================
    // Connection Timeouts
    // ============================================

    // BLE scan timeout (milliseconds)
    const SCAN_TIMEOUT_MS = 10000;  // 10 seconds (reduced for faster connection)

    // Connection timeout (milliseconds)
    const CONNECTION_TIMEOUT_MS = 10000;  // 10 seconds

    // ============================================
    // Message Configuration
    // ============================================

    // Maximum messages to store in history
    const MAX_MESSAGES = 50;

    // Maximum nodes to track
    const MAX_NODES = 100;

    // Default hop limit for messages
    const DEFAULT_HOP_LIMIT = 3;
}