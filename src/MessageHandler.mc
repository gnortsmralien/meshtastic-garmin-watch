// MessageHandler.mc
//
// Handles creation and parsing of Meshtastic messages
// Manages message history and node database

using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using ProtoBuf;

class MessageHandler {
    private var _encoder;
    private var _decoder;
    private var _myNodeNum = null;
    private var _messageIdCounter;
    private var _messages = []; // Array of received messages
    private var _nodes = {}; // Dictionary of node info, keyed by node number
    private var _configComplete = false;
    private var _unreadCount = 0; // Counter for unread messages

    // Callbacks
    private var _onMessageReceived = null;
    private var _onNodeUpdate = null;
    private var _onConfigComplete = null;

    function initialize() {
        _encoder = new ProtoBuf.Encoder();
        _decoder = new ProtoBuf.Decoder();
        _messageIdCounter = System.getTimer();
    }

    // Set callback for when a new text message is received
    function setMessageCallback(callback) {
        _onMessageReceived = callback;
    }

    // Set callback for when node info is updated
    function setNodeUpdateCallback(callback) {
        _onNodeUpdate = callback;
    }

    // Set callback for when initial config sync is complete
    function setConfigCompleteCallback(callback) {
        _onConfigComplete = callback;
    }

    // Generate unique message ID
    function generateMessageId() {
        _messageIdCounter = (_messageIdCounter + 1) & 0xFFFFFFFF;
        return _messageIdCounter;
    }

    // ============================================
    // OUTGOING MESSAGE CREATION
    // ============================================

    // Create a want_config_id request to initiate handshake
    function createWantConfigRequest() {
        var configId = System.getTimer() & 0xFFFFFFFF;

        var toRadio = {
            :want_config_id => configId
        };

        var encoded = _encoder.encode(toRadio, ProtoBuf.SCHEMA_TORADIO);
        var wrapped = ProtoBuf.wrap(encoded);

        System.println("Created want_config_id request: " + configId);
        return wrapped;
    }

    // Create a text message packet
    // @param text The message text to send
    // @param destination Node number (0xFFFFFFFF for broadcast)
    // @param wantAck Whether to request acknowledgment
    function createTextMessage(text, destination, wantAck) {
        if (text == null || text.length() == 0) {
            return null;
        }

        // Build Data message
        var dataMessage = {
            :portnum => ProtoBuf.TEXT_MESSAGE_APP,
            :payload => text.toUtf8Array()
        };

        var dataEncoded = _encoder.encode(dataMessage, ProtoBuf.SCHEMA_DATA);

        // Build MeshPacket
        var meshPacket = {
            :to => destination,
            :decoded => dataEncoded,
            :id => generateMessageId(),
            :want_ack => wantAck,
            :channel => 0,  // Primary channel
            :hop_limit => 3 // Standard hop limit
        };

        // Add from field if we know our node number
        if (_myNodeNum != null) {
            meshPacket[:from] = _myNodeNum;
        }

        var meshEncoded = _encoder.encode(meshPacket, ProtoBuf.SCHEMA_MESHPACKET);

        // Wrap in ToRadio
        var toRadio = {
            :packet => meshEncoded
        };

        var toRadioEncoded = _encoder.encode(toRadio, ProtoBuf.SCHEMA_TORADIO);
        var wrapped = ProtoBuf.wrap(toRadioEncoded);

        System.println("Created text message: \"" + text + "\" to: " + destination.format("%08X"));
        return wrapped;
    }

    // ============================================
    // INCOMING MESSAGE PARSING
    // ============================================

