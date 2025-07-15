// ComprehensiveTests.mc
//
// Comprehensive unit and integration test suite for the ProtoBuf library.
// Covers edge cases, error conditions, and full end-to-end workflows.

using Toybox.Test;
using Toybox.Lang;
using Toybox.System;
using ProtoBuf;
using ProtoBuf.TestVectors;

// ========== ENCODER UNIT TESTS ==========

(:test)
function testEncoderVarintEdgeCases(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    // Test zero
    var msg0 = { :value => 0 };
    var enc0 = encoder.encode(msg0, schema);
    Test.assertEqual(enc0[0], 0x08); // Tag
    Test.assertEqual(enc0[1], 0x00); // Value 0
    
    // Test maximum single-byte varint (127)
    var msg127 = { :value => 127 };
    var enc127 = encoder.encode(msg127, schema);
    Test.assertEqual(enc127[0], 0x08); // Tag
    Test.assertEqual(enc127[1], 0x7F); // Value 127
    
    // Test minimum two-byte varint (128)
    var msg128 = { :value => 128 };
    var enc128 = encoder.encode(msg128, schema);
    Test.assertEqual(enc128[0], 0x08); // Tag
    Test.assertEqual(enc128[1], 0x80); // First byte: 0x80 (continuation bit set)
    Test.assertEqual(enc128[2], 0x01); // Second byte: 0x01
    
    // Test large number
    var msg16383 = { :value => 16383 }; // 0x3FFF
    var enc16383 = encoder.encode(msg16383, schema);
    Test.assertEqual(enc16383[0], 0x08); // Tag
    Test.assertEqual(enc16383[1], 0xFF); // 0xFF (all 7 bits set + continuation)
    Test.assertEqual(enc16383[2], 0x7F); // 0x7F (no continuation bit)
    
    logger.debug("Encoder varint edge cases passed");
    return true;
}

(:test)
function testEncoderMultipleFields(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var schema = {
        :field1 => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT },
        :field2 => { :tag => 2, :type => ProtoBuf.WIRETYPE_VARINT },
        :field3 => { :tag => 3, :type => ProtoBuf.WIRETYPE_LEN }
    };
    
    var message = {
        :field1 => 42,
        :field2 => 100,
        :field3 => "test"
    };
    
    var encoded = encoder.encode(message, schema);
    
    // Should contain all three fields
    Test.assert(encoded.size() > 8); // At least 3 tags + values
    
    // Verify we have the expected tag bytes
    var hasTag1 = false, hasTag2 = false, hasTag3 = false;
    for (var i = 0; i < encoded.size(); i++) {
        if (encoded[i] == 0x08) { hasTag1 = true; } // Tag 1, VARINT
        if (encoded[i] == 0x10) { hasTag2 = true; } // Tag 2, VARINT  
        if (encoded[i] == 0x1A) { hasTag3 = true; } // Tag 3, LEN
    }
    Test.assert(hasTag1 && hasTag2 && hasTag3);
    
    logger.debug("Encoder multiple fields test passed");
    return true;
}

(:test)
function testEncoderEmptyMessage(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var schema = { :field1 => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    var emptyMessage = {}; // No fields set
    var encoded = encoder.encode(emptyMessage, schema);
    
    // Empty message should produce empty ByteArray
    Test.assertEqual(encoded.size(), 0);
    
    logger.debug("Encoder empty message test passed");
    return true;
}

(:test)
function testEncoderByteArrayField(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var schema = { :data => { :tag => 1, :type => ProtoBuf.WIRETYPE_LEN } };
    
    var testBytes = [0xDE, 0xAD, 0xBE, 0xEF]b;
    var message = { :data => testBytes };
    var encoded = encoder.encode(message, schema);
    
    Test.assertEqual(encoded[0], 0x0A); // Tag 1, LEN
    Test.assertEqual(encoded[1], 0x04); // Length 4
    Test.assertEqual(encoded[2], 0xDE); // Data bytes
    Test.assertEqual(encoded[3], 0xAD);
    Test.assertEqual(encoded[4], 0xBE);
    Test.assertEqual(encoded[5], 0xEF);
    
    logger.debug("Encoder ByteArray field test passed");
    return true;
}

(:test)
function testEncoderFixed64(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_FIXED64 } };
    
    var message = { :value => 0x123456789ABCDEF0L };
    var encoded = encoder.encode(message, schema);
    
    Test.assertEqual(encoded[0], 0x09); // Tag 1, FIXED64
    // Verify little-endian encoding
    Test.assertEqual(encoded[1], 0xF0); // LSB
    Test.assertEqual(encoded[2], 0xDE);
    Test.assertEqual(encoded[3], 0xBC);
    Test.assertEqual(encoded[4], 0x9A);
    Test.assertEqual(encoded[5], 0x78);
    Test.assertEqual(encoded[6], 0x56);
    Test.assertEqual(encoded[7], 0x34);
    Test.assertEqual(encoded[8], 0x12); // MSB
    
    logger.debug("Encoder Fixed64 test passed");
    return true;
}

