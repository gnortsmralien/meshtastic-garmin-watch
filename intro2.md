
Feasibility Analysis and Implementation Guide for a Meshtastic Client on Garmin Wearables


Executive Summary

This report provides a comprehensive technical analysis of the feasibility of implementing a Meshtastic client application on latest-generation Garmin smartwatches. The investigation concludes that such an implementation is technically feasible but represents a significant software engineering challenge. It is not a straightforward integration and requires advanced development skills.
The primary obstacle is the architectural mismatch between Meshtastic's communication protocol and the Garmin Connect IQ (CIQ) development environment. Meshtastic's Bluetooth Low Energy (BLE) Application Programming Interface (API) relies exclusively on Google's Protocol Buffers (Protobufs) for data serialization.1 The Garmin CIQ platform and its native Monkey C programming language lack any built-in or third-party library for handling Protobufs. This necessitates that the developer manually implement a custom, low-level Protobuf parser and serializer directly in Monkey C.
This central challenge is mitigated by several key enablers:
Sufficient Hardware Capability: The latest Garmin watch models, such as the Fenix 8 and Forerunner 970 series, possess powerful processors, ample memory (16 GB to 32 GB), and modern BLE chipsets. These resources are more than adequate to handle the computational load of real-time data serialization and communication, meaning hardware is not a limiting factor.4
Capable Garmin BLE API: The Toybox.BluetoothLowEnergy module within the CIQ SDK provides the necessary functionality for a watch application to operate as a BLE central device, which is the required role for communicating with a Meshtastic node.6
Well-Defined Meshtastic Protocol: The Meshtastic project provides stable and publicly accessible documentation for its BLE protocol and Protobuf message definitions, offering a clear and well-defined target for implementation.7
The implementation path involves creating a CIQ "Device App" or "Widget" that utilizes the BLE API to establish a connection with a Meshtastic node.9 The core of the application's logic will be dedicated to constructing and deconstructing binary Protobuf messages byte-by-byte, using Monkey C's
ByteArray class and bitwise operators.10
This project is recommended for experienced developers who are comfortable with low-level binary data manipulation, bitwise logic, and network protocol implementation. The development effort is substantial, and the resulting application will be inherently brittle, requiring manual updates to its parser and serializer whenever Meshtastic's underlying Protobuf schemas evolve.

Architectural Analysis: Interfacing Meshtastic and Garmin Connect IQ


The Meshtastic Ecosystem: A Primer

The Meshtastic project facilitates off-grid communication using inexpensive, low-power LoRa radio hardware, typically based on ESP32 or nRF52 microcontrollers.12 These devices, referred to as "nodes," automatically form a decentralized, self-healing mesh network. This topology allows data packets to be relayed from node to node, extending communication range far beyond that of a single point-to-point link.14
A "Client" in the Meshtastic ecosystem is a user-facing application, such as those available for Android, iOS, or via a Python command-line interface (CLI).15 A client connects to a single Meshtastic node, typically via BLE, Serial, or TCP/IP, and uses that node as its gateway to the entire mesh network. A message originating from a client is first transmitted to its paired node, which then broadcasts the message over the LoRa mesh. Conversely, any LoRa message received by the node from the mesh is forwarded to its connected client.7 The Garmin watch application detailed in this report would function as such a client.

The Garmin Connect IQ Ecosystem

Connect IQ is the proprietary application platform for Garmin's extensive line of wearable devices.9 It allows third-party developers to create and distribute applications through the Connect IQ Store. For a project of this nature, the most suitable application types are a "Device App" or a "Widget." Both types provide access to the full capabilities of the BLE API and can run as interactive, foreground processes, which is necessary for managing a persistent connection and user interaction.9
Development for the platform is done in Monkey C, an object-oriented language that shares syntax with Java, JavaScript, and Python. However, Monkey C is designed for resource-constrained environments and has significant limitations compared to general-purpose languages. It lacks extensive standard libraries, has no native package management system for third-party code, and imposes strict memory and execution time limits on applications.16 These constraints are a defining factor in the implementation strategy.

Proposed System Architecture

