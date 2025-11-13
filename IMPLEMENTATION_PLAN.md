# Meshtastic Garmin Watch - Implementation Plan

## Project Overview

A Meshtastic client application for Garmin wearables (Connect IQ SDK) that enables off-grid mesh communication directly from your wrist. This project implements the complete Meshtastic protocol stack in Monkey C, including manual Protocol Buffers handling, BLE communication, and a full-featured user interface.

**Target Hardware**: Garmin Fenix 8 Solar 51mm (and other compatible Connect IQ devices)

**Current Status**: Proof of Concept → Production Ready Application

---

## Architecture Summary

```
┌─────────────────────────────────────┐
│   Garmin Watch (Connect IQ App)     │
│  ┌──────────────────────────────┐   │
│  │   UI Layer (MeshtasticApp)   │   │
│  └──────────┬───────────────────┘   │
│             │                        │
│  ┌──────────▼───────────────────┐   │
│  │  Application Logic Layer      │   │
│  │  - Message Handler            │   │
│  │  - Node Database              │   │
│  │  - State Machine              │   │
│  └──────────┬───────────────────┘   │
│             │                        │
│  ┌──────────▼───────────────────┐   │
│  │  Protocol Layer               │   │
│  │  - BLE Manager                │   │
│  │  - Command Queue              │   │
│  │  - Protobuf Encoder/Decoder   │   │
│  └──────────┬───────────────────┘   │
└─────────────┼───────────────────────┘
              │ BLE
┌─────────────▼───────────────────────┐
│    Meshtastic Node (ESP32/nRF52)   │
│         LoRa Mesh Network           │
└─────────────────────────────────────┘
```

---

## Completed Foundation (Phase 0)

### ✅ Core Infrastructure
- [x] Manual Protocol Buffers implementation
  - Complete Varint encoding/decoding
  - Zig-Zag encoding for signed integers
  - All wire types (VARINT, FIXED32, FIXED64, LENGTH-DELIMITED)
  - Schema-driven serialization/deserialization
- [x] Meshtastic streaming protocol (4-byte header wrap/unwrap)
- [x] BLE Manager with state machine
  - 6 states: DISCONNECTED, SCANNING, CONNECTING, CONNECTED, SYNCING, READY
  - Connection lifecycle management
  - Meshtastic service/characteristic UUIDs configured
- [x] BLE Command Queue for sequential operations
- [x] Mock BLE Manager for simulator testing
- [x] Comprehensive test suite
  - Protobuf encoding/decoding tests
  - BLE state machine tests
  - Integration tests

**Lines of Code**: ~1,500 lines across 10+ files

---

## Phase 1: Core Messaging (High Priority)

**Goal**: Enable basic text messaging functionality

### 1.1 Message Schema Completion
**Estimated Effort**: 2-3 days

- [ ] Define complete ToRadio/FromRadio schemas
  - `SCHEMA_TORADIO` with `packet` and `want_config_id` fields
  - `SCHEMA_FROMRADIO` with all response types
- [ ] Define NodeInfo schema
  - User information (long_name, short_name, macaddr)
  - Position data
  - Device metrics
- [ ] Define Config message schemas
  - DeviceConfig, LoRaConfig, etc.
- [ ] Add PortNum enum constants
  - TEXT_MESSAGE_APP = 1
  - NODEINFO_APP = 4
  - POSITION_APP = 3
  - ADMIN_APP = 6

**Files**: `src/ProtoBuf.mc`

### 1.2 Connection Handshake Implementation
**Estimated Effort**: 3-4 days

- [ ] Implement connection state machine transitions
  - CONNECTED → SYNCING: Send want_config_id
  - SYNCING → READY: Receive config completion
- [ ] Build ToRadio message constructor
  - `createWantConfigRequest()`
  - `createMeshPacket()`
- [ ] Implement FromRadio parser
  - Detect message type from oneof payload
  - Route to appropriate handler
- [ ] Create initial sync processor
  - Parse MyNodeInfo
  - Parse NodeInfo stream
  - Parse Config responses
  - Store node database

**Files**: `src/BleManager.mc`, `src/MessageHandler.mc` (new)

### 1.3 Text Messaging
**Estimated Effort**: 4-5 days

- [ ] Outgoing message builder
  - Create Data message with TEXT_MESSAGE_APP portnum
  - Wrap in MeshPacket
  - Wrap in ToRadio
  - Add streaming header
  - Generate message IDs
- [ ] Incoming message parser
  - Unwrap streaming header
  - Decode FromRadio → MeshPacket → Data
  - Extract text payload
  - Display in UI
- [ ] Message storage
  - In-memory message queue (last 50 messages)
  - Sender/receiver information
  - Timestamp tracking

**Files**: `src/MessageHandler.mc`, `src/MeshtasticApp.mc`

