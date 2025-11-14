// ViewManager.mc
//
// Manages navigation between different views in the app
// Handles view stack, transitions, and input delegation

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;

class ViewManager {
    enum ViewType {
        VIEW_STATUS,
        VIEW_MESSAGE_LIST,
        VIEW_NODE_LIST,
        VIEW_COMPOSE,
        VIEW_CUSTOM_MESSAGE,
        VIEW_PIN_ENTRY,
        VIEW_MESSAGE_DETAIL
    }

    private var _currentView = null;
    private var _currentDelegate = null;
    private var _bleManager;
    private var _messageHandler;
    private var _systemMonitor;
    private var _reconnectManager;
    private var _settingsManager;

    function initialize(bleManager, messageHandler, systemMonitor, reconnectManager, settingsManager) {
        System.println(">>> ViewManager.initialize() START");
        _bleManager = bleManager;
        _messageHandler = messageHandler;
        _systemMonitor = systemMonitor;
        _reconnectManager = reconnectManager;
        _settingsManager = settingsManager;
        System.println(">>> ViewManager.initialize() COMPLETE");
    }

    // Show the main status view
    function showStatusView() {
        var view = new StatusView(_bleManager, _messageHandler, self, _systemMonitor, _reconnectManager);
        var delegate = new StatusViewDelegate(view, self);
        pushView(view, delegate);
    }

    // Show message list view
    function showMessageListView() {
        var view = new MessageListView(_messageHandler, self);
        var delegate = new MessageListViewDelegate(view, self);
        pushView(view, delegate);
    }

    // Show node list view
    function showNodeListView() {
        var view = new NodeListView(_messageHandler, self);
        var delegate = new NodeListViewDelegate(view, self);
        pushView(view, delegate);
    }

    // Show compose view
    function showComposeView() {
        var view = new ComposeView(_bleManager, _messageHandler, self);
        var delegate = new ComposeViewDelegate(view, self);
        pushView(view, delegate);
    }

    // Show custom message view
    function showCustomMessageView() {
        var view = new CustomMessageView(_bleManager, _messageHandler, self);
        var delegate = new CustomMessageViewDelegate(view, self);
        pushView(view, delegate);
    }

    // Show PIN entry view
    function showPinEntryView(callback) {
        var view = new PinEntryView(callback);
        var delegate = new PinEntryViewDelegate(view);
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_UP);
    }

    // Show settings view
    function showSettingsView() {
        var view = new SettingsView(_settingsManager, self);
        var delegate = new SettingsViewDelegate(view, self);
        pushView(view, delegate);
    }

    // Go back to previous view
    function goBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    // Push a new view onto the stack
    private function pushView(view, delegate) {
        _currentView = view;
        _currentDelegate = delegate;
        WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
    }

    // Get current view
    function getCurrentView() {
        return _currentView;
    }
}