The proposed system architecture establishes a clear communication pathway where the Garmin watch acts as a user interface and control terminal for a Meshtastic node. The end-to-end data flow is as follows:
Garmin Watch (CIQ App) <--> BLE <--> Meshtastic Node <--> LoRa Mesh <--> Other Meshtastic Nodes
In this architecture, the roles of each device are strictly defined by their respective platform capabilities:
Garmin Watch (BLE Central): The Connect IQ application will operate exclusively in the BLE Central role. It will initiate the connection, scan for peripherals, and manage the communication link. This is a fundamental constraint of the Toybox.BluetoothLowEnergy API, which only supports the central role.6
Meshtastic Node (BLE Peripheral): The Meshtastic node hardware will operate in the BLE Peripheral role. It will advertise its presence and wait for a central device (the watch) to connect to it.
This architecture aligns perfectly with the intended design of both ecosystems. Meshtastic is explicitly built to be extended and controlled by external client applications via its client API.7 The Garmin CIQ platform is designed to allow its wearables to interface with a wide range of external BLE sensors and devices.6 There are no fundamental architectural mismatches; the challenge lies not in whether the devices
can connect, but in how they must format the data they exchange.

The Meshtastic BLE Client Protocol: A Deep Dive

A successful implementation requires a thorough understanding of the specific BLE protocol used by Meshtastic nodes. This is not a standard GATT profile but a custom, streaming protocol built on top of basic BLE services.

GATT Service and Characteristic Profile

All Meshtastic client communication over BLE occurs through a single, custom GATT service. The client application must register this profile, including its specific characteristics, to interact with the node.
Table 1: Meshtastic BLE GATT Profile

Element
UUID
Function
Service
6ba1b218-15a8-461f-9fa8-5dcae273eafd
MeshBluetoothService: The primary service for all client API communication.7
Characteristic
f75c76d2-82c7-455b-9721-6b7538f49493
ToRadio: Write-only. Used to send serialized Protobuf data to the Meshtastic node.7
Characteristic
26432193-4482-4648-b425-4c07c409e0e5
FromRadio: Read/Notify. Used to receive serialized Protobuf data from the Meshtastic node.7
Characteristic
18cd4359-5506-4560-8d81-1b038a838e00
FromNum: Notify-only. The node sends a notification on this characteristic containing a counter to indicate that new data is available to be read from the FromRadio characteristic.7


The Meshtastic Streaming Protocol

Meshtastic does not simply send raw Protobuf messages over its BLE characteristics. It uses a streaming protocol where each Protobuf packet is prefixed with a custom 4-byte header. This header provides framing, allowing the receiver to identify the start of a packet and determine its length.7 The Garmin application must prepend this header to all outgoing data and parse it from all incoming data streams.
The 4-byte header is structured as follows:
Byte 0: START1 (constant 0x94)
Byte 1: START2 (constant 0xc3)
Byte 2: Most Significant Byte (MSB) of the Protobuf payload length
Byte 3: Least Significant Byte (LSB) of the Protobuf payload length

Core Data Structures: ToRadio and FromRadio

The data exchanged over the ToRadio and FromRadio characteristics are themselves top-level Protobuf messages that act as envelopes for all other message types.
ToRadio: This message is sent from the client (watch) to the node. It contains a oneof payload field, which can be a request to the node (like want_config_id) or a MeshPacket destined for the LoRa mesh.7
FromRadio: This message is sent from the node to the client. Its oneof payload can contain various types of information, such as node metadata (MyNodeInfo, NodeInfo), configuration data (RadioConfig, User), or a MeshPacket that has been received from the LoRa mesh and is being forwarded to the client.7

Connection Lifecycle and Data Synchronization

The Meshtastic BLE protocol is stateful and requires a specific handshake sequence upon connection. A client cannot simply connect and begin sending messages. It must first perform a data synchronization sequence to download the node's current state, including its configuration and the database of other known nodes in the mesh.
The required connection lifecycle is as follows 7:
The Garmin app connects to the Meshtastic node via BLE.
The app enables notifications on the FromNum and FromRadio characteristics. This is essential for receiving data asynchronously.
The app constructs and sends a ToRadio Protobuf message. The payload of this message is a want_config_id request. This signals to the node that a new client is ready to receive the initial state dump.
The node responds by sending a stream of FromRadio packets. This stream contains the node's radio configuration, its user information, its own node information, and the NodeInfo for every other node it currently knows about in the mesh.
After sending the complete state, the node sends a final FromRadio packet containing a want_config_id response. This signals to the client that the initial synchronization is complete.
At this point, the connection is fully established, and the client is free to send and receive real-time MeshPacket messages.
This mandatory handshake sequence demonstrates that the protocol is more complex than a simple request-response API. The Garmin application logic must be built as a state machine that correctly follows this sequence to be recognized as a valid, fully-functional client by the Meshtastic node.