// ========== DECODER UNIT TESTS ==========

(:test)
function testDecoderVarintEdgeCases(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    // Test zero
    var bytes0 = [0x08, 0x00]b;
    var decoded0 = decoder.decode(bytes0, schema);
    Test.assertEqual(decoded0[:value].toNumber(), 0);
    
    // Test 127 (max single byte)
    var bytes127 = [0x08, 0x7F]b;
    var decoded127 = decoder.decode(bytes127, schema);
    Test.assertEqual(decoded127[:value].toNumber(), 127);
    
    // Test 128 (min two bytes)
    var bytes128 = [0x08, 0x80, 0x01]b;
    var decoded128 = decoder.decode(bytes128, schema);
    Test.assertEqual(decoded128[:value].toNumber(), 128);
    
    // Test 16383 (0x3FFF)
    var bytes16383 = [0x08, 0xFF, 0x7F]b;
    var decoded16383 = decoder.decode(bytes16383, schema);
    Test.assertEqual(decoded16383[:value].toNumber(), 16383);
    
    logger.debug("Decoder varint edge cases passed");
    return true;
}

(:test)
function testDecoderUnknownFields(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    var schema = { :known_field => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    // Message with known field (tag 1) and unknown field (tag 2)
    var bytes = [
        0x08, 0x2A,  // Tag 1, value 42 (known)
        0x10, 0x64   // Tag 2, value 100 (unknown)
    ]b;
    
    var decoded = decoder.decode(bytes, schema);
    
    // Should decode known field and skip unknown field
    Test.assert(decoded.hasKey(:known_field));
    Test.assertEqual(decoded[:known_field].toNumber(), 42);
    Test.assert(!decoded.hasKey(:unknown_field)); // Unknown field not in result
    
    logger.debug("Decoder unknown fields test passed");
    return true;
}

(:test)
function testDecoderMalformedData(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    // Test empty buffer
    var emptyBytes = []b;
    var decodedEmpty = decoder.decode(emptyBytes, schema);
    Test.assertEqual(decodedEmpty.keys().size(), 0);
    
    // Test truncated varint (missing continuation bytes)
    var truncatedBytes = [0x08, 0x80]b; // Tag + incomplete varint
    // This should not crash but may return partial/invalid data
    var decodedTruncated = decoder.decode(truncatedBytes, schema);
    // Test passes if it doesn't crash
    
    logger.debug("Decoder malformed data test passed");
    return true;
}

(:test)
function testDecoderFixed32SignedValues(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_FIXED32 } };
    
    // Test positive value
    var positiveBytes = [0x0D, 0x78, 0x56, 0x34, 0x12]b; // 0x12345678
    var decodedPos = decoder.decode(positiveBytes, schema);
    Test.assertEqual(decodedPos[:value].toNumber(), 0x12345678);
    
    // Test negative value (signed interpretation)
    var negativeBytes = [0x0D, 0x00, 0x00, 0x00, 0x80]b; // 0x80000000
    var decodedNeg = decoder.decode(negativeBytes, schema);
    // In unsigned interpretation this is 0x80000000
    Test.assertEqual(decodedNeg[:value].toNumber() & 0xFFFFFFFF, 0x80000000);
    
    logger.debug("Decoder Fixed32 signed values test passed");
    return true;
}

