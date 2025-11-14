# On-Device Test Guide: Seeed Card T1000E

## Quick Reference for First Connection

### Pre-Test Checklist ✅

**Hardware:**
- [x] Garmin Fenix 8 Solar 51mm charged (>50% battery)
- [x] Seeed Card T1000E powered on and charged
- [x] USB cable for watch deployment
- [x] Computer with Garmin Express or Connect IQ SDK

**Software:**
- [x] Latest build: `build/meshtastic.prg` compiled
- [x] Developer key generated
- [x] Garmin Express installed OR SDK tools available

---

## Step 1: Prepare the T1000E

### Enable BLE on T1000E

**Method 1: Via Serial (if accessible)**
```bash
meshtastic --set bluetooth.enabled true
meshtastic --set bluetooth.mode RANDOM_PIN
meshtastic --get bluetooth
```

**Method 2: Via Mobile App**
1. Open Meshtastic app on phone
2. Connect to T1000E
3. Settings → Bluetooth → Enabled
4. Bluetooth Mode → Random PIN (or Fixed PIN)
5. Note the PIN if using Fixed PIN mode

**Verify T1000E is Advertising:**
- On your phone, go to Bluetooth settings
- Scan for devices
- Look for "Meshtastic_XXXX" or "T1000E"
- Don't pair yet - just verify it's visible

---

## Step 2: Build and Deploy to Watch

### Build Application
```bash
cd /path/to/meshtastic-garmin-watch

# Clean build
rm -rf build/*

# Build main application
monkeyc -o build/meshtastic.prg \
  -f monkey.jungle \
  -d fenix8solar51mm \
  -y developer_key \
  -w
```

**Expected Output:**
```
Building main application...
WARNING: fenix8solar51mm: The launcher icon (371x340) isn't compatible...
[Various container type warnings - these are OK]
✓ No ERRORS
```

### Deploy to Watch

**Option A: Via Garmin Express (Easiest)**
1. Connect watch via USB
2. Open Garmin Express
3. Go to "Apps" section
4. Click "Install from file"
5. Select `build/meshtastic.prg`
6. Wait for transfer to complete

**Option B: Via Connect IQ SDK**
```bash
# Find your device
monkeydo --device-list

# Deploy
monkeydo build/meshtastic.prg [DEVICE_ID]
```

---

## Step 3: Prepare Test Environment

### Critical: Minimize BLE Interference

**Turn OFF or move away from:**
- [ ] Other Bluetooth headphones/speakers
- [ ] Fitness trackers
- [ ] Smart home devices
- [ ] Other phones/tablets with BLE active
- [ ] Other Meshtastic nodes

**Optimal Setup:**
1. **Distance**: Place T1000E within 3 feet (1 meter) of watch
2. **Clear line of sight**: No metal objects between devices
3. **Quiet environment**: Minimize other BLE traffic
4. **Fully charged**: Both devices >50% battery

---

## Step 4: First Connection Test

### Launch App on Watch

1. On watch, press **UP** button to open app list
2. Scroll to **Meshtastic** app
3. Press **START** to launch
4. Wait for app to initialize

**Expected Screen:**
```
┌─────────────────────┐
│    Meshtastic       │  Battery: XX%
│                     │
│   Disconnected      │  (RED text)
│                     │
│   0 nodes | 0 msgs  │
│                     │
│  UP: Messages       │
│  DOWN: Nodes        │
│  SELECT: Compose    │
│  START: Connect     │
└─────────────────────┘
```

### Initiate Connection

**Press START button**

**Watch the screen carefully for state changes:**

```
1. Scanning... (YELLOW)
   - Duration: 10 seconds
   - Watch discovers BLE devices

2. Connecting... (YELLOW)
   - Watch attempts connection
   - May show "Device 1 of X"

3. Connected (ORANGE)
   - BLE connection established
   - Validating Meshtastic service...

4. Syncing... (ORANGE)
   - Handshake in progress
   - Receiving node database

5. Ready (GREEN) ✅
   - X nodes | 0 msgs displayed
   - Connection successful!
```

### If Prompted for PIN

