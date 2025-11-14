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

## Run

Run in the simulator:
```bash
connectiq build/interactive-simulator.prg
```

Run protobuf tests:
```bash
connectiq build/prototest.prg
```

## Deploy to Device

1. Connect your Garmin device via USB
2. Copy the `.prg` file to your device using Garmin Express or the Connect IQ mobile app
3. Or use the connectiq tool:
   ```bash
   connectiq -d [device_id] -i build/meshtastic.prg
   ```

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
