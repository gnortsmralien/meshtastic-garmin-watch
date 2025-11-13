// MessageHandlerTest.mc
//
// Unit tests for MessageHandler functionality
// Tests message creation, encoding, decoding, and the happy path flow

using Toybox.Test;
using Toybox.Lang;
using Toybox.System;
using ProtoBuf;

// Test message creation and encoding
(:test)
function testCreateWantConfigRequest(logger as Logger) as Boolean {
    logger.debug("Testing want_config_id request creation");

    var handler = new MessageHandler();
    var request = handler.createWantConfigRequest();

    Test.assertNotNull(request);
    Test.assert(request instanceof Lang.ByteArray);
    Test.assert(request.size() > 4); // At least header + some data

    // Check streaming header
    Test.assertEqual(request[0], ProtoBuf.START1);
    Test.assertEqual(request[1], ProtoBuf.START2);

    logger.debug("want_config_id request created successfully");
    return true;
}

// Test text message creation
(:test)
function testCreateTextMessage(logger as Logger) as Boolean {
    logger.debug("Testing text message creation");

    var handler = new MessageHandler();
    var text = "Hello Test";
    var destination = 0xFFFFFFFF; // Broadcast

    var message = handler.createTextMessage(text, destination, false);

    Test.assertNotNull(message);
    Test.assert(message instanceof Lang.ByteArray);
    Test.assert(message.size() > 4);

    // Check streaming header
    Test.assertEqual(message[0], ProtoBuf.START1);
    Test.assertEqual(message[1], ProtoBuf.START2);

    logger.debug("Text message created successfully: " + message.size() + " bytes");
    return true;
}

// Test message ID generation
(:test)
function testMessageIdGeneration(logger as Logger) as Boolean {
    logger.debug("Testing message ID generation");

    var handler = new MessageHandler();

    var id1 = handler.generateMessageId();
    var id2 = handler.generateMessageId();
    var id3 = handler.generateMessageId();

    // IDs should be unique and incrementing
    Test.assertNotEqual(id1, id2);
    Test.assertNotEqual(id2, id3);
    Test.assert(id2 > id1);
    Test.assert(id3 > id2);

    logger.debug("Message IDs: " + id1 + ", " + id2 + ", " + id3);
    return true;
}

// Test empty message handling
(:test)
function testEmptyMessageHandling(logger as Logger) as Boolean {
    logger.debug("Testing empty message handling");

    var handler = new MessageHandler();

    // Empty text should return null
    var message1 = handler.createTextMessage("", 0xFFFFFFFF, false);
    Test.assertNull(message1);

    // Null text should return null
    var message2 = handler.createTextMessage(null, 0xFFFFFFFF, false);
    Test.assertNull(message2);

    logger.debug("Empty messages handled correctly");
    return true;
}

// Test ToRadio message structure
(:test)
function testToRadioEncoding(logger as Logger) as Boolean {
    logger.debug("Testing ToRadio message encoding");

    var encoder = new ProtoBuf.Encoder();

    // Create a simple ToRadio with want_config_id
    var toRadio = {
        :want_config_id => 12345
    };

    var encoded = encoder.encode(toRadio, ProtoBuf.SCHEMA_TORADIO);
    Test.assertNotNull(encoded);
    Test.assert(encoded.size() > 0);

    // Decode it back
    var decoder = new ProtoBuf.Decoder();
    var decoded = decoder.decode(encoded, ProtoBuf.SCHEMA_TORADIO);

    Test.assertNotNull(decoded);
    Test.assert(decoded.hasKey(:want_config_id));
    Test.assertEqual(decoded[:want_config_id], 12345);

    logger.debug("ToRadio encoding/decoding successful");
    return true;
}

// Test Data message with TEXT_MESSAGE_APP
(:test)
function testDataMessageEncoding(logger as Logger) as Boolean {
    logger.debug("Testing Data message encoding");

    var encoder = new ProtoBuf.Encoder();
    var text = "Test message";

    var dataMessage = {
        :portnum => ProtoBuf.TEXT_MESSAGE_APP,
        :payload => text.toUtf8Array()
    };

    var encoded = encoder.encode(dataMessage, ProtoBuf.SCHEMA_DATA);
    Test.assertNotNull(encoded);
    Test.assert(encoded.size() > 0);

    // Decode it back
    var decoder = new ProtoBuf.Decoder();
    var decoded = decoder.decode(encoded, ProtoBuf.SCHEMA_DATA);

    Test.assertNotNull(decoded);
    Test.assert(decoded.hasKey(:portnum));
    Test.assertEqual(decoded[:portnum], ProtoBuf.TEXT_MESSAGE_APP);
    Test.assert(decoded.hasKey(:payload));

    logger.debug("Data message encoding/decoding successful");
    return true;
}