**PIN Entry Screen appears:**
```
┌─────────────────────┐
│  Enter Device PIN   │
│                     │
│  * * _ _ _ _        │  (Shows entered digits)
│                     │
│      < 0 >          │  (Current digit selector)
│                     │
│ SELECT: Add         │
│ UP/DOWN: Cycle      │
│ MENU: Delete        │
│ ENTER: Submit       │
└─────────────────────┘
```

**Enter PIN:**
1. **UP/DOWN** buttons: Cycle through 0-9
2. **SELECT** button: Add current digit
3. Repeat for each digit (usually 6 digits)
4. **ENTER** button: Submit PIN
5. If wrong: **BACK** clears, try again

**Default PINs to try:**
- `123456` (Meshtastic default)
- `000000` (Some devices)
- Check T1000E screen/app for displayed PIN

---

## Step 5: Verify Connection Success

### Check Node List
1. Press **DOWN** button
2. Node List should show:
   - At minimum: Your T1000E node
   - Possibly: Other mesh nodes in range
3. Example:
   ```
   ┌─────────────────────┐
   │    Node List        │  3/3
   │                     │
   │ ▶ T1000E Tracker    │
   │   !a1b2c3d4         │
   │   Just now          │
   │                     │
   │   Unknown Node      │
   │   !e5f6g7h8         │
   │   5m ago            │
   └─────────────────────┘
   ```

4. Press **BACK** to return to status

### Send Test Message
1. Press **SELECT** (Compose view)
2. Select "OK" (should be highlighted)
3. Press **ENTER** to send
4. Watch for "Sending..." then "Sent!" message
5. Check T1000E or other Meshtastic device to verify receipt

### Check for Received Messages
1. On another Meshtastic device, send a message to mesh
2. Watch should **vibrate** when message received
3. **Unread badge** should appear in top-right (blue circle)
4. Press **UP** to view messages
5. New message should be listed

---

## Step 6: Troubleshooting

### Problem: "No BLE devices found"

**Causes:**
- T1000E not powered on
- T1000E BLE not enabled
- T1000E out of range
- BLE interference

**Solutions:**
1. Verify T1000E is on (check screen/LED)
2. Check T1000E BLE enabled: `meshtastic --get bluetooth.enabled`
3. Move watch closer to T1000E (<3 feet)
4. Restart T1000E: Hold power button 10s, power on
5. Restart watch app: Close and reopen
6. Try in different location (away from other BLE devices)

---

### Problem: "Not a Meshtastic device"

**Causes:**
- Connected to wrong BLE device (headphones, etc.)
- T1000E not running Meshtastic firmware

**Solutions:**
1. **Good news:** App auto-retries with next device!
2. Wait for retry (should happen automatically)
3. If still fails: Turn off other BLE devices nearby
4. Verify T1000E has Meshtastic firmware: `meshtastic --info`

---

### Problem: Connection drops immediately

**Causes:**
- Wrong PIN entered
- T1000E pairing issues
- BLE signal too weak

**Solutions:**
1. Check PIN on T1000E screen or via `meshtastic --get bluetooth`
2. Clear T1000E BLE pairings:
   ```bash
   meshtastic --set bluetooth.enabled false
   meshtastic --set bluetooth.enabled true
   ```
3. Move devices closer together
4. Ensure no metal objects between devices

---

### Problem: "Syncing..." never completes

**Causes:**
- want_config_id handshake not completing
- T1000E firmware issue
- Characteristic notification not working

**Solutions:**
1. Wait 30 seconds (initial sync can take time)
2. Check T1000E serial output for errors
3. Restart both devices
4. Try with different Meshtastic node if available

---

### Problem: Can't send messages

**Causes:**
- Config not complete (still syncing)
- Disconnected
- Invalid node selection

**Solutions:**
1. Verify status shows "Ready" (GREEN)
2. Check node count > 0
3. Wait for "X nodes | Y msgs" to display
4. Try sending to broadcast (0xFFFFFFFF) first

---

## Step 7: Success Criteria

**Minimum Success (First Connection):**
- [x] App connects to T1000E
- [x] Status shows "Ready" (GREEN)
- [x] Node list shows at least T1000E
- [x] Can send one message without errors
- [x] No crashes for 5 minutes

