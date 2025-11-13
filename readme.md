# Meshtastic Garmin Client

A Meshtastic client implementation for Garmin wearables using Connect IQ SDK. This project provides off-grid mesh communication capabilities directly on your Garmin watch.

## Features

- ✅ **Complete Protobuf Implementation** - Manual serialization/deserialization in Monkey C
- ✅ **BLE Communication** - Full BLE stack with Meshtastic protocol support
- ✅ **Streaming Protocol** - Meshtastic 4-byte header wrap/unwrap
- ✅ **Message Schemas** - Data, MeshPacket, Position message support
- ✅ **Command Queue** - Prevents BLE request drops with proper sequencing
- 🚧 **ToRadio/FromRadio** - Meshtastic-specific message handling (in progress)
- 🚧 **Connection Lifecycle** - Scan, connect, handshake, sync state machine (in progress)

## Prerequisites

- **Garmin Connect IQ SDK** (version 8.2+)
- **Garmin device** with BLE support (Fenix 8 recommended)
- **Meshtastic hardware** for real-world testing
- **Developer key** for signing builds

## Project Structure

```
├── src/                    # Source code
│   ├── ProtoBuf.mc        # Protobuf core module
│   ├── Encoder.mc         # Protobuf encoder
│   ├── Decoder.mc         # Protobuf decoder
│   ├── BleManager.mc      # BLE connection management
│   ├── BleCommandQueue.mc # BLE command sequencing
│   └── SimpleBleManager.mc # Simplified BLE for testing
├── tests/                 # Test applications
│   ├── FixedSimpleTest.mc # Protobuf tests
│   ├── InteractiveHardwareTest.mc # Interactive hardware testing
│   └── ComprehensiveTest.mc # All-in-one test suite
├── resources/             # App resources
└── build/                 # Build outputs
```

## Testing

  Quick Test Commands

  # For protobuf testing (works great)
  monkeyc -f proto-test.jungle -d fenix8solar51mm -o
  build/prototest.prg -y developer_key
  connectiq build/prototest.prg

  # For comprehensive testing
  monkeyc -f comprehensive-test.jungle -d fenix8solar51mm -o
  build/comprehensive.prg -y developer_key
  connectiq build/comprehensive.prg

  # For interactive simulator testing
  monkeyc -f interactive-test.jungle -d fenix8solar51mm -o build/interactive-simulator.prg -y developer_key
  connectiq build/interactive-simulator.prg

**Features:**
- Complete 7-screen UX flow testing
- Mock BLE devices (Meshtastic_1234, Meshtastic_5678, etc.)
- Simulated connection success/failure
- All button interactions work
- Debug output shows "[MOCK]" prefixes

#### B. Hardware Mode (Real Device Required)

Test with actual Meshtastic hardware:

**Prerequisites:**
1. **Meshtastic Device Setup:**
   - Power on your Meshtastic device
   - Ensure BLE is enabled in device settings
   - Device should appear as "Meshtastic_XXXX" when scanning
   - Note the device PIN (default: 123456)

2. **Garmin Device Setup:**
   - Connect your Garmin device to computer via USB
   - Enable Developer Mode if required
   - Install Garmin Express or Connect IQ mobile app for deployment

**Build and Deploy:**
```bash
# Build interactive hardware test (real BLE)
monkeyc -f hardware-interactive-test.jungle -d fenix8solar51mm -o build/interactive-hardware.prg -y developer_key --warn

# Deploy to device using one of these methods:
# Option A: Using Garmin Express
# - Copy build/interactive-hardware.prg to your device via Garmin Express

# Option B: Using Connect IQ Mobile App
# - Install Connect IQ mobile app
# - Use "Load App" feature to sideload the .prg file

# Option C: Using connectiq tool (if available)
# connectiq -i build/interactive-hardware.prg -d [device_id]
```

#### Using the Interactive Test App

The interactive test provides a complete UX flow for testing with real hardware:

##### **Screen 1: Start Screen**
- Shows "Ready to test with Meshtastic hardware"
- **Press START** to begin scanning

##### **Screen 2: Scanning Screen**
- Shows "Scanning..." with animated dots
- Displays count of found devices
- **Press BACK** to cancel
- **Press START** to simulate finding a device (for testing)

