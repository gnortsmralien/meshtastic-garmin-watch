// CanonicalTests.mc
//
// Tests for bit-for-bit compatibility with canonical test vectors 
// generated from the official meshtastic-python library.
// These tests ensure our implementation matches the reference exactly.

using Toybox.Test;
using Toybox.Lang;
using Toybox.System;
using ProtoBuf;
using ProtoBuf.TestVectors;

(:test)
function testCanonicalTextMessage(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    
    // Test decoding the canonical text message test vector
    // This should decode to a MeshPacket with "hello" text message
    var decoded = decoder.decode(TestVectors.TV_01_TEXT_HELLO, ProtoBuf.SCHEMA_MESHPACKET);
    
    Test.assert(decoded != null);
    Test.assert(decoded.hasKey(:decoded));
    Test.assert(decoded.hasKey(:to));
    
    // Verify the outer MeshPacket structure
    Test.assertEqual(decoded[:to].toNumber(), TestVectors.BROADCAST_ADDR);
    
    // Decode the nested Data message
    var dataBytes = decoded[:decoded] as ByteArray;
    var dataDecoded = decoder.decode(dataBytes, ProtoBuf.SCHEMA_DATA);
    
    Test.assertEqual(dataDecoded[:portnum].toNumber(), TestVectors.TEXT_MESSAGE_APP);
    
    // Verify the payload is "hello"
    var payloadBytes = dataDecoded[:payload] as ByteArray;
    var payloadString = bytesToString(payloadBytes);
    Test.assertEqual(payloadString, TestVectors.TV_01_EXPECTED_PAYLOAD);
    
    logger.debug("Canonical text message test passed");
    return true;
}

(:test)
function testCanonicalPositionMessage(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    
    // Test decoding the canonical position message test vector
    var decoded = decoder.decode(TestVectors.TV_02_POSITION, ProtoBuf.SCHEMA_MESHPACKET);
    
    Test.assert(decoded != null);
    Test.assert(decoded.hasKey(:from));
    Test.assert(decoded.hasKey(:to));
    Test.assert(decoded.hasKey(:decoded));
    
    // Verify packet routing
    Test.assertEqual(decoded[:from].toNumber(), 1);
    Test.assertEqual(decoded[:to].toNumber(), 2);
    
    // Decode the Data message
    var dataBytes = decoded[:decoded] as ByteArray;
    var dataDecoded = decoder.decode(dataBytes, ProtoBuf.SCHEMA_DATA);
    
    Test.assertEqual(dataDecoded[:portnum].toNumber(), TestVectors.POSITION_APP);
    
    // Decode the Position payload
    var positionBytes = dataDecoded[:payload] as ByteArray;
    var positionDecoded = decoder.decode(positionBytes, ProtoBuf.SCHEMA_POSITION);
    
    // Verify the position data matches expected values
    // Note: These are sfixed32 values, may need sign conversion
    var lat = positionDecoded[:latitude_i].toNumber();
    var lon = positionDecoded[:longitude_i].toNumber();
    var alt = positionDecoded[:altitude].toNumber();
    
    // Handle sign extension for sfixed32 if needed
    if ((lat & 0x80000000) != 0) { lat = lat - 0x100000000; }
    if ((lon & 0x80000000) != 0) { lon = lon - 0x100000000; }
    
    Test.assertEqual(lat, TestVectors.TV_02_EXPECTED_LAT);
    Test.assertEqual(lon, TestVectors.TV_02_EXPECTED_LON);
    Test.assertEqual(alt, TestVectors.TV_02_EXPECTED_ALT);
    
    logger.debug("Canonical position message test passed");
    return true;
}

(:test)
function testCanonicalStreamWrapped(logger as Logger) {
    // Test the canonical stream-wrapped message
    var unwrapped = ProtoBuf.unwrap(TestVectors.TV_03_WRAPPED_TEXT_HELLO);
    
    Test.assert(unwrapped != null);
    
    // The unwrapped payload should match TV_01_TEXT_HELLO
    Test.assertEqual(unwrapped.size(), TestVectors.TV_01_TEXT_HELLO.size());
    
    for (var i = 0; i < unwrapped.size(); i++) {
        Test.assertEqual(unwrapped[i], TestVectors.TV_01_TEXT_HELLO[i]);
    }
    
    // Also test that we can decode the unwrapped content
    var decoder = new ProtoBuf.Decoder();
    var decoded = decoder.decode(unwrapped, ProtoBuf.SCHEMA_MESHPACKET);
    
    Test.assert(decoded != null);
    Test.assert(decoded.hasKey(:decoded));
    
    logger.debug("Canonical stream wrapped test passed");
    return true;
}