**Deliverable**: Send and receive text messages on the mesh network

---

## Phase 2: User Interface (High Priority)

**Goal**: Professional, usable interface for message and node management

### 2.1 Multi-View Navigation
**Estimated Effort**: 3-4 days

- [ ] Implement view manager with stack navigation
- [ ] Create 5 core views:
  1. **Status View** - Connection state, node count, battery
  2. **Message List** - Scrollable message history
  3. **Message Detail** - Full message view
  4. **Node List** - Known nodes with status
  5. **Compose View** - Send message options
- [ ] Add button/touch event routing
  - UP/DOWN: Scroll
  - SELECT: Choose action
  - BACK: Return to previous view
  - START: Quick actions

**Files**: `src/views/*.mc`, `resources/layouts/*.xml`

### 2.2 Message UI Components
**Estimated Effort**: 3-4 days

- [ ] Message list view
  - Display sender name, timestamp, preview
  - Unread message indicators
  - Scroll with pagination
- [ ] Message composition
  - Pre-defined quick messages (10+ options)
  - Broadcast vs. direct message selection
  - Send confirmation
- [ ] Message detail view
  - Full message text
  - Sender information
  - Delivery status (if available)
  - Reply/forward options

**Files**: `src/views/MessageListView.mc`, `src/views/ComposeView.mc`

### 2.3 Node Management UI
**Estimated Effort**: 2-3 days

- [ ] Node list display
  - Node name, ID, distance (if position available)
  - Last heard time
  - Battery/signal indicators
  - Sort by name, distance, or last heard
- [ ] Node detail view
  - Full node information
  - Position on map (if available)
  - Device metrics
  - Message history with that node

**Files**: `src/views/NodeListView.mc`, `src/views/NodeDetailView.mc`

**Deliverable**: Complete, polished UI for all core functions

---

## Phase 3: Advanced Features (Medium Priority)

**Goal**: Feature parity with mobile clients

### 3.1 Position Sharing
**Estimated Effort**: 3-4 days

- [ ] GPS integration using Toybox.Position
- [ ] Position message builder
  - Convert GPS coordinates to Meshtastic format
  - Add altitude, speed, heading
  - Broadcast on configurable interval
- [ ] Position message parser
  - Decode incoming position updates
  - Update node database with locations
- [ ] Distance/bearing calculations
  - Show distance to other nodes
  - Show direction indicators

**Files**: `src/PositionManager.mc`, `src/MessageHandler.mc`

### 3.2 Node Database Management
**Estimated Effort**: 3-4 days

- [ ] Optimize data structures
  - Replace Dictionary with Array where possible
  - Use fixed-size node storage (max 100 nodes)
  - Implement LRU eviction for old nodes
- [ ] Node filtering and search
  - Filter by online/offline status
  - Search by name
  - Favorite nodes feature
- [ ] Persistence layer
  - Save node database to storage
  - Save message history
  - Save user preferences
  - Use Toybox.Application.Storage

**Files**: `src/NodeDatabase.mc`, `src/Storage.mc` (new)

### 3.3 Configuration Management
**Estimated Effort**: 4-5 days

- [ ] Build AdminMessage support
  - get_config_request builder
  - set_config builder
  - Config response parser
- [ ] Configuration UI
  - View current LoRa settings
  - Change channel settings
  - Modify device settings
  - Reboot node command
- [ ] Channel management
  - Switch between channels
  - View channel key/settings

**Files**: `src/ConfigManager.mc`, `src/views/ConfigView.mc`

**Deliverable**: Full-featured Meshtastic client with configuration support

---

## Phase 4: Optimization & Polish (Medium Priority)

**Goal**: Production-quality reliability and performance

### 4.1 Memory Optimization
**Estimated Effort**: 2-3 days

- [ ] Profile memory usage in simulator
- [ ] Optimize protobuf operations
  - Reuse ByteArray buffers
  - Minimize object creation in hot paths
- [ ] Implement data pruning
  - Automatic message cleanup (> 50 messages)
  - Node eviction (> 100 nodes)
  - Clear old position data
- [ ] Add memory monitoring
  - Display available memory in debug mode
  - Log memory warnings

**Files**: All source files

### 4.2 Performance Optimization
**Estimated Effort**: 2-3 days

- [ ] Watchdog timer handling
  - Chunk large parsing operations
  - Add yield points in loops
  - Background processing for sync
- [ ] BLE optimization
  - Optimize notification handling
  - Reduce unnecessary reads
  - Implement smart polling
- [ ] UI responsiveness
  - Lazy loading for long lists
  - Smooth scrolling
  - Fast view transitions

**Files**: `src/BleManager.mc`, `src/views/*.mc`

### 4.3 Error Handling & Recovery
**Estimated Effort**: 2-3 days

