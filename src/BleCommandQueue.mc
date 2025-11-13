// BleCommandQueue.mc
//
// Command queue for serializing BLE operations
// Prevents command drops by ensuring only one operation at a time

using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;

class BleCommandQueue {
    private var _queue = [];
    private var _isProcessing = false;
    private var _currentCommand = null;
    private var _timeoutTimer = null;
    private var _defaultTimeout = 5000; // 5 seconds
    
    function initialize() {
    }
    
    // Add a command to the queue
    function enqueue(command) {
        if (command == null || !command.hasKey(:execute)) {
            System.println("Invalid command - must have execute method");
            return false;
        }
        
        _queue.add(command);
        System.println("Command enqueued, queue size: " + _queue.size());
        
        // Process queue if not already processing
        if (!_isProcessing) {
            processNext();
        }
        
        return true;
    }
    
    // Process the next command in the queue
    private function processNext() {
        if (_queue.size() == 0) {
            _isProcessing = false;
            _currentCommand = null;
            return;
        }
        
        _isProcessing = true;
        _currentCommand = _queue[0];
        _queue = _queue.slice(1, null);
        
        System.println("Processing command, remaining: " + _queue.size());
        
        // Set timeout
        var timeout = _currentCommand.hasKey(:timeout) ? _currentCommand[:timeout] : _defaultTimeout;
        startTimeout(timeout);
        
        // Execute the command
        try {
            _currentCommand[:execute].invoke();
        } catch (exception) {
            System.println("Command execution failed: " + exception.getErrorMessage());
            onCommandComplete(false, exception.getErrorMessage());
        }
    }
    
    // Called when a command completes (successfully or with error)
    function onCommandComplete(success, error) {
        stopTimeout();
        
        System.println("Command complete - success: " + success);
        
        // Call command's callback if it exists
        if (_currentCommand != null && _currentCommand.hasKey(:callback)) {
            try {
                _currentCommand[:callback].invoke(success, error);
            } catch (exception) {
                System.println("Command callback failed: " + exception.getErrorMessage());
            }
        }
        
        _currentCommand = null;
        
        // Process next command
        processNext();
    }
    
    // Start timeout timer
    private function startTimeout(duration) {
        stopTimeout();
        _timeoutTimer = new Timer.Timer();
        var timeoutMethod = new Lang.Method(self, :onTimeout);
        _timeoutTimer.start(timeoutMethod, duration, false);
    }
    
    // Stop timeout timer
    private function stopTimeout() {
        if (_timeoutTimer != null) {
            _timeoutTimer.stop();
            _timeoutTimer = null;
        }
    }
    
    // Handle command timeout
    private function onTimeout() {
        System.println("Command timeout!");
        onCommandComplete(false, "Command timeout");
    }
    
    // Clear the queue
    function clear() {
        stopTimeout();
        _queue = [];
        _isProcessing = false;
        _currentCommand = null;
        System.println("Command queue cleared");
    }
    
    // Get queue size
    function getSize() {
        return _queue.size();
    }
    
    // Check if queue is processing
    function isProcessing() {
        return _isProcessing;
    }
}

// Helper class to create BLE commands
class BleCommand {
    static function createWriteCommand(characteristic, data, callback) {
        return {
            :execute => new Lang.Method(characteristic, :requestWrite),
            :data => data,
            :callback => callback,
            :timeout => 3000
        };
    }
    
    static function createReadCommand(characteristic, callback) {
        return {
            :execute => new Lang.Method(characteristic, :requestRead),
            :callback => callback,
            :timeout => 3000
        };
    }
    
    static function createCustomCommand(executeMethod, callback, timeout) {
        return {
            :execute => executeMethod,
            :callback => callback,
            :timeout => timeout != null ? timeout : 5000
        };
    }
}