// NodeListView.mc
//
// Displays a scrollable list of known nodes on the mesh

using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

class NodeListView extends WatchUi.View {
    private var _messageHandler;
    private var _viewManager;
    private var _scrollIndex = 0;
    private var _itemsPerPage = 3;
    private var _nodeList = [];

    function initialize(messageHandler, viewManager) {
        View.initialize();
        _messageHandler = messageHandler;
        _viewManager = viewManager;
        buildNodeList();
    }

    function buildNodeList() {
        // Convert node dictionary to array for scrolling
        _nodeList = [];
        var nodes = _messageHandler.getNodes();
        var keys = nodes.keys();

        for (var i = 0; i < keys.size(); i++) {
            var nodeNum = keys[i];
            var nodeInfo = nodes[nodeNum];
            _nodeList.add(nodeInfo);
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var centerX = width / 2;

        // Title
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 10, Graphics.FONT_SMALL, "Nodes", Graphics.TEXT_JUSTIFY_CENTER);

        var nodeCount = _nodeList.size();

        if (nodeCount == 0) {
            // No nodes
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, dc.getHeight() / 2, Graphics.FONT_SMALL,
                       "No nodes yet", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(centerX, dc.getHeight() / 2 + 25, Graphics.FONT_TINY,
                       "Connect to sync", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            // Draw nodes
            var y = 45;
            var lineHeight = 60;

            // Calculate which nodes to show
            var startIdx = _scrollIndex;
            var endIdx = startIdx + _itemsPerPage;
            if (endIdx > nodeCount) {
                endIdx = nodeCount;
            }

            for (var i = startIdx; i < endIdx; i++) {
                var nodeInfo = _nodeList[i];
                drawNode(dc, nodeInfo, y, i == _scrollIndex);
                y += lineHeight;
            }

            // Scroll indicator
            if (nodeCount > _itemsPerPage) {
                var scrollText = (_scrollIndex + 1) + "/" + nodeCount;
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, dc.getHeight() - 40, Graphics.FONT_TINY,
                           scrollText, Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        // Instructions
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, dc.getHeight() - 20, Graphics.FONT_TINY,
                   "UP/DOWN: Scroll | BACK: Return", Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawNode(dc, nodeInfo, y, isSelected) {
        var centerX = dc.getWidth() / 2;

        // Highlight if selected
        if (isSelected) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            dc.fillRectangle(5, y - 5, dc.getWidth() - 10, 50);
        }

        // Node number
        var nodeNum = nodeInfo[:num];
        var nodeNumText = nodeNum.format("%08X");

        // Node name (from user info if available)
        var nodeName = "Unknown";
        if (nodeInfo.hasKey(:user)) {
            var user = nodeInfo[:user];
            if (user instanceof Lang.Dictionary && user.hasKey(:long_name)) {
                nodeName = bytesToString(user[:long_name]);
            }
        }

        // Truncate name if too long
        if (nodeName.length() > 20) {
            nodeName = nodeName.substring(0, 17) + "...";
        }

        // Draw node name
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_SMALL, nodeName, Graphics.TEXT_JUSTIFY_CENTER);

        // Draw node number
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y + 20, Graphics.FONT_TINY, nodeNumText, Graphics.TEXT_JUSTIFY_CENTER);

        // Last heard (if available)
        if (nodeInfo.hasKey(:last_heard)) {
            var lastHeard = nodeInfo[:last_heard];
            var lastHeardText = formatLastHeard(lastHeard);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y + 35, Graphics.FONT_XTINY, lastHeardText, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

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
                break;
            }
            str += byte.toChar();
        }
        return str;
    }

    private function formatLastHeard(timestamp) {
        var now = System.getTimer() / 1000;
        var diff = now - timestamp;

        if (diff < 60) {
            return "Just now";
        } else if (diff < 3600) {
            return (diff / 60) + "m ago";
        } else if (diff < 86400) {
            return (diff / 3600) + "h ago";
        } else {
            return (diff / 86400) + "d ago";
        }
    }

    function scrollUp() {
        if (_scrollIndex > 0) {
            _scrollIndex--;
            WatchUi.requestUpdate();
        }
    }

    function scrollDown() {
        if (_scrollIndex < _nodeList.size() - 1) {
            _scrollIndex++;
            WatchUi.requestUpdate();
        }
    }
}

class NodeListViewDelegate extends WatchUi.BehaviorDelegate {
    private var _view;
    private var _viewManager;

    function initialize(view, viewManager) {
        BehaviorDelegate.initialize();
        _view = view;
        _viewManager = viewManager;
    }

    // Handle UP button for scrolling (Fenix 8)
    function onPreviousPage() {
        _view.scrollUp();
        return true;
    }

    // Handle DOWN button for scrolling (Fenix 8)
    function onNextPage() {
        _view.scrollDown();
        return true;
    }

    // Handle BACK button
    function onBack() {
        _viewManager.goBack();
        return true;
    }

    // Legacy key handler for simulator compatibility
    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_UP) {
            return onPreviousPage();
        } else if (key == WatchUi.KEY_DOWN) {
            return onNextPage();
        } else if (key == WatchUi.KEY_ESC) {
            return onBack();
        }

        return false;
    }
}
