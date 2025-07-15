// ProtoTest.mc
//
// Unit test harness for the ProtoBuf library.
// Run this in the Connect IQ simulator to validate the implementation.

using Toybox.Test;
using Toybox.Lang;
using Toybox.System;
using ProtoBuf;
using ProtoBuf.TestVectors;

(:test)
function testVarintEncoding(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    
    // Test encoding single varint values
    var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    // Test value 1
    var message1 = { :value => 1 };
    var encoded1 = encoder.encode(message1, schema);
    var expected1 = [0x08, 0x01]b; // Tag 1 + value 1
    Test.assertEqual(encoded1.size(), expected1.size());
    
    // Test value 150  
    var message150 = { :value => 150 };
    var encoded150 = encoder.encode(message150, schema);
    var expected150 = [0x08, 0x96, 0x01]b; // Tag 1 + varint 150
    Test.assertEqual(encoded150.size(), expected150.size());
    
    logger.debug("Varint encoding tests passed");
    return true;
}

(:test)
function testVarintDecoding(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    // Test decoding value 1
    var bytes1 = [0x08, 0x01]b;
    var decoded1 = decoder.decode(bytes1, schema);
    Test.assertEqual(decoded1[:value].toNumber(), 1);
    
    // Test decoding value 150
    var bytes150 = [0x08, 0x96, 0x01]b;
    var decoded150 = decoder.decode(bytes150, schema);
    Test.assertEqual(decoded150[:value].toNumber(), 150);
    
    logger.debug("Varint decoding tests passed");
    return true;
}

(:test)
function testStringEncoding(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var schema = { :text => { :tag => 1, :type => ProtoBuf.WIRETYPE_LEN } };
    
    var message = { :text => "hello" };
    var encoded = encoder.encode(message, schema);
    
    // Should be: tag(0x0A) + length(0x05) + "hello"
    Test.assertEqual(encoded[0], 0x0A); // Tag 1, wire type 2
    Test.assertEqual(encoded[1], 0x05); // Length 5
    Test.assertEqual(encoded[2], 0x68); // 'h'
    Test.assertEqual(encoded[3], 0x65); // 'e'
    Test.assertEqual(encoded[4], 0x6C); // 'l'
    Test.assertEqual(encoded[5], 0x6C); // 'l'
    Test.assertEqual(encoded[6], 0x6F); // 'o'
    
    logger.debug("String encoding test passed");
    return true;
}

(:test)
function testStringDecoding(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    var schema = { :text => { :tag => 1, :type => ProtoBuf.WIRETYPE_LEN } };
    
    var bytes = [0x0A, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F]b;
    var decoded = decoder.decode(bytes, schema);
    
    Test.assert(decoded.hasKey(:text));
    var textBytes = decoded[:text] as ByteArray;
    var textStr = bytesToString(textBytes);
    Test.assertEqual(textStr, "hello");
    
    logger.debug("String decoding test passed");
    return true;
}

