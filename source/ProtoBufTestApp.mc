// ProtoBufTestApp.mc
//
// Main application entry point for running ProtoBuf tests
// This creates a simple widget that executes the test suite

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using ProtoBuf;

class ProtoBufTestApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        // Run tests on app start
        var logger = new TestLogger();
        runAllTests(logger);
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new ProtoBufTestView(), new ProtoBufTestDelegate() ] as Array<Views or InputDelegates>;
    }
}

class ProtoBufTestView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        
        // Display test status on screen
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 - 30, 
                   Graphics.FONT_MEDIUM, "ProtoBuf Tests", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, 
                   Graphics.FONT_SMALL, "Check debug output", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 30, 
                   Graphics.FONT_TINY, "for test results", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class ProtoBufTestDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        // Run tests when menu button is pressed
        var logger = new TestLogger();
        runAllTests(logger);
        return true;
    }
}

// Simple logger implementation for test output
class TestLogger {
    function debug(message as String) as Void {
        System.println(message);
    }
}

// Main test execution function
function runAllTests(logger as TestLogger) as Void {
    logger.debug("=== Starting ProtoBuf Test Suite ===");
    
    var totalTests = 0;
    var passedTests = 0;
    var failedTests = 0;
    
    // Run basic tests
    logger.debug("\n--- Basic Tests ---");
    passedTests += runBasicTests(logger);
    totalTests += 11; // Number of basic tests
    
    // Run comprehensive tests  
    logger.debug("\n--- Comprehensive Tests ---");
    passedTests += runComprehensiveTests(logger);
    totalTests += 22; // Number of comprehensive tests
    
    // Run canonical tests
    logger.debug("\n--- Canonical Tests ---");
    passedTests += runCanonicalTests(logger);
    totalTests += 9; // Number of canonical tests
    
    failedTests = totalTests - passedTests;
    
    // Print summary
    logger.debug("\n=== Test Summary ===");
    logger.debug("Total Tests: " + totalTests);
    logger.debug("Passed: " + passedTests);
    logger.debug("Failed: " + failedTests);
    
    if (failedTests == 0) {
        logger.debug("🎉 All tests passed!");
    } else {
        logger.debug("⚠️ " + failedTests + " test(s) failed");
    }
}

// Execute basic test functions
function runBasicTests(logger as TestLogger) as Number {
    var passed = 0;
    
    try { if (testVarintEncoding(logger)) { passed++; } } catch (e) { logger.debug("testVarintEncoding failed: " + e.getErrorMessage()); }
    try { if (testVarintDecoding(logger)) { passed++; } } catch (e) { logger.debug("testVarintDecoding failed: " + e.getErrorMessage()); }
    try { if (testStringEncoding(logger)) { passed++; } } catch (e) { logger.debug("testStringEncoding failed: " + e.getErrorMessage()); }
    try { if (testStringDecoding(logger)) { passed++; } } catch (e) { logger.debug("testStringDecoding failed: " + e.getErrorMessage()); }
    try { if (testBooleanEncoding(logger)) { passed++; } } catch (e) { logger.debug("testBooleanEncoding failed: " + e.getErrorMessage()); }
    try { if (testNestedMessageEncoding(logger)) { passed++; } } catch (e) { logger.debug("testNestedMessageEncoding failed: " + e.getErrorMessage()); }
    try { if (testNestedMessageDecoding(logger)) { passed++; } } catch (e) { logger.debug("testNestedMessageDecoding failed: " + e.getErrorMessage()); }
    try { if (testStreamWrapping(logger)) { passed++; } } catch (e) { logger.debug("testStreamWrapping failed: " + e.getErrorMessage()); }
    try { if (testMeshtasticDataSchema(logger)) { passed++; } } catch (e) { logger.debug("testMeshtasticDataSchema failed: " + e.getErrorMessage()); }
    try { if (testMeshtasticMeshPacketSchema(logger)) { passed++; } } catch (e) { logger.debug("testMeshtasticMeshPacketSchema failed: " + e.getErrorMessage()); }
    try { if (testFixed32Encoding(logger)) { passed++; } } catch (e) { logger.debug("testFixed32Encoding failed: " + e.getErrorMessage()); }
    
    return passed;
}