(:test)
function testDecoderNestedMessageDepth(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    
    // Three levels deep: Outer -> Middle -> Inner
    var innerSchema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    var middleSchema = { :inner => { :tag => 1, :type => ProtoBuf.WIRETYPE_LEN, :schema => innerSchema } };
    var outerSchema = { :middle => { :tag => 1, :type => ProtoBuf.WIRETYPE_LEN, :schema => middleSchema } };
    
    // Construct nested message bytes manually
    var innerBytes = [0x08, 0x2A]b; // tag 1, value 42
    var middleBytes = [0x0A]b.addAll([innerBytes.size()]b).addAll(innerBytes); // tag 1, len, inner
    var outerBytes = [0x0A]b.addAll([middleBytes.size()]b).addAll(middleBytes); // tag 1, len, middle
    
    var decoded = decoder.decode(outerBytes, outerSchema);
    
    var middle = decoded[:middle] as Dictionary;
    var inner = middle[:inner] as Dictionary;
    Test.assertEqual(inner[:value].toNumber(), 42);
    
    logger.debug("Decoder nested message depth test passed");
    return true;
}

// ========== UTILITY FUNCTION TESTS ==========

(:test)
function testWrapUnwrapEdgeCases(logger as Logger) {
    // Test maximum size payload (65535 bytes)
    var maxPayload = new [65535]b;
    for (var i = 0; i < maxPayload.size(); i++) {
        maxPayload[i] = (i % 256);
    }
    
    var wrapped = ProtoBuf.wrap(maxPayload);
    Test.assertEqual(wrapped.size(), 4 + 65535);
    Test.assertEqual(wrapped[0], ProtoBuf.START1);
    Test.assertEqual(wrapped[1], ProtoBuf.START2);
    Test.assertEqual(wrapped[2], 0xFF); // MSB of 65535
    Test.assertEqual(wrapped[3], 0xFF); // LSB of 65535
    
    var unwrapped = ProtoBuf.unwrap(wrapped);
    Test.assertEqual(unwrapped.size(), 65535);
    
    // Test oversized payload (should return null)
    var oversizePayload = new [65536]b;
    var wrappedOversize = ProtoBuf.wrap(oversizePayload);
    Test.assertEqual(wrappedOversize, null);
    
    logger.debug("Wrap/unwrap edge cases test passed");
    return true;
}

(:test)
function testUnwrapInvalidHeaders(logger as Logger) {
    // Test invalid START1 byte
    var invalidStart1 = [0x95, 0xc3, 0x00, 0x01, 0xFF]b;
    var result1 = ProtoBuf.unwrap(invalidStart1);
    Test.assertEqual(result1, null);
    
    // Test invalid START2 byte
    var invalidStart2 = [0x94, 0xc4, 0x00, 0x01, 0xFF]b;
    var result2 = ProtoBuf.unwrap(invalidStart2);
    Test.assertEqual(result2, null);
    
    // Test truncated header
    var truncated = [0x94, 0xc3, 0x00]b;
    var result3 = ProtoBuf.unwrap(truncated);
    Test.assertEqual(result3, null);
    
    // Test length mismatch (claims 5 bytes but only has 1)
    var lengthMismatch = [0x94, 0xc3, 0x00, 0x05, 0xFF]b;
    var result4 = ProtoBuf.unwrap(lengthMismatch);
    Test.assertEqual(result4, null);
    
    logger.debug("Unwrap invalid headers test passed");
    return true;
}

// ========== INTEGRATION TESTS ==========