##### **Screen 3: Device Selection**
- Lists found Meshtastic devices
- **UP/DOWN** to select device
- **START** to connect to selected device
- **BACK** to cancel

##### **Screen 4: PIN Entry**
- Shows "Enter PIN" screen
- Displays default PIN (123456)
- **START** to use default PIN
- **BACK** to cancel

##### **Screen 5: Connecting**
- Shows "Connecting..." with device name
- Displays connection progress
- Auto-advances on success/failure

##### **Screen 6: Results**
- Shows SUCCESS (green) or FAILED (red)
- Displays error message if failed
- **START** to try again
- **BACK** to exit

##### **Screen 7: Connected** (if successful)
- Shows "Connected!" with device name
- **UP/DOWN** to run additional tests
- **BACK** to disconnect

#### Hardware Test Troubleshooting

**No devices found:**
- Ensure Meshtastic device is powered on
- Check device is in pairing mode
- Verify BLE is enabled on both devices
- Try moving devices closer together

**Connection failed:**
- Device may already be paired to another device
- Check PIN is correct (default: 123456)
- Restart both devices
- Check BLE permissions in manifest

**App crashes:**
- Check debug console for error messages
- Verify BLE permissions are set correctly
- Ensure device has sufficient memory

#### Debug Output

Monitor debug output using:
- **Garmin Express** debug console
- **Connect IQ mobile app** logs
- **VS Code Connect IQ extension** output panel

Example debug output:
```
=== Interactive Hardware Test App Starting ===
✓ BLE profile registered successfully
Starting BLE scan...
✓ Scan started successfully
Simulated device found: Meshtastic_1234
Selected device: Meshtastic_1234
Starting connection to device...
✓ Connection successful!
Test result: SUCCESS
```

## Development Commands

### Build Commands

```bash
# Main application
monkeyc -f monkey.jungle -d fenix8solar51mm -o build/meshtastic.prg -y developer_key

# Protobuf tests
monkeyc -f proto-test.jungle -d fenix8solar51mm -o build/prototest.prg -y developer_key

# Interactive tests (simulator mode)
monkeyc -f interactive-test.jungle -d fenix8solar51mm -o build/interactive-simulator.prg -y developer_key

# Interactive tests (hardware mode)
monkeyc -f hardware-interactive-test.jungle -d fenix8solar51mm -o build/interactive-hardware.prg -y developer_key

# Comprehensive tests
monkeyc -f comprehensive-test.jungle -d fenix8solar51mm -o build/comprehensive.prg -y developer_key
```

### Run Commands

```bash
# Run in simulator
connectiq build/prototest.prg

# Run with unit tests
monkeyc -f proto-test.jungle -d fenix8solar51mm -o build/unittest.prg -y developer_key --unit-test

# Build with warnings
monkeyc -f [jungle-file] -d fenix8solar51mm -o build/output.prg -y developer_key --warn
```

## Testing Strategy

### 1. **Simulator Testing** (No Hardware Required)
- Use `proto-test.jungle` for protobuf functionality
- Use `comprehensive-test.jungle` for all components
- Perfect for development and CI/CD

### 2. **Hardware Testing** (Requires Real Devices)
- Use `interactive-test.jungle` for full BLE testing
- Deploy to actual Garmin device
- Test with real Meshtastic hardware

### 3. **Integration Testing**
- Start with simulator tests to verify core functionality
- Move to hardware tests for BLE and real-world scenarios
- Use interactive test app for user acceptance testing

## Known Limitations

- **Simulator BLE:** Connect IQ simulator cannot connect to real BLE devices
- **Hardware Dependency:** Full testing requires actual Meshtastic hardware
- **Platform Specific:** Iterator handling varies across Garmin devices
- **Memory Constraints:** Watch apps have limited memory for node databases

## Next Steps

1. **Complete ToRadio/FromRadio implementation**
2. **Add connection lifecycle state machine**
3. **Implement text messaging functionality**
4. **Add admin message support**
5. **Create comprehensive UI for real app**

## Support

For issues and questions:
- Check debug console output for error messages
- Verify hardware setup matches requirements
- Ensure all prerequisites are installed
- Review troubleshooting section for common issues

---

**Note:** This is a complex project requiring deep knowledge of both Garmin Connect IQ and Meshtastic protocols. The manual protobuf implementation represents significant engineering effort and ongoing maintenance.