Garmin Connect IQ for BLE Communication

The Garmin CIQ SDK provides the necessary tools to implement the client side of the Meshtastic BLE protocol. The entire interaction is managed through the Toybox.BluetoothLowEnergy module.

The Toybox.BluetoothLowEnergy Module

This module is the sole entry point for direct, low-level BLE communication within a CIQ application.6 It grants the application the ability to act as a BLE central, which involves scanning for, connecting to, and communicating with peripheral devices.

Implementing the BLE Central Role

The process of connecting to a Meshtastic node from a Garmin watch involves several distinct steps:
Scanning: The application initiates a BLE scan by calling BluetoothLowEnergy.setScanState(SCAN_STATE_SCANNING). As devices are discovered, the onScanResults callback in the application's delegate is triggered. The code must iterate through these results and identify the Meshtastic node, typically by its advertised name (e.g., "Meshtastic_1234") or by matching the advertised service UUID.6
Profile Registration: Before attempting to connect, the application must inform the CIQ system of the specific GATT profile it intends to use. This is a critical step performed by calling BluetoothLowEnergy.registerProfile() and providing a dictionary containing the UUIDs for the MeshBluetoothService and its associated characteristics (ToRadio, FromRadio, FromNum).6 Failure to register the profile will prevent any subsequent interaction with the service.
Pairing and Connecting: Once a target device is identified from the scan results, the application calls BluetoothLowEnergy.pairDevice(). The CIQ BLE subsystem then handles the connection process. The application is notified of the connection status (connected, disconnected) via the onConnectedStateChanged callback in its delegate.6

Managing Asynchronous Data Flow with BleDelegate

All BLE operations in Connect IQ are asynchronous and event-driven. An application does not block and wait for an operation to complete. Instead, it registers a BleDelegate class, which contains a series of callback methods that the system invokes when events occur.20 The key callbacks for this project are:
onScanResults(): Receives advertising data from nearby peripherals.
onConnectedStateChanged(): Notifies the app of connection or disconnection events.
onCharacteristicWrite(): Confirms that a write request has completed.
onCharacteristicChanged(): Delivers new data received via a notification. This is the primary mechanism for receiving data from the FromRadio characteristic.
onCharacteristicRead(): Delivers data from an explicit read request.
A significant detail noted by experienced CIQ developers is that the BLE API does not automatically queue requests. If an application sends a new request (e.g., a second requestWrite()) before the callback for the previous request (e.g., onCharacteristicWrite()) has been received, the new request may be dropped or cause an error. Therefore, a robust application must implement its own simple command queue to serialize BLE operations, ensuring that a new command is only sent after the previous one has been acknowledged by the system.21 This requirement, combined with the stateful nature of the Meshtastic handshake, reinforces the need for a well-structured state machine within the Garmin app's architecture.

Strategies for Writing and Reading Characteristics

Writing Data: To send data to the Meshtastic node, the application will serialize a Protobuf message into a Lang.ByteArray, prepend the 4-byte stream header, and pass this final byte array to the ToRadio characteristic's requestWrite() method.21
Receiving Data: Incoming data from the node will arrive asynchronously via the onCharacteristicChanged callback. This callback provides the raw data as a Lang.ByteArray.20 This byte array must then be passed to the custom Protobuf deserializer for parsing.

Bridging the Protocol Gap: Handling Protobufs in Monkey C

This section addresses the most significant technical hurdle of the project: the implementation of Protobuf message handling in a language environment that offers no native support.

The Core Challenge: The "Protobuf Wall"

As established, Meshtastic's protocol is built entirely on Protobufs 1, while the Monkey C language provides no tools to work with them directly. The developer is therefore forced to bridge this gap by manually implementing the logic to encode and decode Protobuf messages according to the official Protobuf wire format specification. This task is deterministic but requires meticulous, error-prone, low-level programming.