- [ ] Comprehensive error handling
  - BLE disconnection recovery
  - Malformed packet handling
  - Timeout management
- [ ] User feedback
  - Error messages in UI
  - Connection retry logic
  - Status notifications
- [ ] Logging system
  - Configurable log levels
  - Error history view
  - Debug export feature

**Files**: All source files, `src/ErrorHandler.mc` (new)

### 4.4 Battery Optimization
**Estimated Effort**: 2-3 days

- [ ] Connection management
  - Configurable connection timeout
  - Auto-disconnect on idle
  - Background connection option
- [ ] Smart sync
  - Reduce sync frequency
  - On-demand node updates
  - Efficient notification handling
- [ ] Battery monitoring
  - Display battery impact estimate
  - Low-power mode option

**Files**: `src/BleManager.mc`, `src/PowerManager.mc` (new)

**Deliverable**: Optimized, production-ready application

---

## Phase 5: Hardware Testing & Refinement (High Priority)

**Goal**: Validate on real hardware with real Meshtastic nodes

### 5.1 Hardware Integration Testing
**Estimated Effort**: 5-7 days

- [ ] Test on Fenix 8 Solar 51mm
  - Full connection lifecycle
  - Message send/receive
  - Multi-hour stress test
- [ ] Test with multiple Meshtastic nodes
  - ESP32 devices
  - nRF52 devices
  - Different firmware versions
- [ ] Real-world mesh testing
  - Multi-hop messages
  - Range testing
  - Interference handling

**Requirements**:
- Garmin Fenix 8 (or equivalent)
- 2+ Meshtastic nodes
- Outdoor testing environment

### 5.2 Bug Fixes & Edge Cases
**Estimated Effort**: 3-5 days

- [ ] Fix hardware-specific issues
- [ ] Handle protocol edge cases
  - Packet reordering
  - Duplicate messages
  - Partial sync states
- [ ] UI refinements based on real use
- [ ] Performance tuning for actual hardware

### 5.3 Field Testing
**Estimated Effort**: Ongoing

- [ ] Multi-day usage test
- [ ] Battery life measurement
- [ ] Range testing
- [ ] User acceptance testing
- [ ] Iteration based on feedback

**Deliverable**: Validated, field-tested application

---

## Phase 6: Advanced Features (Low Priority)

**Goal**: Feature differentiation and advanced use cases

### 6.1 Message Features
**Estimated Effort**: 3-4 days

- [ ] Message acknowledgments
  - Track ACK status
  - Retry failed messages
  - Delivery confirmation UI
- [ ] Group messaging
  - Channel-based groups
  - Broadcast vs. group messages
- [ ] Message prioritization
  - Emergency messages
  - Priority levels
  - Queue management

### 6.2 Mapping Integration
**Estimated Effort**: 4-5 days

- [ ] Map view for node positions (if device supports maps)
- [ ] Breadcrumb trail of own position
- [ ] Waypoint creation from messages
- [ ] Distance/bearing overlays

### 6.3 Telemetry & Metrics
**Estimated Effort**: 2-3 days

- [ ] Display device telemetry
  - Battery levels
  - Signal strength (SNR)
  - Air utilization
- [ ] Network metrics
  - Mesh topology view
  - Hop count visualization
  - Message statistics

### 6.4 Code Generation Tool
**Estimated Effort**: 5-7 days

- [ ] Python script to parse .proto files
- [ ] Generate Monkey C schema definitions
- [ ] Generate encoder/decoder helpers
- [ ] Automated update workflow
- [ ] Version tracking

**Files**: `tools/protoc-monkeyc/` (new)

**Deliverable**: Advanced features for power users

---

## Testing Strategy

### Unit Tests
- Protobuf encoder/decoder validation
- BLE state machine transitions
- Message parsing/building
- Node database operations

**Tool**: `tests/ComprehensiveTest.mc`

### Integration Tests
- End-to-end message flow
- Connection lifecycle
- Multi-message sequences
- Error recovery scenarios

**Tool**: `tests/InteractiveHardwareTest.mc`

### Hardware Tests
- Real device connection
- Message send/receive
- Range and reliability
- Battery consumption
- Multi-hour stability

**Devices**: Fenix 8 + Meshtastic nodes

---

## Development Workflow

### Local Development
1. Edit source in VS Code with Connect IQ extension
2. Run in simulator: `monkey.jungle` build target
3. Run unit tests: `comprehensive-test.jungle`
4. Commit changes to feature branch

### Hardware Testing
1. Build for device: Select `fenix8-51` product
2. Deploy via WiFi or USB to watch
3. Test with real Meshtastic nodes
4. Document findings

### Release Process
1. Update version in `manifest.xml`
2. Create git tag
3. Build release binary
4. Test on multiple devices
5. Submit to Connect IQ Store (if public)

