# Meshtastic Garmin Client Implementation Plan

## Overview
Implementation of a Meshtastic client application for Garmin wearables using Connect IQ SDK. This is a technically challenging project requiring manual Protobuf implementation in Monkey C.

## Completed Tasks

### Development Environment & Protobuf Implementation ✅
- [x] Set up Garmin Connect IQ development environment
- [x] Created base project structure with manifest and resources
- [x] Implemented complete Protobuf encoder with all wire types
- [x] Implemented complete Protobuf decoder with schema support
- [x] Created Meshtastic streaming protocol (wrap/unwrap with 4-byte header)
- [x] Defined Meshtastic message schemas (Data, MeshPacket, Position)
- [x] Built working test suite demonstrating protobuf functionality

## Phase 1: Foundation (High Priority)

### 1. Core BLE Manager Implementation
- [ ] Create BleManager class with singleton pattern
- [ ] Implement BLE profile registration with Meshtastic UUIDs
- [ ] Add BleDelegate for handling callbacks
- [ ] Implement device scanning functionality
- [ ] Add connection management methods

### 2. ToRadio/FromRadio Message Implementation
- [ ] Create ToRadio/FromRadio message schemas
- [ ] Implement want_config_id request builder
- [ ] Build ToRadio envelope serializer
- [ ] Implement config message parser (FromRadio)
- [ ] Create NodeInfo deserializer
- [ ] Add message type detection logic

### 3. BLE Command Queue
- [ ] Create command queue data structure
- [ ] Implement queue management (add, remove, process)
- [ ] Add command completion tracking
- [ ] Ensure sequential BLE operations
- [ ] Handle timeout and retry logic

### 4. Connection Lifecycle State Machine
- [ ] Define connection states enum
- [ ] Implement state transition logic
- [ ] Add handshake sequence handler
- [ ] Create initial sync processor
- [ ] Handle disconnection and reconnection

## Phase 2: Core Functionality (Medium Priority)

### 5. Text Messaging System
- [ ] Create Data message builder with PortNum
- [ ] Implement text payload encoding
- [ ] Build complete MeshPacket for sending
- [ ] Parse incoming text messages
- [ ] Add message ID generation

### 6. User Interface Development
- [ ] Design connection status view
- [ ] Create message list view with scrolling
- [ ] Build node list display
- [ ] Implement message composition screen
- [ ] Add navigation between views

### 7. Memory Optimization
- [ ] Replace dictionaries with arrays where possible
- [ ] Implement node database with fixed-size structures
- [ ] Add memory usage monitoring
- [ ] Create data pruning strategies
- [ ] Optimize string storage

### 8. Watchdog Timer Handling
- [ ] Identify long-running operations
- [ ] Implement operation chunking
- [ ] Add yield points in parsing loops
- [ ] Create progress indicators
- [ ] Test with large node databases

### 9. Testing Suite
- [ ] Create BLE mock for unit testing
- [ ] Build message serialization tests
- [ ] Add deserialization validation tests
- [ ] Implement integration test scenarios
- [ ] Document device testing procedures

## Phase 3: Advanced Features (Low Priority)

### 10. Admin Message Support
- [ ] Implement get_config_request builder
- [ ] Create set_config message serializer
- [ ] Add config response parser
- [ ] Build UI for configuration options
- [ ] Test with various config types

### 11. Code Generation Tool
- [ ] Create Python script to parse .proto files
- [ ] Build Monkey C code generator
- [ ] Generate serialization functions
- [ ] Generate deserialization functions
- [ ] Add update detection and versioning

## Technical Considerations

### Key Challenges
- No native Protobuf support in Monkey C
- Manual binary manipulation required
- Strict memory and CPU constraints
- BLE API doesn't queue commands
- Maintenance burden with protocol changes

### Required Skills
- Expert knowledge of Garmin Connect IQ
- Strong understanding of binary protocols
- Experience with bitwise operations
- BLE communication patterns
- Low-level data serialization

### Resource Limits
- Memory: ~32KB-64KB available for app
- CPU: Watchdog timer ~10 seconds
- Storage: Limited persistent storage
- Battery: BLE communication impact

## References
- [Meshtastic Protocol Docs](https://meshtastic.org/docs/development/device/client-api/)
- [Connect IQ SDK](https://developer.garmin.com/connect-iq/)
- [Protobuf Wire Format](https://developers.google.com/protocol-buffers/docs/encoding)