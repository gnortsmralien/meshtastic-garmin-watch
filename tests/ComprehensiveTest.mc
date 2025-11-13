// ComprehensiveTest.mc
//
// Comprehensive test suite for all functionality without requiring BLE hardware

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics;
using ProtoBuf;

class ComprehensiveTestApp extends Application.AppBase {
    
    function initialize() {
        AppBase.initialize();
    }
    
    function onStart(state as Lang.Dictionary?) as Void {
        System.println("=== Comprehensive Test Suite ===");
        
        // Test 1: Protobuf functionality
        testProtobuf();
        
        // Test 2: BLE Manager (without actual BLE)
        testBleManager();
        
        // Test 3: Command Queue
        testCommandQueue();
        
        // Test 4: Meshtastic Message Schemas
        testMeshtasticSchemas();
        
        System.println("=== All Tests Complete ===");
    }
    
    function onStop(state as Lang.Dictionary?) as Void {
    }
    
    function getInitialView() {
        return [ new ComprehensiveTestView() ];
    }
    
    function testProtobuf() {
        System.println("\n--- Testing Protobuf ---");
        
        try {
            var encoder = new ProtoBuf.Encoder();
            var schema = { :value => { :tag => 1, :type => ProtoBuf.WIRETYPE_VARINT } };
            var message = { :value => 123 };
            
            var encoded = encoder.encode(message, schema);
            System.println("✓ Protobuf encoding: " + encoded.size() + " bytes");
            
            var decoder = new ProtoBuf.Decoder();
            var decoded = decoder.decode(encoded, schema);
            
            if (decoded.hasKey(:value) && decoded[:value] == 123) {
                System.println("✓ Protobuf decoding: value = " + decoded[:value]);
            } else {
                System.println("✗ Protobuf decoding failed");
            }
        } catch (exception) {
            System.println("✗ Protobuf test failed: " + exception.getErrorMessage());
        }
    }
    
    function testBleManager() {
        System.println("\n--- Testing BLE Manager ---");
        
        try {
            var bleManager = new SimpleBleManager();
            System.println("✓ BLE Manager created");
            
            // Test initial state
            var state = bleManager.getConnectionState();
            System.println("✓ Initial connection state: " + state);
            
            // Test connection check
            var isConnected = bleManager.isConnected();
            System.println("✓ Is connected: " + isConnected);
            
            // Test profile registration (this might fail without BLE permission)
            var profileResult = bleManager.registerProfile();
            if (profileResult) {
                System.println("✓ BLE profile registered");
            } else {
                System.println("⚠ BLE profile registration failed (expected without hardware)");
            }
            
        } catch (exception) {
            System.println("✗ BLE Manager test failed: " + exception.getErrorMessage());
        }
    }
    
    function testCommandQueue() {
        System.println("\n--- Testing Command Queue ---");
        
        try {
            var queue = new BleCommandQueue();
            System.println("✓ Command queue created");
            
            // Test initial state
            System.println("✓ Initial queue size: " + queue.getSize());
            System.println("✓ Is processing: " + queue.isProcessing());
            
            // Test queue operations
            queue.clear();
            System.println("✓ Queue cleared, size: " + queue.getSize());
            
        } catch (exception) {
            System.println("✗ Command queue test failed: " + exception.getErrorMessage());
        }
    }
    
    function testMeshtasticSchemas() {
        System.println("\n--- Testing Meshtastic Schemas ---");
        
        try {
            // Test Data schema
            var dataSchema = ProtoBuf.SCHEMA_DATA;
            System.println("✓ Data schema has " + dataSchema.keys().size() + " fields");
            
            // Test MeshPacket schema
            var meshSchema = ProtoBuf.SCHEMA_MESHPACKET;
            System.println("✓ MeshPacket schema has " + meshSchema.keys().size() + " fields");
            
            // Test Position schema
            var posSchema = ProtoBuf.SCHEMA_POSITION;
            System.println("✓ Position schema has " + posSchema.keys().size() + " fields");
            
            // Test streaming protocol
            var testData = [0x01, 0x02, 0x03, 0x04, 0x05]b;
            var wrapped = ProtoBuf.wrap(testData);
            
            if (wrapped != null && wrapped.size() == testData.size() + 4) {
                System.println("✓ Streaming wrap: " + wrapped.size() + " bytes");
                
                var unwrapped = ProtoBuf.unwrap(wrapped);
                if (unwrapped != null && unwrapped.size() == testData.size()) {
                    System.println("✓ Streaming unwrap: " + unwrapped.size() + " bytes");
                } else {
                    System.println("✗ Streaming unwrap failed");
                }
            } else {
                System.println("✗ Streaming wrap failed");
            }
            
        } catch (exception) {
            System.println("✗ Schema test failed: " + exception.getErrorMessage());
        }
    }
}

class ComprehensiveTestView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }
    
    function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, 
                   Graphics.FONT_MEDIUM, "Comprehensive Test", Graphics.TEXT_JUSTIFY_CENTER);
                   
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 30, 
                   Graphics.FONT_SMALL, "Check Debug Console", Graphics.TEXT_JUSTIFY_CENTER);
    }
}