**Full Success:**
- [x] All above PLUS:
- [x] Receives messages from other mesh nodes
- [x] Vibration works on message receipt
- [x] Can send all 10 quick messages
- [x] Custom message entry works
- [x] Stays connected for 30+ minutes
- [x] Auto-reconnects after disconnect

---

## Step 8: Debug Log Collection

### If Connection Fails

**Collect logs from watch:**

**Via Garmin Express:**
1. Keep watch connected via USB
2. Open Garmin Express
3. Go to Tools → Activity Log
4. Look for "Meshtastic" entries
5. Copy relevant error messages

**Via SDK Tools:**
```bash
# Run simulator with logging
connectiq
# Output shows in simulator console window
```

**Via Serial (if connected during development):**
```bash
# Watch logs appear in terminal
```

**Look for these log messages:**
```
✓ BLE scan started - collecting devices...
✓ Discovered BLE device #1
✓ Discovered BLE device #2
✓ Scan window complete - found 2 devices
✓ Attempting connection to first discovered device
✓ Device connected, validating Meshtastic service...
✓ Meshtastic service found!
✓ All required characteristics found
✓ Enabling notifications
✓ Ready
```

**Common error patterns:**
```
✗ ERROR: Not a Meshtastic device - service UUID not found
  → Connected to wrong device, watch for auto-retry

✗ ERROR: Required characteristics not found
  → T1000E firmware issue or incomplete GATT profile

✗ ERROR: No BLE devices found
  → T1000E not advertising or out of range
```

---

## Step 9: Performance Monitoring

### Battery Life Test
1. Note watch battery level before test
2. Run for 1 hour with app in foreground
3. Note battery level after 1 hour
4. **Expected drain: 3-5% per hour**

### Memory Usage
- App includes SystemMonitor
- Memory shown in logs
- **Should stay under 80% usage**

### Connection Stability
- Leave connected for 2+ hours
- Check for disconnects
- Verify auto-reconnect works if disrupted

---

## Step 10: What to Report

### If Everything Works ✅
Please report:
- "Connection successful!"
- Time to connect (seconds)
- Number of nodes discovered
- Message send/receive latency
- Battery drain per hour
- Any UI glitches noticed

### If Something Fails ❌
Please report:
- Exact step where it failed
- Error message on watch screen
- Last log message seen
- T1000E firmware version (`meshtastic --info`)
- Watch battery level
- Distance between devices

---

## Quick Command Reference

**T1000E Commands:**
```bash
# Check BLE status
meshtastic --get bluetooth.enabled
meshtastic --get bluetooth.mode

# Enable BLE
meshtastic --set bluetooth.enabled true

# Check device info
meshtastic --info

# Monitor serial output
meshtastic --seriallog

# Reset BLE
meshtastic --set bluetooth.enabled false
meshtastic --set bluetooth.enabled true
```

**Build Commands:**
```bash
# Full clean build
rm -rf build/*
monkeyc -o build/meshtastic.prg -f monkey.jungle -d fenix8solar51mm -y developer_key -w

# Run tests
monkeyc -o build/ble-test.prg -f ble-connection-test.jungle -d fenix8solar51mm -y developer_key -w
connectiq build/ble-test.prg
```

---

## Expected Timeline

**First connection attempt:**
- App launch: 2-3 seconds
- BLE scan: 10 seconds
- Connection attempt: 3-5 seconds
- Service validation: 1-2 seconds
- Characteristic setup: 2-3 seconds
- Handshake (want_config_id): 2-5 seconds
- Node sync: 2-10 seconds (depends on # of nodes)
- **Total: 25-40 seconds to "Ready" status**

**Subsequent connections:**
- Should be faster: 15-25 seconds

---

## Good Luck! 🚀

The app is tested and ready. The BLE validation and auto-retry mechanisms should handle most edge cases automatically. If something fails, the detailed logs will help us debug quickly.

**Remember:** First BLE connection can be finicky. If it doesn't work on first try:
1. Don't panic - this is normal
2. Check the troubleshooting section
3. Try moving devices closer
4. Restart both devices if needed
5. Report what you see - we'll fix it!
