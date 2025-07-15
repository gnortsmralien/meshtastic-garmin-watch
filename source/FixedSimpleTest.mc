// FixedSimpleTest.mc
//
// Working test application for ProtoBuf library - Monkey C compatible

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics;
using ProtoBuf;

class FixedSimpleTestApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
        System.println("=== ProtoBuf Working Test ===");
        
        // Test basic functionality only (no complex syntax)
        testBasicEncoding();
        testBasicDecoding();
        testStreamWrapUnwrap();
        
        System.println("=== Tests Complete ===");
    }

    function onStop(state as Lang.Dictionary?) as Void {
    }

    function getInitialView() {
        return [ new WorkingTestView() ];
    }
}

function testBasicEncoding() as Void {
    System.println("Test: Basic Encoding");
    
    try {
        var encoder = new ProtoBuf.Encoder();
        var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
        var message = { :value => 42 };
        
        var encoded = encoder.encode(message, schema);
        System.println("✓ Encoding works - size: " + encoded.size());
    } catch (exception) {
        System.println("✗ Encoding failed: " + exception.getErrorMessage());
    }
}

function testBasicDecoding() as Void {
    System.println("Test: Basic Decoding");
    
    try {
        var decoder = new ProtoBuf.Decoder();
        var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
        
        // Simple test data: tag 1 (0x08) + value 42 (0x2A)
        var testBytes = [0x08, 0x2A]b;
        var decoded = decoder.decode(testBytes, schema);
        
        if (decoded.hasKey(:value)) {
            System.println("✓ Decoding works - value: " + decoded[:value]);
        } else {
            System.println("✗ Decoding failed - no value found");
        }
    } catch (exception) {
        System.println("✗ Decoding failed: " + exception.getErrorMessage());
    }
}

function testStreamWrapUnwrap() as Void {
    System.println("Test: Stream Wrap/Unwrap");
    
    try {
        var testData = [0x01, 0x02, 0x03]b;
        var wrapped = ProtoBuf.wrap(testData);
        
        if (wrapped != null) {
            System.println("✓ Wrap works - size: " + wrapped.size());
            
            var unwrapped = ProtoBuf.unwrap(wrapped);
            if (unwrapped != null && unwrapped.size() == testData.size()) {
                System.println("✓ Unwrap works - size: " + unwrapped.size());
            } else {
                System.println("✗ Unwrap failed");
            }
        } else {
            System.println("✗ Wrap failed");
        }
    } catch (exception) {
        System.println("✗ Stream test failed: " + exception.getErrorMessage());
    }
}

class WorkingTestView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, 
                   Graphics.FONT_MEDIUM, "ProtoBuf Test", Graphics.TEXT_JUSTIFY_CENTER);
                   
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 30, 
                   Graphics.FONT_SMALL, "Check Debug Output", Graphics.TEXT_JUSTIFY_CENTER);
    }
}