(:test)
function testBooleanEncoding(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var schema = { :flag => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    // Test true
    var messageTrue = { :flag => true };
    var encodedTrue = encoder.encode(messageTrue, schema);
    Test.assertEqual(encodedTrue[0], 0x08); // Tag 1
    Test.assertEqual(encodedTrue[1], 0x01); // True = 1
    
    // Test false
    var messageFalse = { :flag => false };
    var encodedFalse = encoder.encode(messageFalse, schema);
    Test.assertEqual(encodedFalse[0], 0x08); // Tag 1
    Test.assertEqual(encodedFalse[1], 0x00); // False = 0
    
    logger.debug("Boolean encoding test passed");
    return true;
}

(:test)
function testNestedMessageEncoding(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    
    // Create a simple nested message test
    var innerSchema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    var outerSchema = { 
        :inner => { :tag => 1, :type => ProtoBuf.WIRETYPE_LEN, :schema => innerSchema } 
    };
    
    var innerMessage = { :value => 42 };
    var outerMessage = { :inner => innerMessage };
    
    var encoded = encoder.encode(outerMessage, outerSchema);
    
    // Should contain tag for outer field, length, then encoded inner message
    Test.assertEqual(encoded[0], 0x0A); // Tag 1, wire type LEN
    Test.assert(encoded.size() > 3); // At least tag + length + inner content
    
    logger.debug("Nested message encoding test passed");
    return true;
}

(:test)
function testNestedMessageDecoding(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    
    var innerSchema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    var outerSchema = { 
        :inner => { :tag => 1, :type => ProtoBuf.WIRETYPE_LEN, :schema => innerSchema } 
    };
    
    // Manually construct: outer tag + length + (inner tag + inner value)
    var bytes = [0x0A, 0x02, 0x08, 0x2A]b; // outer tag, len=2, inner tag 1, value 42
    var decoded = decoder.decode(bytes, outerSchema);
    
    Test.assert(decoded.hasKey(:inner));
    var inner = decoded[:inner] as Dictionary;
    Test.assertEqual(inner[:value].toNumber(), 42);
    
    logger.debug("Nested message decoding test passed");
    return true;
}

(:test)
function testStreamWrapping(logger as Logger) {
    var payload = [0x01, 0x02, 0x03]b;
    var wrapped = ProtoBuf.wrap(payload);
    
    Test.assertEqual(wrapped.size(), 4 + payload.size());
    Test.assertEqual(wrapped[0], ProtoBuf.START1);
    Test.assertEqual(wrapped[1], ProtoBuf.START2);
    Test.assertEqual(wrapped[2], 0x00); // Length MSB
    Test.assertEqual(wrapped[3], 0x03); // Length LSB
    
    var unwrapped = ProtoBuf.unwrap(wrapped);
    Test.assertEqual(payload.size(), unwrapped.size());
    for (var i = 0; i < payload.size(); i++) {
        Test.assertEqual(payload[i], unwrapped[i]);
    }
    
    logger.debug("Stream wrap/unwrap test passed");
    return true;
}

(:test)
function testMeshtasticDataSchema(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var decoder = new ProtoBuf.Decoder();
    
    // Test encoding/decoding with actual Meshtastic Data schema
    var dataMessage = {
        :portnum => TestVectors.TEXT_MESSAGE_APP,
        :payload => "test".toUtf8Array(),
        :want_response => false
    };
    
    var encoded = encoder.encode(dataMessage, ProtoBuf.SCHEMA_DATA);
    var decoded = decoder.decode(encoded, ProtoBuf.SCHEMA_DATA);
    
    Test.assertEqual(decoded[:portnum].toNumber(), TestVectors.TEXT_MESSAGE_APP);
    Test.assertEqual(decoded[:want_response].toNumber(), 0); // false
    
    var payloadBytes = decoded[:payload] as ByteArray;
    var payloadStr = bytesToString(payloadBytes);
    Test.assertEqual(payloadStr, "test");
    
    logger.debug("Meshtastic Data schema test passed");
    return true;
}

(:test)
function testMeshtasticMeshPacketSchema(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var decoder = new ProtoBuf.Decoder();
    
    // Create a complete MeshPacket with nested Data
    var dataMessage = {
        :portnum => TestVectors.TEXT_MESSAGE_APP,
        :payload => "hi".toUtf8Array()
    };
    
    var meshPacket = {
        :to => TestVectors.BROADCAST_ADDR,
        :decoded => dataMessage,
        :want_ack => false
    };
    
    var encoded = encoder.encode(meshPacket, ProtoBuf.SCHEMA_MESHPACKET);
    var decoded = decoder.decode(encoded, ProtoBuf.SCHEMA_MESHPACKET);
    
    Test.assertEqual(decoded[:to].toNumber(), TestVectors.BROADCAST_ADDR);
    Test.assertEqual(decoded[:want_ack].toNumber(), 0);
    
    var decodedData = decoded[:decoded] as Dictionary;
    Test.assertEqual(decodedData[:portnum].toNumber(), TestVectors.TEXT_MESSAGE_APP);
    
    logger.debug("Meshtastic MeshPacket schema test passed");
    return true;
}

(:test)
function testFixed32Encoding(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var schema = { :fixed_val => { :tag => 1, :type => ProtoBuf.WIRETYPE_FIXED32 } };
    
    var message = { :fixed_val => 0x12345678 };
    var encoded = encoder.encode(message, schema);
    
    // Should be: tag(0x0D) + 4 bytes little-endian
    Test.assertEqual(encoded[0], 0x0D); // Tag 1, wire type FIXED32
    Test.assertEqual(encoded[1], 0x78); // LSB
    Test.assertEqual(encoded[2], 0x56);
    Test.assertEqual(encoded[3], 0x34);
    Test.assertEqual(encoded[4], 0x12); // MSB
    
    logger.debug("Fixed32 encoding test passed");
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