Monkey C's Toolkit for Binary Manipulation

While lacking a Protobuf library, Monkey C does provide the fundamental tools necessary for this task:
Lang.ByteArray: This is the primary object for holding and building sequences of bytes. Methods like add(), slice(), size(), and indexing (``) are the building blocks for constructing and parsing packets.11
Lang.ByteArray.encodeNumber() and decodeNumber(): These methods are invaluable for converting between sequences of bytes and Monkey C's native Number or Long types. They correctly handle endianness and can parse fixed-size numbers (e.g., sfixed32), simplifying parts of the process.11
Bitwise Operators: The language supports a full suite of bitwise operators (& for AND, | for OR, ^ for XOR, << for left shift, >> for right shift).10 These are absolutely essential for implementing the Protobuf wire format, particularly for encoding and decoding variable-length integers (varints) and parsing field tags.

Strategy for Manual Deserialization (Incoming Data)

A function to parse an incoming FromRadio payload would follow these general steps:
Verify and strip the 4-byte stream header to get the payload length and the raw Protobuf ByteArray.
Implement a loop to process the ByteArray as a stream. In each iteration, the loop reads a "tag." A tag is a varint that contains two pieces of information: the field number (e.g., field 1, 2, 3) and the wire type (e.g., varint, 64-bit, length-delimited, 32-bit).
The tag is decoded using bitwise operations: the wire type is the lower 3 bits (tag & 0x07), and the field number is the upper bits (tag >> 3).
A switch statement on the field number determines which data field is being processed.
Based on the wire type, a specific helper function is called to read the value. For example, a readVarint() function would read bytes until the most significant bit is 0, reassembling the integer. A readLengthDelimited() function would first read a varint to determine the length of the upcoming data (e.g., a string or nested message), then read that many bytes.
The parsed value is stored in a Monkey C Dictionary or a custom class instance, keyed by the field name.
This process is applied recursively for nested messages.

Strategy for Manual Serialization (Outgoing Data)

A function to serialize an outgoing ToRadio payload would reverse the process:
Start with an empty ByteArray.
Iterate through the fields of a Dictionary or class representing the message to be sent.
For each field, write the corresponding tag to the ByteArray. The tag is constructed by bit-shifting the field number left by 3 and OR-ing it with the correct wire type ((field_number << 3) | wire_type).
Call a helper function to encode the field's value. For a string or bytes field, this involves first writing the length of the data as a varint, followed by the data bytes themselves.
After all fields are written, calculate the total length of the serialized ByteArray.
Construct the 4-byte stream header using this length and prepend it to the payload.
The final ByteArray is now ready to be written to the ToRadio characteristic.

Reference Implementations for Key Messages

To facilitate this manual coding, the following reference tables distill the complex .proto files into a direct "cheat sheet" for the developer.
Table 2: Key Meshtastic Protobuf Message Structures (Simplified)
Message
Field Name
Field Number
Protobuf Type
Wire Type
Monkey C Representation
Data
portnum
1
PortNum (enum)
Varint
Lang.Number


payload
2
bytes
Length-delimited
Lang.ByteArray


want_response
3
bool
Varint
Lang.Boolean


text
8
string
Length-delimited
Lang.String
MeshPacket
from
1
uint32
Varint
Lang.Number


to
2
uint32
Varint
Lang.Number


channel
3
uint32
Varint
Lang.Number


decoded
4
Data (message)
Length-delimited
Lang.Dictionary or class


id
5
uint32
Varint
Lang.Number
AdminMessage
get_config_request
5
ConfigType
Varint
Lang.Number


get_config_response
6
Config (message)
Length-delimited
Lang.Dictionary or class


set_config
34
Config (message)
Length-delimited
Lang.Dictionary or class

Table 3: Protobuf-to-Monkey C Type Mapping
Protobuf Type
Wire Format
Monkey C Type
Notes
int32, uint32, bool, enum
Varint
Lang.Number
Use custom varint encoder/decoder.
sfixed32
32-bit
Lang.Number
Use decodeNumber with FORMAT_INT32.
string
Length-delimited
Lang.String
Convert to/from ByteArray using UTF-8. StringUtil may assist.
bytes
Length-delimited
Lang.ByteArray
Direct mapping.
message
Length-delimited
Lang.Dictionary or class
Represents a nested object. Requires recursive serialization/deserialization.