---

## Technical Specifications

### Language & Platform
- **Language**: Monkey C (Garmin Connect IQ 7.3.1+)
- **API Level**: 7.3.1
- **Build System**: `.jungle` files

### Key Dependencies
- `Toybox.BluetoothLowEnergy` - BLE communication
- `Toybox.Lang` - Core language features
- `Toybox.System` - System utilities
- `Toybox.Position` - GPS integration

### Memory Targets
- **Maximum memory usage**: < 512 KB
- **Node database**: Max 100 nodes
- **Message history**: Max 50 messages
- **Persistent storage**: < 100 KB

### Performance Targets
- **Connection time**: < 10 seconds
- **Message send latency**: < 2 seconds
- **UI responsiveness**: < 100ms for interactions
- **Battery impact**: < 20% per 8 hours of active use

---

## Known Limitations & Challenges

### Protocol Limitations
1. **Manual Protobuf implementation**: No code generation, manual schema updates required
2. **Protocol evolution**: Meshtastic updates require manual app updates
3. **Limited schema support**: Only core message types implemented

### Platform Limitations
1. **Memory constraints**: Limited to ~512KB for data
2. **CPU constraints**: Watchdog timer limits processing time
3. **BLE constraints**: Sequential operations only, no command queuing in SDK
4. **No native Protobuf support**: All serialization is manual

### UX Limitations
1. **Text input**: Limited to pre-defined messages or very basic input
2. **Screen size**: Small display limits information density
3. **Battery**: BLE communication is power-intensive

### Mitigation Strategies
- Implement robust error handling
- Use memory-efficient data structures
- Chunk long-running operations
- Provide clear user feedback
- Optimize BLE communication patterns

---

## Success Criteria

### Minimum Viable Product (MVP)
- ✅ Connect to Meshtastic node via BLE
- ✅ Complete connection handshake
- ⏳ Send text messages to mesh
- ⏳ Receive and display incoming messages
- ⏳ View list of known nodes
- ⏳ Basic status display

### Version 1.0 Release
- All MVP features
- Position sharing
- Node database management
- Configuration viewing
- Optimized performance
- Comprehensive error handling
- Field tested on real hardware

### Future Enhancements
- Configuration editing
- Advanced mapping features
- Telemetry display
- Code generation tool
- Multi-device support

---

## Timeline Estimate

**Total Development Time**: 12-16 weeks (full-time equivalent)

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 0 (Complete) | 4 weeks | None |
| Phase 1: Core Messaging | 2 weeks | Phase 0 |
| Phase 2: User Interface | 2 weeks | Phase 1 |
| Phase 3: Advanced Features | 3 weeks | Phase 2 |
| Phase 4: Optimization | 2 weeks | Phase 3 |
| Phase 5: Hardware Testing | 2 weeks | Phase 4 |
| Phase 6: Advanced (Optional) | 3 weeks | Phase 5 |

**Note**: Timeline assumes experienced Monkey C developer working full-time

---

## Resources & References

### Documentation
- [Meshtastic Protocol Docs](https://meshtastic.org/docs/development/device/client-api/)
- [Connect IQ SDK](https://developer.garmin.com/connect-iq/)
- [Protobuf Wire Format](https://protobuf.dev/programming-guides/encoding/)
- [Meshtastic Protobufs](https://github.com/meshtastic/protobufs)

### Development Tools
- Visual Studio Code with Connect IQ extension
- Connect IQ SDK Manager
- Garmin Express (for device connection)
- Simulator (included in SDK)

### Hardware
- Garmin Fenix 8 Solar 51mm (primary target)
- Meshtastic ESP32/nRF52 nodes (for testing)
- USB cable for device deployment

---

## Contributors & Acknowledgments

This implementation builds upon the comprehensive technical analysis and research documented in the project's foundational documents, including deep dives into Protocol Buffers wire format, Meshtastic protocol specifications, and Garmin Connect IQ platform constraints.

**Key Technologies**:
- Meshtastic Protocol (Open Source)
- Google Protocol Buffers
- Garmin Connect IQ SDK
- Bluetooth Low Energy (BLE)

---

## Conclusion

This implementation plan provides a clear, phased roadmap from the current proof-of-concept to a production-ready Meshtastic client for Garmin wearables. The foundation is solid, with core protocol handling complete. The remaining work focuses on application logic, user interface, optimization, and real-world validation.

**Current Status**: Phase 0 Complete (Foundation) → Phase 1 In Progress (Core Messaging)

**Next Steps**:
1. Complete message schema definitions
2. Implement connection handshake
3. Build text messaging functionality
4. Begin UI development

This is an ambitious but achievable project that will bring the power of Meshtastic mesh networking directly to the wrist of Garmin users worldwide.
