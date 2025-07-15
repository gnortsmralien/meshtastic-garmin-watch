// SimpleTest.mc
//
// Minimal test application for ProtoBuf library

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using ProtoBuf;

class SimpleTestApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        System.println("=== ProtoBuf Simple Test ===");
        
        // Test 1: Basic Encoder/Decoder
        testBasicEncodeDecode();
        
        // Test 2: Varint encoding
        testVarintEncoding();
        
        // Test 3: String encoding
        testStringEncoding();
        
        System.println("=== Tests Complete ===");
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new SimpleTestView() ] as Array<Views or InputDelegates>;
    }
}

function testBasicEncodeDecode() as Void {
    System.println("Test 1: Basic Encode/Decode");
    
    var encoder = new ProtoBuf.Encoder();
    var decoder = new ProtoBuf.Decoder();
    
    var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    var message = { :value => 42 };
    
    var encoded = encoder.encode(message, schema);
    System.println("Encoded size: " + encoded.size());
    
    var decoded = decoder.decode(encoded, schema);
    var result = decoded[:value].toNumber();
    
    if (result == 42) {
        System.println("✓ Basic encode/decode passed");
    } else {
        System.println("✗ Basic encode/decode failed: " + result);
    }
}

function testVarintEncoding() as Void {
    System.println("Test 2: Varint Encoding");
    
    var encoder = new ProtoBuf.Encoder();
    var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
    
    // Test value 1
    var message1 = { :value => 1 };
    var encoded1 = encoder.encode(message1, schema);
    
    if (encoded1.size() == 2 && encoded1[0] == 0x08 && encoded1[1] == 0x01) {
        System.println("✓ Varint encoding for 1 passed");
    } else {
        System.println("✗ Varint encoding for 1 failed");
    }
    
    // Test value 150
    var message150 = { :value => 150 };
    var encoded150 = encoder.encode(message150, schema);
    
    if (encoded150.size() == 3 && encoded150[0] == 0x08) {
        System.println("✓ Varint encoding for 150 passed");
    } else {
        System.println("✗ Varint encoding for 150 failed");
    }
}

function testStringEncoding() as Void {
    System.println("Test 3: String Encoding");
    
    var encoder = new ProtoBuf.Encoder();
    var decoder = new ProtoBuf.Decoder();
    
    var schema = { :text => { :tag => 1, :type => ProtoBuf.WIRETYPE_LEN } };
    var message = { :text => "hello" };
    
    var encoded = encoder.encode(message, schema);
    var decoded = decoder.decode(encoded, schema);
    
    if (decoded.hasKey(:text)) {
        System.println("✓ String encoding passed");
    } else {
        System.println("✗ String encoding failed");
    }
}

class SimpleTestView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, 
                   Graphics.FONT_MEDIUM, "ProtoBuf Tests", Graphics.TEXT_JUSTIFY_CENTER);
    }
}