Implementation Guide and Sample Code

This section provides illustrative, commented Monkey C code snippets to serve as a blueprint for development. This is not a complete, copy-paste solution but a functional guide to the core components.

Project Setup

First, a new Connect IQ project should be created using the Visual Studio Code extension, selecting "Device App" as the project type. The manifest.xml file must be updated to include the necessary BLE permissions:

XML


<iq:permissions>
    <iq:uses-permission id="BluetoothLowEnergy"/>
</iq:permissions>



Core BLE Manager Class

A central class, BleManager, should be created to encapsulate all BLE logic, including state management, the command queue, and the delegate.

Code snippet


// BleManager.mc
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Lang;
using Toybox.System;

class BleManager {
    private var _delegate;
    private var _profileRegistered = false;
    private var _meshtasticService = null;
    private var _toRadioChar = null;
    private var _fromRadioChar = null;

    // UUIDs from Table 1
    private const MESH_SERVICE_UUID = Ble.stringToUuid("6ba1b218-15a8-461f-9fa8-5dcae273eafd");
    private const TO_RADIO_UUID = Ble.stringToUuid("f75c76d2-82c7-455b-9721-6b7538f49493");
    private const FROM_RADIO_UUID = Ble.stringToUuid("26432193-4482-4648-b425-4c07c409e0e5");
    private const FROM_NUM_UUID = Ble.stringToUuid("18cd4359-5506-4560-8d81-1b038a838e00");

    function initialize() {
        _delegate = new MyBleDelegate();
        Ble.setDelegate(_delegate);
        registerProfile();
    }

    function registerProfile() {
        if (_profileRegistered) { return; }
        var profile = {
            :uuid => MESH_SERVICE_UUID,
            :characteristics => },
                { :uuid => FROM_RADIO_UUID, :descriptors => },
                { :uuid => FROM_NUM_UUID, :descriptors => }
            ]
        };
        Ble.registerProfile(profile);
        _profileRegistered = true; // Assume success for simplicity
    }

    function startScan() {
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
    }
    
    //... other methods for connecting, sending data, etc.
}

class MyBleDelegate extends Ble.BleDelegate {
    function initialize() {
        BleDelegate.initialize();
    }

    function onScanResults(scanResults) {
        // Iterate through scanResults and find a Meshtastic device
        // Then call Ble.pairDevice(result)
    }

    function onConnectedStateChanged(device, state) {
        if (state == Ble.CONNECTION_STATE_CONNECTED) {
            System.println("Connected to device!");
            // Begin handshake sequence here
        } else if (state == Ble.CONNECTION_STATE_DISCONNECTED) {
            System.println("Disconnected.");
        }
    }
    
    function onCharacteristicChanged(char, value) {
        // This is where incoming data from FromRadio arrives
        // Pass 'value' (a ByteArray) to the Protobuf parser
        System.println("Received data: " + value);
        // Example: var parsedData = ProtobufParser.parseFromRadio(value);
    }

    //... other delegate callbacks (onCharacteristicWrite, etc.)
}



Part A: Establishing and Managing the Connection

After a connection is established in onConnectedStateChanged, the handshake must begin. This involves enabling notifications and then sending the want_config_id request.

Code snippet


// Inside MyBleDelegate.onConnectedStateChanged, when connected:
var service = device.getService(MESH_SERVICE_UUID);
var fromRadio = service.getCharacteristic(FROM_RADIO_UUID);
var fromNum = service.getCharacteristic(FROM_NUM_UUID);

// Enable notifications - this requires writing to the CCCD
var cccd = fromRadio.getDescriptor(Ble.cccdUuid());
cccd.requestWrite([0x01, 0x00]b); // This should be queued

// After notification is enabled, send the config request
// This function would be in a separate ProtobufSerializer class
var configRequestPacket = ProtobufSerializer.createWantConfigPacket();
var toRadio = service.getCharacteristic(TO_RADIO_UUID);
toRadio.requestWrite(configRequestPacket, {});



Part B: Implementing Messaging

To send a text message, the application must construct a series of nested Protobuf messages and serialize them.

Code snippet