// Execute comprehensive test functions
function runComprehensiveTests(logger as TestLogger) as Number {
    var passed = 0;
    
    try { if (testEncoderVarintEdgeCases(logger)) { passed++; } } catch (e) { logger.debug("testEncoderVarintEdgeCases failed: " + e.getErrorMessage()); }
    try { if (testEncoderMultipleFields(logger)) { passed++; } } catch (e) { logger.debug("testEncoderMultipleFields failed: " + e.getErrorMessage()); }
    try { if (testEncoderEmptyMessage(logger)) { passed++; } } catch (e) { logger.debug("testEncoderEmptyMessage failed: " + e.getErrorMessage()); }
    try { if (testEncoderByteArrayField(logger)) { passed++; } } catch (e) { logger.debug("testEncoderByteArrayField failed: " + e.getErrorMessage()); }
    try { if (testEncoderFixed64(logger)) { passed++; } } catch (e) { logger.debug("testEncoderFixed64 failed: " + e.getErrorMessage()); }
    try { if (testDecoderVarintEdgeCases(logger)) { passed++; } } catch (e) { logger.debug("testDecoderVarintEdgeCases failed: " + e.getErrorMessage()); }
    try { if (testDecoderUnknownFields(logger)) { passed++; } } catch (e) { logger.debug("testDecoderUnknownFields failed: " + e.getErrorMessage()); }
    try { if (testDecoderMalformedData(logger)) { passed++; } } catch (e) { logger.debug("testDecoderMalformedData failed: " + e.getErrorMessage()); }
    try { if (testDecoderFixed32SignedValues(logger)) { passed++; } } catch (e) { logger.debug("testDecoderFixed32SignedValues failed: " + e.getErrorMessage()); }
    try { if (testDecoderNestedMessageDepth(logger)) { passed++; } } catch (e) { logger.debug("testDecoderNestedMessageDepth failed: " + e.getErrorMessage()); }
    try { if (testWrapUnwrapEdgeCases(logger)) { passed++; } } catch (e) { logger.debug("testWrapUnwrapEdgeCases failed: " + e.getErrorMessage()); }
    try { if (testUnwrapInvalidHeaders(logger)) { passed++; } } catch (e) { logger.debug("testUnwrapInvalidHeaders failed: " + e.getErrorMessage()); }
    try { if (testMeshtasticTextMessageWorkflow(logger)) { passed++; } } catch (e) { logger.debug("testMeshtasticTextMessageWorkflow failed: " + e.getErrorMessage()); }
    try { if (testMeshtasticPositionWorkflow(logger)) { passed++; } } catch (e) { logger.debug("testMeshtasticPositionWorkflow failed: " + e.getErrorMessage()); }
    try { if (testRoundTripConsistency(logger)) { passed++; } } catch (e) { logger.debug("testRoundTripConsistency failed: " + e.getErrorMessage()); }
    try { if (testCanonicalTestVectorCompatibility(logger)) { passed++; } } catch (e) { logger.debug("testCanonicalTestVectorCompatibility failed: " + e.getErrorMessage()); }
    try { if (testEncodingPerformance(logger)) { passed++; } } catch (e) { logger.debug("testEncodingPerformance failed: " + e.getErrorMessage()); }
    try { if (testMemoryUsage(logger)) { passed++; } } catch (e) { logger.debug("testMemoryUsage failed: " + e.getErrorMessage()); }
    
    return passed;
}

// Execute canonical test functions
function runCanonicalTests(logger as TestLogger) as Number {
    var passed = 0;
    
    try { if (testCanonicalTextMessage(logger)) { passed++; } } catch (e) { logger.debug("testCanonicalTextMessage failed: " + e.getErrorMessage()); }
    try { if (testCanonicalPositionMessage(logger)) { passed++; } } catch (e) { logger.debug("testCanonicalPositionMessage failed: " + e.getErrorMessage()); }
    try { if (testCanonicalStreamWrapped(logger)) { passed++; } } catch (e) { logger.debug("testCanonicalStreamWrapped failed: " + e.getErrorMessage()); }
    try { if (testCanonicalBooleanTrue(logger)) { passed++; } } catch (e) { logger.debug("testCanonicalBooleanTrue failed: " + e.getErrorMessage()); }
    try { if (testCanonicalZigZagEncoding(logger)) { passed++; } } catch (e) { logger.debug("testCanonicalZigZagEncoding failed: " + e.getErrorMessage()); }
    try { if (testVarintCanonicalValues(logger)) { passed++; } } catch (e) { logger.debug("testVarintCanonicalValues failed: " + e.getErrorMessage()); }
    try { if (testEncodingMatchesCanonical(logger)) { passed++; } } catch (e) { logger.debug("testEncodingMatchesCanonical failed: " + e.getErrorMessage()); }
    try { if (testFullRoundTripCanonical(logger)) { passed++; } } catch (e) { logger.debug("testFullRoundTripCanonical failed: " + e.getErrorMessage()); }
    try { if (testCompatibilityWithVersions(logger)) { passed++; } } catch (e) { logger.debug("testCompatibilityWithVersions failed: " + e.getErrorMessage()); }
    
    return passed;
}