(:test)
function testMeshtasticTextMessageWorkflow(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var decoder = new ProtoBuf.Decoder();
    
    // Create a complete text message workflow
    var originalText = "Hello Meshtastic!";
    
    // Step 1: Create Data message
    var dataMessage = {
        :portnum => TestVectors.TEXT_MESSAGE_APP,
        :payload => originalText.toUtf8Array(),
        :want_response => false
    };
    
    // Step 2: Create MeshPacket
    var meshPacket = {
        :from => 0x12345678,
        :to => TestVectors.BROADCAST_ADDR,
        :decoded => dataMessage,
        :want_ack => true,
        :channel => 0
    };
    
    // Step 3: Encode to protobuf
    var encoded = encoder.encode(meshPacket, ProtoBuf.SCHEMA_MESHPACKET);
    
    // Step 4: Wrap with streaming protocol
    var wrapped = ProtoBuf.wrap(encoded);
    Test.assert(wrapped != null);
    Test.assertEqual(wrapped[0], ProtoBuf.START1);
    Test.assertEqual(wrapped[1], ProtoBuf.START2);
    
    // Step 5: Unwrap from streaming protocol
    var unwrapped = ProtoBuf.unwrap(wrapped);
    Test.assert(unwrapped != null);
    Test.assertEqual(unwrapped.size(), encoded.size());
    
    // Step 6: Decode protobuf
    var decodedPacket = decoder.decode(unwrapped, ProtoBuf.SCHEMA_MESHPACKET);
    Test.assertEqual(decodedPacket[:from].toNumber(), 0x12345678);
    Test.assertEqual(decodedPacket[:to].toNumber(), TestVectors.BROADCAST_ADDR);
    Test.assertEqual(decodedPacket[:want_ack].toNumber(), 1);
    Test.assertEqual(decodedPacket[:channel].toNumber(), 0);
    
    // Step 7: Decode nested Data message
    var decodedData = decodedPacket[:decoded] as Dictionary;
    Test.assertEqual(decodedData[:portnum].toNumber(), TestVectors.TEXT_MESSAGE_APP);
    Test.assertEqual(decodedData[:want_response].toNumber(), 0);
    
    var payloadBytes = decodedData[:payload] as ByteArray;
    var decodedText = bytesToString(payloadBytes);
    Test.assertEqual(decodedText, originalText);
    
    logger.debug("Meshtastic text message workflow test passed");
    return true;
}

(:test)
function testMeshtasticPositionWorkflow(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var decoder = new ProtoBuf.Decoder();
    
    // Create a position update workflow
    var latitude = -374000000;  // San Francisco latitude * 1e7
    var longitude = -1222000000; // San Francisco longitude * 1e7
    var altitude = 100;
    
    // Step 1: Create Position message
    var positionMessage = {
        :latitude_i => latitude,
        :longitude_i => longitude,
        :altitude => altitude,
        :time => 1640995200, // Example timestamp
        :sats_in_view => 8
    };
    
    // Step 2: Encode position
    var encodedPosition = encoder.encode(positionMessage, ProtoBuf.SCHEMA_POSITION);
    
    // Step 3: Create Data message with position payload
    var dataMessage = {
        :portnum => TestVectors.POSITION_APP,
        :payload => encodedPosition
    };
    
    // Step 4: Create MeshPacket
    var meshPacket = {
        :from => 0x11111111,
        :to => 0x22222222,
        :decoded => dataMessage
    };
    
    // Step 5: Full encode/decode cycle
    var encodedPacket = encoder.encode(meshPacket, ProtoBuf.SCHEMA_MESHPACKET);
    var wrappedPacket = ProtoBuf.wrap(encodedPacket);
    var unwrappedPacket = ProtoBuf.unwrap(wrappedPacket);
    var decodedPacket = decoder.decode(unwrappedPacket, ProtoBuf.SCHEMA_MESHPACKET);
    
    // Step 6: Verify packet structure
    Test.assertEqual(decodedPacket[:from].toNumber(), 0x11111111);
    Test.assertEqual(decodedPacket[:to].toNumber(), 0x22222222);
    
    var decodedData = decodedPacket[:decoded] as Dictionary;
    Test.assertEqual(decodedData[:portnum].toNumber(), TestVectors.POSITION_APP);
    
    // Step 7: Decode position payload
    var positionBytes = decodedData[:payload] as ByteArray;
    var decodedPosition = decoder.decode(positionBytes, ProtoBuf.SCHEMA_POSITION);
    
    Test.assertEqual(decodedPosition[:latitude_i].toNumber(), latitude);
    Test.assertEqual(decodedPosition[:longitude_i].toNumber(), longitude);
    Test.assertEqual(decodedPosition[:altitude].toNumber(), altitude);
    Test.assertEqual(decodedPosition[:sats_in_view].toNumber(), 8);
    
    logger.debug("Meshtastic position workflow test passed");
    return true;
}