// ProtobufSerializer.mc
class ProtobufSerializer {
    // A simplified serializer for a text message
    static function createTextMessagePacket(text as String, destinationNodeNum as Number) as ByteArray {
        // 1. Create the 'Data' message payload
        var dataPayload = new ByteArray(0);
        // Tag for PortNum (field 1, varint)
        dataPayload.addAll(writeVarint( (1 << 3) | 0 )); 
        dataPayload.addAll(writeVarint(1)); // PortNum.TEXT_MESSAGE_APP = 1
        // Tag for payload text (field 8, length-delimited)
        var textBytes = text.toUtf8Array();
        dataPayload.addAll(writeVarint( (8 << 3) | 2 ));
        dataPayload.addAll(writeVarint(textBytes.size()));
        dataPayload.addAll(textBytes);

        // 2. Wrap in 'MeshPacket'
        var meshPacketPayload = new ByteArray(0);
        // Tag for destination (field 2, varint)
        meshPacketPayload.addAll(writeVarint( (2 << 3) | 0 ));
        meshPacketPayload.addAll(writeVarint(destinationNodeNum));
        // Tag for decoded Data message (field 4, length-delimited)
        meshPacketPayload.addAll(writeVarint( (4 << 3) | 2 ));
        meshPacketPayload.addAll(writeVarint(dataPayload.size()));
        meshPacketPayload.addAll(dataPayload);
        //... add other required MeshPacket fields like 'from', 'id'

        // 3. Wrap in 'ToRadio'
        var toRadioPayload = new ByteArray(0);
        // Tag for packet (field 1, length-delimited)
        toRadioPayload.addAll(writeVarint( (1 << 3) | 2 ));
        toRadioPayload.addAll(writeVarint(meshPacketPayload.size()));
        toRadioPayload.addAll(meshPacketPayload);

        // 4. Prepend the 4-byte stream header
        return createStreamPacket(toRadioPayload);
    }
    
    // Helper to write a varint (simplified)
    static function writeVarint(value as Number) as ByteArray {
        //... implementation of varint encoding...
        return new ByteArray(0); // Placeholder
    }

    // Helper to create the final stream packet
    static function createStreamPacket(payload as ByteArray) as ByteArray {
        var header = new ByteArray(4);
        header = 0x94;
        header = 0xc3;
        var len = payload.size();
        header = (len >> 8) & 0xFF;
        header = len & 0xFF;
        return header.addAll(payload);
    }
}


Parsing an incoming message would involve a ProtobufParser class that performs the reverse of this logic, using bitwise operations to read tags and helper functions to decode varints and length-delimited fields.

Part C: Implementing Simple Administration

Requesting the node's configuration follows the same serialization pattern, but with an AdminMessage as the payload.

Code snippet


// ProtobufSerializer.mc (continued)
class ProtobufSerializer {
    // A simplified serializer for a config request
    static function createGetConfigRequestPacket() as ByteArray {
        // 1. Create AdminMessage payload
        var adminPayload = new ByteArray(0);
        // Tag for get_config_request (field 5, varint)
        adminPayload.addAll(writeVarint( (5 << 3) | 0 ));
        adminPayload.addAll(writeVarint(1)); // Config.DeviceConfig = 1

        // 2. Wrap in MeshPacket (sent to local node)
        var meshPacketPayload = new ByteArray(0);
        // Destination is broadcast addr 0xFFFFFFFF for admin messages to local node
        meshPacketPayload.addAll(writeVarint( (2 << 3) | 0 ));
        meshPacketPayload.addAll(writeVarint(0xFFFFFFFF));
        // PortNum is ADMIN_APP
        //...
        // Embed AdminMessage as payload
        //...

        // 3. Wrap in ToRadio and create stream packet
        //...
        return new ByteArray(0); // Placeholder
    }
}



Analysis of Performance, Limitations, and Future Work


Anticipated Performance