    // Process raw data received from BLE
    // @param data ByteArray of raw data from FromRadio characteristic
    function processReceivedData(data) {
        if (data == null || data.size() == 0) {
            return;
        }

        System.println("Processing received data: " + data.size() + " bytes");

        // Unwrap streaming header
        var unwrapped = ProtoBuf.unwrap(data);
        if (unwrapped == null) {
            System.println("Failed to unwrap data");
            return;
        }

        // Decode FromRadio message
        var fromRadio = _decoder.decode(unwrapped, ProtoBuf.SCHEMA_FROMRADIO);
        if (fromRadio == null) {
            System.println("Failed to decode FromRadio");
            return;
        }

        // Process based on what fields are present
        if (fromRadio.hasKey(:my_info)) {
            handleMyNodeInfo(fromRadio[:my_info]);
        }

        if (fromRadio.hasKey(:node_info)) {
            handleNodeInfo(fromRadio[:node_info]);
        }

        if (fromRadio.hasKey(:packet)) {
            handleMeshPacket(fromRadio[:packet]);
        }

        if (fromRadio.hasKey(:config_complete_id)) {
            handleConfigComplete(fromRadio[:config_complete_id]);
        }

        if (fromRadio.hasKey(:rebooted)) {
            System.println("Node has rebooted");
        }
    }

    // Handle MyNodeInfo message
    private function handleMyNodeInfo(myInfoBytes) {
        if (!(myInfoBytes instanceof Lang.ByteArray)) {
            // Already decoded as dictionary
            var myInfo = myInfoBytes;
            if (myInfo.hasKey(:my_node_num)) {
                _myNodeNum = myInfo[:my_node_num];
                System.println("My node number: " + _myNodeNum.format("%08X"));
            }
            return;
        }

        var myInfo = _decoder.decode(myInfoBytes, ProtoBuf.SCHEMA_MYNODEINFO);
        if (myInfo != null && myInfo.hasKey(:my_node_num)) {
            _myNodeNum = myInfo[:my_node_num];
            System.println("My node number: " + _myNodeNum.format("%08X"));
        }
    }

    // Handle NodeInfo message
    private function handleNodeInfo(nodeInfoBytes) {
        if (!(nodeInfoBytes instanceof Lang.ByteArray)) {
            // Already decoded
            var nodeInfo = nodeInfoBytes;
            if (nodeInfo.hasKey(:num)) {
                storeNodeInfo(nodeInfo);
            }
            return;
        }

        var nodeInfo = _decoder.decode(nodeInfoBytes, ProtoBuf.SCHEMA_NODEINFO);
        if (nodeInfo != null && nodeInfo.hasKey(:num)) {
            storeNodeInfo(nodeInfo);
        }
    }

    // Store node information in database
    private function storeNodeInfo(nodeInfo) {
        var nodeNum = nodeInfo[:num];
        _nodes[nodeNum] = nodeInfo;

        var nodeName = "Unknown";
        if (nodeInfo.hasKey(:user)) {
            var user = nodeInfo[:user];
            if (!(user instanceof Lang.ByteArray)) {
                if (user.hasKey(:long_name)) {
                    nodeName = bytesToString(user[:long_name]);
                }
            } else {
                var userDecoded = _decoder.decode(user, ProtoBuf.SCHEMA_USER);
                if (userDecoded.hasKey(:long_name)) {
                    nodeName = bytesToString(userDecoded[:long_name]);
                }
            }
        }

        System.println("Node info: " + nodeNum.format("%08X") + " - " + nodeName);

        if (_onNodeUpdate != null) {
            _onNodeUpdate.invoke(nodeInfo);
        }
    }

    // Handle MeshPacket
    private function handleMeshPacket(packetBytes) {
        if (!(packetBytes instanceof Lang.ByteArray)) {
            System.println("Packet is not ByteArray");
            return;
        }

        var meshPacket = _decoder.decode(packetBytes, ProtoBuf.SCHEMA_MESHPACKET);
        if (meshPacket == null) {
            System.println("Failed to decode MeshPacket");
            return;
        }

        System.println("Received packet from: " +
                      (meshPacket.hasKey(:from) ? meshPacket[:from].format("%08X") : "unknown"));

        // Process decoded data if present
        if (meshPacket.hasKey(:decoded)) {
            handleDataMessage(meshPacket);
        }
    }