// Test MeshPacket encoding
(:test)
function testMeshPacketEncoding(logger as Logger) as Boolean {
    logger.debug("Testing MeshPacket encoding");

    var encoder = new ProtoBuf.Encoder();
    var decoder = new ProtoBuf.Decoder();

    // Create inner Data message
    var dataMessage = {
        :portnum => ProtoBuf.TEXT_MESSAGE_APP,
        :payload => "Hello".toUtf8Array()
    };
    var dataEncoded = encoder.encode(dataMessage, ProtoBuf.SCHEMA_DATA);

    // Create MeshPacket
    var meshPacket = {
        :from => 0x12345678,
        :to => 0xFFFFFFFF,
        :decoded => dataEncoded,
        :id => 42,
        :channel => 0
    };

    var encoded = encoder.encode(meshPacket, ProtoBuf.SCHEMA_MESHPACKET);
    Test.assertNotNull(encoded);
    Test.assert(encoded.size() > 0);

    // Decode it back
    var decoded = decoder.decode(encoded, ProtoBuf.SCHEMA_MESHPACKET);

    Test.assertNotNull(decoded);
    Test.assert(decoded.hasKey(:from));
    Test.assertEqual(decoded[:from], 0x12345678);
    Test.assert(decoded.hasKey(:to));
    Test.assertEqual(decoded[:to], 0xFFFFFFFF);
    Test.assert(decoded.hasKey(:id));
    Test.assertEqual(decoded[:id], 42);

    logger.debug("MeshPacket encoding/decoding successful");
    return true;
}

// Test wrap/unwrap with complete message
(:test)
function testStreamWrapUnwrap(logger as Logger) as Boolean {
    logger.debug("Testing stream wrap/unwrap");

    var encoder = new ProtoBuf.Encoder();

    // Create a simple message
    var toRadio = {
        :want_config_id => 999
    };

    var encoded = encoder.encode(toRadio, ProtoBuf.SCHEMA_TORADIO);
    var wrapped = ProtoBuf.wrap(encoded);

    Test.assertNotNull(wrapped);
    Test.assertEqual(wrapped[0], ProtoBuf.START1);
    Test.assertEqual(wrapped[1], ProtoBuf.START2);

    // Unwrap it
    var unwrapped = ProtoBuf.unwrap(wrapped);
    Test.assertNotNull(unwrapped);
    Test.assertEqual(unwrapped.size(), encoded.size());

    // Verify content matches
    for (var i = 0; i < encoded.size(); i++) {
        Test.assertEqual(unwrapped[i], encoded[i]);
    }

    logger.debug("Stream wrap/unwrap successful");
    return true;
}

// Test PortNum constants
(:test)
function testPortNumConstants(logger as Logger) as Boolean {
    logger.debug("Testing PortNum constants");

    Test.assertEqual(ProtoBuf.TEXT_MESSAGE_APP, 1);
    Test.assertEqual(ProtoBuf.POSITION_APP, 3);
    Test.assertEqual(ProtoBuf.NODEINFO_APP, 4);
    Test.assertEqual(ProtoBuf.ADMIN_APP, 6);

    logger.debug("PortNum constants verified");
    return true;
}

// Test complete happy path: create message, encode, wrap
(:test)
function testCompleteHappyPath(logger as Logger) as Boolean {
    logger.debug("Testing complete happy path");

    var handler = new MessageHandler();

    // Step 1: Create want_config_id (handshake)
    var configRequest = handler.createWantConfigRequest();
    Test.assertNotNull(configRequest);
    logger.debug("Step 1: Config request created");

    // Step 2: Create text message
    var textMessage = handler.createTextMessage("Hello Meshtastic!", 0xFFFFFFFF, false);
    Test.assertNotNull(textMessage);
    logger.debug("Step 2: Text message created");

    // Step 3: Verify both are properly formatted
    Test.assertEqual(configRequest[0], ProtoBuf.START1);
    Test.assertEqual(configRequest[1], ProtoBuf.START2);
    Test.assertEqual(textMessage[0], ProtoBuf.START1);
    Test.assertEqual(textMessage[1], ProtoBuf.START2);

    // Step 4: Verify sizes are reasonable
    Test.assert(configRequest.size() >= 8);  // Header + minimal ToRadio
    Test.assert(textMessage.size() >= 20);   // Header + ToRadio + MeshPacket + Data + text

    logger.debug("Happy path complete: All messages created successfully");
    logger.debug("Config request size: " + configRequest.size());
    logger.debug("Text message size: " + textMessage.size());

    return true;
}