CPU and Watchdog: The manual serialization and, more critically, deserialization of Protobuf messages will be CPU-intensive. The CIQ platform employs a "watchdog" timer that terminates any application function that runs for too long without yielding control.17 Parsing the large initial node database sync could potentially trigger this watchdog. The implementation must be highly optimized, possibly processing the incoming data stream in smaller chunks across multiple execution cycles to avoid termination.
Memory: While modern Garmin watches have more memory than their predecessors, CIQ applications still operate under tight constraints.4 Storing the entire Meshtastic node database in memory could consume a significant portion of the available RAM. Developers should use memory-efficient data structures, such as
Array with numeric indices instead of Dictionary with string keys where possible, and be mindful of object allocation.26
Battery Life: Continuous BLE communication is a known source of battery drain on wearables. The application's battery impact will be comparable to that of using other connected BLE sensors (like a heart rate monitor) and will be significantly higher than the watch's baseline smartwatch mode.

Inherent Limitations of the Approach

Brittleness and Maintenance Burden: The most significant limitation is the application's tight coupling to the specific version of the Meshtastic Protobuf definitions it was built against. Any change to the .proto files in the main Meshtastic firmware project—such as adding a field, changing a field number, or modifying a message structure—will break the Garmin app's parser and serializer.15 This will require a manual rewrite of the affected code and a new release of the application, creating a substantial and continuous maintenance burden.
Development Complexity: The level of effort required to manually implement the Protobuf wire format is an order of magnitude higher than on platforms like Android or Python, where code generation tools are readily available. This increases initial development time and the likelihood of subtle, hard-to-diagnose bugs in the binary manipulation logic.
Feature Lag: Due to the high maintenance cost, it will be challenging for a Garmin client to keep pace with the feature velocity of the core Meshtastic project. New capabilities that rely on new or modified Protobuf messages will require significant development effort to support.

Recommendations for a Robust User Interface (UI/UX)

A successful application must provide a clear and intuitive user experience.
Connection Status: The UI must always display the current connection state (e.g., "Disconnected," "Scanning," "Connecting," "Syncing," "Connected") to manage user expectations.
Messaging: The interface should include a simple, readable view for incoming messages and a straightforward method for sending. Given the input limitations of a watch, this should focus on sending canned, pre-defined messages rather than free-form text entry.
Node List: A view showing the list of nodes received during the initial sync, with their user-assigned names and last-heard timestamps, would provide essential network awareness.

Pathways for Future Development

Expanded Administration: Support for a wider range of AdminMessage types to allow for comprehensive remote node configuration directly from the watch.
Location Sharing: Parsing incoming Position packets and displaying node locations on a map view if the target Garmin device supports mapping capabilities.
Automated Code Generation: The optimal long-term solution to the maintenance problem would be to develop an external tool (e.g., a Python script) that programmatically parses the official Meshtastic .proto files and automatically generates the corresponding Monkey C serialization and deserialization code. This would eliminate the manual, error-prone coding process and allow the app to be updated much more easily.

Conclusion and Final Recommendation