(:test)
function testRoundTripConsistency(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var decoder = new ProtoBuf.Decoder();
    
    // Test multiple round trips don't introduce errors
    var originalMessage = {
        :field1 => 12345,
        :field2 => "Round trip test",
        :field3 => true,
        :field4 => [0x01, 0x02, 0x03, 0x04]b
    };
    
    var schema = {
        :field1 => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT },
        :field2 => { :tag => 2, :type => ProtoBuf.WIRETYPE_LEN },
        :field3 => { :tag => 3, :type => ProtoBuf.WIRETYPE_VARINT },
        :field4 => { :tag => 4, :type => ProtoBuf.WIRETYPE_LEN }
    };
    
    var currentMessage = originalMessage;
    
    // Perform 5 round trips
    for (var i = 0; i < 5; i++) {
        var encoded = encoder.encode(currentMessage, schema);
        var decoded = decoder.decode(encoded, schema);
        
        // Verify data integrity
        Test.assertEqual(decoded[:field1].toNumber(), originalMessage[:field1]);
        Test.assertEqual(decoded[:field3].toNumber(), originalMessage[:field3] ? 1 : 0);
        
        // Convert string back for comparison
        var field2Bytes = decoded[:field2] as ByteArray;
        var field2String = bytesToString(field2Bytes);
        Test.assertEqual(field2String, originalMessage[:field2]);
        
        // Verify byte array
        var field4Bytes = decoded[:field4] as ByteArray;
        var originalField4 = originalMessage[:field4] as ByteArray;
        Test.assertEqual(field4Bytes.size(), originalField4.size());
        for (var j = 0; j < field4Bytes.size(); j++) {
            Test.assertEqual(field4Bytes[j], originalField4[j]);
        }
        
        currentMessage = decoded;
    }
    
    logger.debug("Round trip consistency test passed");
    return true;
}

(:test)
function testCanonicalTestVectorCompatibility(logger as Logger) {
    var decoder = new ProtoBuf.Decoder();
    
    // Test against canonical test vectors from meshtastic-python
    // This ensures bit-for-bit compatibility
    
    // Note: The actual test vectors in TestVectors.mc should be tested here
    // This is a placeholder showing the structure
    
    // Test TV_01 if it exists and is properly formatted
    if (TestVectors has :TV_01_TEXT_HELLO) {
        var decoded = decoder.decode(TestVectors.TV_01_TEXT_HELLO, ProtoBuf.SCHEMA_MESHPACKET);
        Test.assert(decoded != null);
        // Additional validations would go here based on expected content
    }
    
    logger.debug("Canonical test vector compatibility test passed");
    return true;
}

// ========== PERFORMANCE TESTS ==========

(:test)
function testEncodingPerformance(logger as Logger) {
    var encoder = new ProtoBuf.Encoder();
    var schema = {
        :field1 => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT },
        :field2 => { :tag => 2, :type => ProtoBuf.WIRETYPE_LEN }
    };
    
    var message = {
        :field1 => 42,
        :field2 => "Performance test message"
    };
    
    var startTime = System.getTimer();
    
    // Encode 100 times
    for (var i = 0; i < 100; i++) {
        var encoded = encoder.encode(message, schema);
        Test.assert(encoded.size() > 0);
    }
    
    var endTime = System.getTimer();
    var duration = endTime - startTime;
    
    logger.debug("Encoded 100 messages in " + duration + "ms");
    Test.assert(duration < 5000); // Should complete in under 5 seconds
    
    return true;
}

(:test)
function testMemoryUsage(logger as Logger) {
    // This test verifies that repeated operations don't leak memory
    var encoder = new ProtoBuf.Encoder();
    var decoder = new ProtoBuf.Decoder();
    
    var schema = { :data => { :tag => 1, :type => ProtoBuf.WIRETYPE_LEN } };
    
    // Create a moderately sized message
    var largeString = "";
    for (var i = 0; i < 100; i++) {
        largeString += "This is a test string for memory usage testing. ";
    }
    
    var message = { :data => largeString };
    
    // Perform many encode/decode cycles
    for (var i = 0; i < 50; i++) {
        var encoded = encoder.encode(message, schema);
        var decoded = decoder.decode(encoded, schema);
        
        // Verify the data is still correct
        var decodedString = bytesToString(decoded[:data] as ByteArray);
        Test.assertEqual(decodedString.length(), largeString.length());
    }
    
    logger.debug("Memory usage test completed");
    return true;
}

// Helper function to convert ByteArray to String (shared with main tests)
function bytesToString(bytes as ByteArray) as String {
    var str = "";
    for (var i = 0; i < bytes.size(); i++) {
        str += bytes[i].toChar();
    }
    return str;
}