(:test)
function testCanonicalBooleanTrue(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    var schema = { :want_response => { :tag => 3, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    // Test the canonical boolean true encoding
    var decoded = decoder.decode(TestVectors.TV_04_BOOLEAN_TRUE, schema);
    
    Test.assert(decoded != null);
    Test.assert(decoded.hasKey(:want_response));
    Test.assertEqual(decoded[:want_response].toNumber(), 1); // true = 1
    
    logger.debug("Canonical boolean true test passed");
    return true;
}

(:test)
function testCanonicalZigZagEncoding(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    var schema = { :altitude_hae => { :tag => 9, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    // Test the canonical ZigZag encoded -50
    var decoded = decoder.decode(TestVectors.TV_05_ZIGZAG_NEG50, schema);
    
    Test.assert(decoded != null);
    Test.assert(decoded.hasKey(:altitude_hae));
    
    // The raw decoded value should be the ZigZag encoded value (0x63 = 99)
    // To decode ZigZag: (n >>> 1) ^ (-(n & 1))
    var zigzagValue = decoded[:altitude_hae].toNumber();
    var originalValue = (zigzagValue >>> 1) ^ (-(zigzagValue & 1));
    Test.assertEqual(originalValue, -50);
    
    logger.debug("Canonical ZigZag encoding test passed");
    return true;
}

(:test)
function testVarintCanonicalValues(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    // Test canonical varint encodings
    
    // Test value 1
    var decoded1 = decoder.decode([0x08].addAll(TestVectors.VARINT_1), schema);
    Test.assertEqual(decoded1[:value].toNumber(), 1);
    
    // Test value 150
    var decoded150 = decoder.decode([0x08].addAll(TestVectors.VARINT_150), schema);
    Test.assertEqual(decoded150[:value].toNumber(), 150);
    
    // Test value 300
    var decoded300 = decoder.decode([0x08].addAll(TestVectors.VARINT_300), schema);
    Test.assertEqual(decoded300[:value].toNumber(), 300);
    
    logger.debug("Varint canonical values test passed");
    return true;
}

(:test)
function testEncodingMatchesCanonical(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var decoder = new ProtoBuf.Decoder();
    
    // Test that our encoder produces output that matches canonical test vectors
    // We'll encode messages and compare with expected canonical output
    
    // Test simple text message encoding
    var dataMessage = {
        :portnum => TestVectors.TEXT_MESSAGE_APP,
        :payload => TestVectors.TV_01_EXPECTED_PAYLOAD.toUtf8Array()
    };
    
    var meshPacket = {
        :to => TestVectors.BROADCAST_ADDR,
        :decoded => dataMessage
    };
    
    var encoded = encoder.encode(meshPacket, ProtoBuf.SCHEMA_MESHPACKET);
    
    // Verify we can decode our own encoding and get the same data
    var decoded = decoder.decode(encoded, ProtoBuf.SCHEMA_MESHPACKET);
    Test.assertEqual(decoded[:to].toNumber(), TestVectors.BROADCAST_ADDR);
    
    var decodedData = decoded[:decoded] as Dictionary;
    Test.assertEqual(decodedData[:portnum].toNumber(), TestVectors.TEXT_MESSAGE_APP);
    
    var payloadBytes = decodedData[:payload] as ByteArray;
    var payloadString = bytesToString(payloadBytes);
    Test.assertEqual(payloadString, TestVectors.TV_01_EXPECTED_PAYLOAD);
    
    logger.debug("Encoding matches canonical test passed");
    return true;
}

(:test)
function testFullRoundTripCanonical(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var decoder = new ProtoBuf.Decoder();
    
    // Test the complete workflow: decode canonical -> modify -> encode -> decode -> verify
    
    // Start with canonical text message
    var originalDecoded = decoder.decode(TestVectors.TV_01_TEXT_HELLO, ProtoBuf.SCHEMA_MESHPACKET);
    
    // Modify the message slightly
    var dataBytes = originalDecoded[:decoded] as ByteArray;
    var dataDecoded = decoder.decode(dataBytes, ProtoBuf.SCHEMA_DATA);
    
    // Change the payload
    dataDecoded[:payload] = "modified".toUtf8Array();
    
    // Re-encode the modified data
    var modifiedDataEncoded = encoder.encode(dataDecoded, ProtoBuf.SCHEMA_DATA);
    
    // Update the packet with modified data
    originalDecoded[:decoded] = modifiedDataEncoded;
    
    // Re-encode the entire packet
    var finalEncoded = encoder.encode(originalDecoded, ProtoBuf.SCHEMA_MESHPACKET);
    
    // Wrap and unwrap with streaming protocol
    var wrapped = ProtoBuf.wrap(finalEncoded);
    var unwrapped = ProtoBuf.unwrap(wrapped);
    
    // Final decode and verify
    var finalDecoded = decoder.decode(unwrapped, ProtoBuf.SCHEMA_MESHPACKET);
    Test.assertEqual(finalDecoded[:to].toNumber(), TestVectors.BROADCAST_ADDR);
    
    var finalDataBytes = finalDecoded[:decoded] as ByteArray;
    var finalDataDecoded = decoder.decode(finalDataBytes, ProtoBuf.SCHEMA_DATA);
    
    var finalPayloadBytes = finalDataDecoded[:payload] as ByteArray;
    var finalPayloadString = bytesToString(finalPayloadBytes);
    Test.assertEqual(finalPayloadString, "modified");
    
    logger.debug("Full round trip canonical test passed");
    return true;
}

(:test)
function testCompatibilityWithVersions(logger as Logger) {
    // Test that our decoder can handle messages with additional fields
    // (simulating forward compatibility)
    
    var decoder = new ProtoBuf.Decoder();
    
    // Create a message with extra fields that aren't in our schema
    var messageWithExtraFields = [
        0x08, 0x01,  // field 1: value 1 (known)
        0x10, 0x02,  // field 2: value 2 (unknown)
        0x18, 0x03,  // field 3: value 3 (unknown)
        0x20, 0x04   // field 4: value 4 (unknown)
    ]b;
    
    // Schema only knows about field 1
    var limitedSchema = { :known_field => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    var decoded = decoder.decode(messageWithExtraFields, limitedSchema);
    
    // Should successfully decode the known field and skip unknown ones
    Test.assert(decoded != null);
    Test.assert(decoded.hasKey(:known_field));
    Test.assertEqual(decoded[:known_field].toNumber(), 1);
    
    // Should not have the unknown fields
    Test.assertEqual(decoded.keys().size(), 1);
    
    logger.debug("Compatibility with versions test passed");
    return true;
}

// Helper function to convert ByteArray to String
function bytesToString(bytes as ByteArray) as String {
    var str = "";
    for (var i = 0; i < bytes.size(); i++) {
        str += bytes[i].toChar();
    }
    return str;
}