The implementation of a Meshtastic client on modern Garmin watches is a viable but highly challenging endeavor. There are no fundamental hardware or protocol-level barriers that make the project impossible. The Garmin CIQ BLE API provides the necessary tools to establish communication, and the latest watch hardware has the resources to run such an application.
The project's success hinges almost entirely on overcoming the "Protobuf Wall"—the absence of a Protobuf library in the Monkey C environment. This forces the developer into the domain of low-level, manual implementation of a complex data serialization format. The ideal developer for this task possesses a rare combination of deep expertise in the Garmin Connect IQ ecosystem and a strong background in byte-level data protocol implementation.
Final Verdict: The project is feasible for a dedicated and highly skilled developer. It is not a project suitable for a novice or intermediate programmer. The resulting application would offer unique and valuable off-grid communication capabilities directly on a user's wrist. However, the significant initial development effort and the ongoing maintenance burden required to keep the application in sync with the evolving Meshtastic project must be carefully weighed against the desired outcome.
Works cited
Mesh Broadcast Algorithm | Meshtastic, accessed July 13, 2025, https://meshtastic.org/docs/overview/mesh-algo/
meshtastic.org, accessed July 13, 2025, https://meshtastic.org/docs/development/reference/protobufs/#:~:text=Protocol%20Buffers%2C%20commonly%20referred%20to,Device%2Dto%2DDevice%20communication.
Monkey C - Garmin Developers, accessed July 13, 2025, https://developer.garmin.com/connect-iq/monkey-c/
Garmin fenix 8 AMOLED GPS Watch Long-term Review, accessed July 13, 2025, https://www.treelinereview.com/gearreviews/garmin-fenix-8-amoled-long-term-review
Garmin Fenix 8 In-Depth Review: Worth the Upgrade? | DC Rainmaker, accessed July 13, 2025, https://www.dcrainmaker.com/2024/08/garmin-fenix-8-in-depth-review.html
Toybox.BluetoothLowEnergy, accessed July 13, 2025, https://developer.garmin.com/connect-iq/api-docs/Toybox/BluetoothLowEnergy.html
Client API (Serial/TCP/BLE) | Meshtastic, accessed July 13, 2025, https://meshtastic.org/docs/development/device/client-api/
Docs at 5f00ad5691ae7d8a03fd92437b81e9a424e3483f ... - Buf.Build, accessed July 13, 2025, https://buf.build/meshtastic/protobufs/docs/5f00ad5691ae7d8a03fd92437b81e9a424e3483f:meshtastic
Connect IQ SDK - Garmin Developers, accessed July 13, 2025, https://developer.garmin.com/connect-iq/
Monkey C Language Reference - Garmin Developers, accessed July 13, 2025, https://developer.garmin.com/connect-iq/reference-guides/monkey-c-reference/
Class: Toybox.Lang.ByteArray, accessed July 13, 2025, https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/ByteArray.html
pendleto/Meshtastic-esp32: Device code for the Meshtastic ski/hike/fly/Signal-chat GPS radio - GitHub, accessed July 13, 2025, https://github.com/pendleto/Meshtastic-esp32
LoRa Meshtastic - Lounge - Dangerous Things Forum, accessed July 13, 2025, https://forum.dangerousthings.com/t/lora-meshtastic/21217
Meshtastic Glossary of Terms - OpenELAB, accessed July 13, 2025, https://openelab.io/blogs/getting-started/meshtastic-glossary-of-terms
Meshtastic - GitHub, accessed July 13, 2025, https://github.com/meshtastic
Learning to code with Monkey C or is another language better? - Connect IQ App Development Discussion - Garmin Forums, accessed July 13, 2025, https://forums.garmin.com/developer/connect-iq/f/discussion/363189/learning-to-code-with-monkey-c-or-is-another-language-better
Exceptions and Errors - Monkey C, accessed July 13, 2025, https://developer.garmin.com/connect-iq/monkey-c/exceptions-and-errors/
Using the Meshtastic CLI, accessed July 13, 2025, https://meshtastic.org/docs/software/python/cli/usage/
BLE: How to read out characteristic properties? - Connect IQ App Development Discussion, accessed July 13, 2025, https://forums.garmin.com/developer/connect-iq/f/discussion/314729/ble-how-to-read-out-characteristic-properties
Class: Toybox.BluetoothLowEnergy.BleDelegate, accessed July 13, 2025, https://developer.garmin.com/connect-iq/api-docs/Toybox/BluetoothLowEnergy/BleDelegate.html
[BLE] How to notify characteristic change on device - Connect IQ App Development Discussion - Garmin Forums, accessed July 13, 2025, https://forums.garmin.com/developer/connect-iq/f/discussion/328285/ble-how-to-notify-characteristic-change-on-device
Need some help related to BLE link to Ergo - Connect IQ App Development Discussion, accessed July 13, 2025, https://forums.garmin.com/developer/connect-iq/f/discussion/252468/need-some-help-related-to-ble-link-to-ergo
BLE: How to send Notify to Service - Connect IQ App Development Discussion, accessed July 13, 2025, https://forums.garmin.com/developer/connect-iq/f/discussion/332806/ble-how-to-send-notify-to-service
Protobufs - Meshtastic, accessed July 13, 2025, https://meshtastic.org/docs/development/reference/protobufs/
How to work with float values - Connect IQ App Development Discussion - Garmin Forums, accessed July 13, 2025, https://forums.garmin.com/developer/connect-iq/f/discussion/378309/how-to-work-with-float-values
Optimizing Monkey C code - Connect IQ App Development Discussion - Garmin Forums, accessed July 13, 2025, https://forums.garmin.com/developer/connect-iq/f/discussion/291568/optimizing-monkey-c-code
The protobuf definitions for the Meshtastic project - GitHub, accessed July 13, 2025, https://github.com/mzman88/Meshtastic-protobufs