    // Handle Data message within a MeshPacket
    private function handleDataMessage(meshPacket) {
        var dataBytes = meshPacket[:decoded];
        if (!(dataBytes instanceof Lang.ByteArray)) {
            return;
        }

        var dataMessage = _decoder.decode(dataBytes, ProtoBuf.SCHEMA_DATA);
        if (dataMessage == null) {
            System.println("Failed to decode Data message");
            return;
        }

        var portnum = dataMessage.hasKey(:portnum) ? dataMessage[:portnum] : 0;

        // Handle different message types
        switch (portnum) {
            case ProtoBuf.TEXT_MESSAGE_APP:
                handleTextMessage(meshPacket, dataMessage);
                break;
            case ProtoBuf.POSITION_APP:
                handlePositionMessage(meshPacket, dataMessage);
                break;
            case ProtoBuf.NODEINFO_APP:
                System.println("Received NodeInfo app message");
                break;
            default:
                System.println("Unhandled portnum: " + portnum);
                break;
        }
    }

    // Handle text message
    private function handleTextMessage(meshPacket, dataMessage) {
        if (!dataMessage.hasKey(:payload)) {
            return;
        }

        var textBytes = dataMessage[:payload];
        var text = bytesToString(textBytes);
        var from = meshPacket.hasKey(:from) ? meshPacket[:from] : 0;
        var messageId = meshPacket.hasKey(:id) ? meshPacket[:id] : 0;

        // Create message record
        var message = {
            :id => messageId,
            :from => from,
            :text => text,
            :timestamp => Time.now().value(),
            :portnum => ProtoBuf.TEXT_MESSAGE_APP,
            :read => false  // Mark as unread
        };

        // Store message
        _messages.add(message);
        if (_messages.size() > 50) {
            // Keep only last 50 messages
            _messages = _messages.slice(-50, null);
        }

        // Increment unread counter
        _unreadCount++;

        System.println("Text message from " + from.format("%08X") + ": " + text);

        if (_onMessageReceived != null) {
            _onMessageReceived.invoke(message);
        }
    }

    // Handle position message
    private function handlePositionMessage(meshPacket, dataMessage) {
        System.println("Received position update");
        // TODO: Decode position data and update node database
    }

    // Handle config complete
    private function handleConfigComplete(configId) {
        _configComplete = true;
        System.println("Config sync complete: " + configId);

        if (_onConfigComplete != null) {
            _onConfigComplete.invoke();
        }
    }

    // ============================================
    // DATA ACCESS
    // ============================================

    function getMessages() {
        return _messages;
    }

    function getNodes() {
        return _nodes;
    }

    function getNodeCount() {
        return _nodes.size();
    }

    function getMyNodeNum() {
        return _myNodeNum;
    }

    function isConfigComplete() {
        return _configComplete;
    }

    function getUnreadCount() {
        return _unreadCount;
    }

    // Mark all messages as read
    function markAllAsRead() {
        for (var i = 0; i < _messages.size(); i++) {
            _messages[i][:read] = true;
        }
        _unreadCount = 0;
    }

    // Mark a specific message as read
    function markMessageAsRead(messageId) {
        for (var i = 0; i < _messages.size(); i++) {
            if (_messages[i][:id] == messageId) {
                if (!_messages[i][:read]) {
                    _messages[i][:read] = true;
                    _unreadCount--;
                    if (_unreadCount < 0) {
                        _unreadCount = 0;
                    }
                }
                break;
            }
        }
    }

    // ============================================
    // UTILITY FUNCTIONS
    // ============================================

    // Convert ByteArray to String
    private function bytesToString(bytes) {
        if (bytes == null) {
            return "";
        }

        if (bytes instanceof Lang.String) {
            return bytes;
        }

        if (!(bytes instanceof Lang.ByteArray)) {
            return "";
        }

        var str = "";
        for (var i = 0; i < bytes.size(); i++) {
            var byte = bytes[i];
            if (byte == 0) {
                break; // Stop at null terminator
            }
            str += byte.toChar();
        }
        return str;
    }
}
