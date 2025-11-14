# Build and Deploy Guide

## Prerequisites

1. **Garmin Connect IQ SDK** installed
2. **monkeyc** and **monkeydo** in your PATH
3. **developer_key** in the project root (or SDK default location)
4. **Fenix 8 Solar 51mm** watch or simulator

## Quick Start

### Option 1: Use Build Script (Easiest)

```bash
# On your Mac, from the project root:
./build.sh
```

This will create `build/meshtastic.prg`.

### Option 2: Manual Build

```bash
# Create build directory
mkdir -p build

# Build the app
monkeyc \
  -o build/meshtastic.prg \
  -f monkey.jungle \
  -d fenix8solar51mm \
  -y developer_key \
  -w
```

## Running the App

### In Simulator

```bash
# Run with monkeydo
monkeydo -d fenix8solar51mm -f build/meshtastic.prg
```

**Note:** BLE functionality won't work in simulator, but you can test:
- UI navigation (UP/DOWN/SELECT/MENU buttons)
- Settings screen (press MENU when "disconnected")
- PIN entry via keyboard

### On Real Device (USB)

```bash
# 1. Connect your Fenix 8 via USB
# 2. Deploy the app
monkeydo -d fenix8solar51mm -f build/meshtastic.prg
```

## Testing the New PIN Storage Feature

### Step 1: Configure PIN
1. Launch app on watch
2. Press **MENU** button → Settings opens
3. Navigate to "BLE PIN" → Press **SELECT**
4. Keyboard appears → Type your T1000E's PIN
5. PIN is saved to persistent storage

**Find your T1000E PIN:**
```bash
# Connect T1000E via USB, then:
meshtastic --get bluetooth.fixed_pin
```

### Step 2: Connect to T1000E
1. Press **START** button
2. Watch scans for BLE devices (10 seconds)
3. Auto-validates Meshtastic service UUID
4. Uses your saved PIN for pairing
5. Should connect and sync! 🎉

### Step 3: Use the App
- **UP**: View messages
- **DOWN**: View nodes
- **SELECT**: Compose message
- **MENU**: Settings (when disconnected) / Disconnect (when connected)

## Settings Options

The Settings screen includes:
- **BLE PIN**: Configure pairing PIN (persistent)
- **Auto-Reconnect**: Auto-reconnect on disconnect (default: ON)
- **Auto-Retry**: Try next device if wrong one connected (default: ON)
- **Reset Defaults**: Reset all settings to defaults

## Troubleshooting

### "Prg file doesn't exist"
You forgot to build! Run `./build.sh` first.

### "Cannot find developer_key"
Create a developer key:
```bash
openssl genrsa -out developer_key 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key -out developer_key.der -nocrypt
```

### BLE won't connect
1. Check T1000E PIN is correct: `meshtastic --get bluetooth.fixed_pin`
2. Make sure T1000E is powered on and not paired with another device
3. Check Settings → Auto-Retry is ON (to try multiple devices)
4. Look at watch logs for "Not a Meshtastic device" errors

### Connection timeout
1. Increase scan timeout in Settings Manager if needed
2. T1000E might be out of range
3. Check T1000E Bluetooth is enabled

## Build Variants

### Build BLE Connection Tests
```bash
monkeyc \
  -o build/ble-connection-test.prg \
  -f ble-connection-test.jungle \
  -d fenix8solar51mm \
  -y developer_key \
  -w
```

### Build Comprehensive Tests
```bash
monkeyc \
  -o build/comprehensive-test.prg \
  -f comprehensive-test.jungle \
  -d fenix8solar51mm \
  -y developer_key \
  -w
```

## Directory Structure

```
meshtastic-garmin-watch/
├── build/                  # Build output (created by build.sh)
│   └── meshtastic.prg     # Main app binary
├── src/                    # Source code
│   ├── MeshtasticApp.mc   # Main app entry point
│   ├── BleManager.mc      # BLE connection logic
│   ├── SettingsManager.mc # Persistent settings (NEW!)
│   ├── Config.mc          # Configuration constants
│   └── views/             # UI views
│       ├── StatusView.mc  # Main status screen
│       ├── SettingsView.mc # Settings screen (NEW!)
│       └── ...
├── monkey.jungle          # Build configuration
├── manifest.xml           # App manifest
├── build.sh              # Build script
└── developer_key         # Your signing key
```

## Next Steps

1. Build the app: `./build.sh`
2. Test in simulator: `monkeydo -d fenix8solar51mm -f build/meshtastic.prg`
3. Deploy to watch and test with real T1000E!
4. Report any issues or bugs

Happy Meshing! 📡
