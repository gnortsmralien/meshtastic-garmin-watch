# Meshtastic Garmin Client

A Meshtastic client implementation for Garmin wearables using Connect IQ SDK.

## Prerequisites

- **Garmin Connect IQ SDK** 8.3.0 or higher
- **Developer key** for signing builds
- **Garmin device** with BLE support (Fenix 8 Solar recommended) or simulator

## Setup

1. Install the Connect IQ SDK via SDK Manager
2. Generate a developer key if you don't have one:
   ```bash
   openssl genrsa -out developer_key 4096
   ```

## Build

Build the main application:
```bash
monkeyc -f monkey.jungle -d fenix8solar51mm -o build/meshtastic.prg -y developer_key
```

Build the interactive simulator test:
```bash
monkeyc -f interactive-test.jungle -d fenix8solar51mm -o build/interactive-simulator.prg -y developer_key
```

Build the protobuf test:
```bash
monkeyc -f proto-test.jungle -d fenix8solar51mm -o build/prototest.prg -y developer_key
```

Build the comprehensive test:
```bash
monkeyc -f comprehensive-test.jungle -d fenix8solar51mm -o build/comprehensive.prg -y developer_key
```

## Run in Simulator

### Simulator Build with Mock BLE (Recommended)

We provide a special simulator build that uses mock BLE to avoid crashes:

```bash
# Build simulator version (includes mock BLE)
./build.sh

# Or build manually:
monkeyc -f simulator.jungle -d fenix8solar51mm -o build/meshtastic-sim.prg -y developer_key -w

# Run in simulator
connectiq build/meshtastic-sim.prg &
```

**Mock BLE Features:**
- ✅ Simulates device discovery (3 mock Meshtastic devices)
- ✅ Simulates connection flow (scanning → connecting → syncing → ready)
- ✅ Simulates config sync
- ✅ No BLE crashes!

**Simulator Limitations:**
- ⚠️ Message sending may trigger watchdog timeout in simulator (protobuf encoding is slow in simulator)
- ⚠️ This is a simulator performance limitation - works fine on real hardware
- ✅ You can still test: UI navigation, connection flow, view layouts

For full testing including message sending, deploy to real hardware.

### Device Build (Real BLE)

The device build uses real BLE for actual Meshtastic hardware:

```bash
# Build device version (real BLE)
monkeyc -f monkey.jungle -d fenix8solar51mm -o build/meshtastic.prg -y developer_key -w
```

**⚠️ WARNING:** The device build WILL CRASH in the simulator on macOS due to a known Garmin SDK bug with BLE. See [SIMULATOR_CRASH.md](SIMULATOR_CRASH.md) for details. **Always use the simulator build for testing in the simulator.**

Run protobuf tests:
```bash
monkeydo build/prototest.prg fenix8solar51mm
```

## Deploy to Device

### Method 1: Direct USB Copy (Sideloading - Recommended for Development)

1. Build the app for your device:
   ```bash
   monkeyc -f monkey.jungle -d fenix8solar51mm -o build/meshtastic.prg -y developer_key
   ```

2. Connect your Garmin watch via USB cable

3. The watch will appear as a USB storage device (e.g., `/Volumes/GARMIN`)

4. Copy the `.prg` file to the APPS folder on the watch:
   ```bash
   cp build/meshtastic.prg /Volumes/GARMIN/GARMIN/APPS/
   ```

5. Safely eject the watch from your computer

6. **Important:** On newer watches, the .prg file will disappear from the folder immediately after copying - this is normal! The watch has processed and installed it.

7. On the watch, press the UP button to open the app menu and scroll to find "Meshtastic"

### Method 2: Using Garmin Express (For Viewing/Managing)

**Note:** Garmin Express cannot directly install custom .prg files, but it's useful for managing sideloaded apps.

1. Install [Garmin Express](https://www.garmin.com/en-US/software/express/)

2. After sideloading via USB (Method 1), connect your watch to Garmin Express

3. Your sideloaded app will appear as a "development version" in Garmin Express

4. You can use Garmin Express to:
   - View installed sideloaded apps
   - Uninstall sideloaded apps (can't be done via the Connect IQ mobile app)
   - Sync other device data

### Method 3: Connect IQ Store App on Watch (For Management)

1. After sideloading, open the Connect IQ Store app on your watch

2. Navigate to "Installed"

3. Your app will appear with a "development version" label

4. You can delete the app from here if needed

### Verify Installation

After sideloading:
1. The .prg file will disappear from /GARMIN/APPS/ (normal behavior on modern watches)
2. Press the UP button on your watch to open the app menu
3. Scroll to find "Meshtastic"
4. Select it to launch the app
5. You should see the status screen with "Disconnected" (if no Meshtastic device is nearby)

If the app doesn't appear, try:
- Restarting the watch
- Checking the file was copied to `/GARMIN/APPS/` (not `/Garmin/Apps/` - case matters on some systems)
- Verifying the .prg was built for the correct device model

## Project Structure

```
├── src/                          # Source code
│   ├── MeshtasticApp.mc         # Main application
│   ├── BleManager.mc            # BLE connection management
│   ├── BleCommandQueue.mc       # BLE command sequencing
│   ├── MessageHandler.mc        # Message processing
│   ├── ProtoBuf.mc              # Protobuf core
│   ├── Encoder.mc               # Protobuf encoder
│   ├── Decoder.mc               # Protobuf decoder
│   ├── ViewManager.mc           # View coordination
│   ├── NotificationManager.mc   # Notification handling
│   ├── SystemMonitor.mc         # System monitoring
│   ├── ReconnectManager.mc      # Connection recovery
│   └── views/                   # UI views
├── tests/                       # Test applications
├── resources/                   # App resources
└── build/                       # Build outputs
```

## Testing

See [TESTING.md](TESTING.md) for comprehensive testing documentation.

## Implementation Status

- ✅ Complete Protobuf implementation
- ✅ BLE communication layer
- ✅ Message handling system
- ✅ UI views and navigation
- ✅ Notification management
- 🚧 Full Meshtastic protocol integration (in progress)

For detailed implementation plans, see:
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)
- [PHASE1_COMPLETE.md](PHASE1_COMPLETE.md)
- [PHASE2_COMPLETE.md](PHASE2_COMPLETE.md)
