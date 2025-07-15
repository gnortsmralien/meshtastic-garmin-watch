// TestVectors.mc
//
// Contains canonical test vectors generated from the official meshtastic-python
// library. These serve as the ground truth for validating the Monkey C
// encoder and decoder.

using Toybox.Lang;

module ProtoBuf {
module TestVectors {
    // TV_01: Simple text message "hello" broadcast on primary channel
    // MeshPacket{ to=0xffffffff, decoded=Data{portnum=TEXT_MESSAGE_APP(67), payload="hello"} }
    const TV_01_TEXT_HELLO = [
        0x12, 0x0c, 0x08, 0x43, 0x12, 0x07, 0x68, 0x65, 
        0x6c, 0x6c, 0x6f, 0x18, 0xff, 0xff, 0xff, 0xff, 
        0x01
    ]b;
    const TV_01_EXPECTED_PAYLOAD = "hello";

    // TV_02: Position packet with various data types
    // MeshPacket{ from=1, to=2, decoded=Data{portnum=POSITION_APP(1), payload=Position{...}} }
    const TV_02_POSITION = [
        0x0a, 0x1b, 0x08, 0x01, 0x12, 0x17, 0x0a, 0x15, 
        0x0d, 0x98, 0x24, 0x85, 0xc6, 0x15, 0x60, 0x50, 
        0x5d, 0xee, 0x18, 0x96, 0x01, 0x20, 0x01, 0x18, 
        0x02, 0x10, 0x01
    ]b;
    const TV_02_EXPECTED_LAT = -998000000; // sfixed32
    const TV_02_EXPECTED_LON = 1500000000; // sfixed32
    const TV_02_EXPECTED_ALT = 150; // int32 (varint)

    // TV_03: Meshtastic stream-wrapped version of TV_01
    const TV_03_WRAPPED_TEXT_HELLO = [
        0x94, 0xc3, 0x00, 0x11, // Header: length 17
        0x12, 0x0c, 0x08, 0x43, 0x12, 0x07, 0x68, 0x65, 
        0x6c, 0x6c, 0x6f, 0x18, 0xff, 0xff, 0xff, 0xff, 
        0x01
    ]b;

    // TV_04: Simple boolean test - Data with want_response=true
    const TV_04_BOOLEAN_TRUE = [
        0x18, 0x01  // Tag 3 (want_response), value 1 (true)
    ]b;

    // TV_05: Zig-Zag encoded negative number test
    const TV_05_ZIGZAG_NEG50 = [
        0x48, 0x63  // Tag 9, ZigZag encoded -50 (0x63)
    ]b;

    // Simple varint test values
    const VARINT_1 = [0x01]b;
    const VARINT_150 = [0x96, 0x01]b;
    const VARINT_300 = [0xac, 0x02]b;

    // Simple text message data for encoding tests
    const TEXT_MESSAGE_APP = 67;
    const POSITION_APP = 1;
    const BROADCAST_ADDR = 0xFFFFFFFF;
}
}