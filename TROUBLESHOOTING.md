# Troubleshooting Meshtastic Connection

## Issue: App doesn't detect Meshtastic device

If the app shows "Disconnected" and doesn't connect to your Meshtastic device when you press SELECT, follow these steps:

### 1. Check Meshtastic Device BLE Settings

On your Meshtastic device (phone app or device web interface):

- **Enable Bluetooth**: Make sure Bluetooth is turned on
- **Check BLE is enabled**: Go to Settings → Bluetooth → Enable
- **Make device discoverable**: Some Meshtastic devices need to be in pairing mode
- **Check PIN**: Default PIN is usually `123456` or blank. The app uses `123456` by default.
- **Unpair from other devices**: If the Meshtastic device is already paired with your phone, it might not be discoverable

### 2. Check Garmin Watch Permissions

- Go to watch Settings → System → Connectivity
- Ensure Bluetooth is enabled
- Check that the Meshtastic app has permission to use Bluetooth

### 3. What the App Does When Scanning

When you press SELECT to connect:

1. **Scan Phase** (10 seconds):
   - The watch scans for ALL nearby BLE devices
   - Collects a list of discovered devices
   - Shows "Scanning..." status message

2. **Connection Phase**:
   - Tries to connect to the first device found
   - Validates it has the Meshtastic service UUID: `6ba1b218-15a8-461f-9fa8-5dcae273eafd`
   - If not a Meshtastic device, tries the next one
   - Shows "Connecting..." then "Connected" or error message

3. **Validation**:
   - Checks for required Meshtastic BLE characteristics
   - If validated, shows "Ready"
   - Starts syncing node data

### 4. Common Issues

**No devices found:**
- Meshtastic device too far away (BLE range is ~10-30 feet)
- Meshtastic BLE is disabled
- Watch Bluetooth is off
- Interference from other devices

**Wrong device connected:**
- Multiple BLE devices nearby
- App connects to first device found
- The app will auto-retry other devices if the first isn't Meshtastic

**Connection fails:**
- PIN mismatch (default is `123456`)
- Meshtastic device already paired with another device
- BLE connection limit reached on watch or Meshtastic device

**Connected but no data:**
- Meshtastic device not on a mesh network
- No other nodes in range
- Node database empty

### 5. Diagnostic Steps

1. **Check Meshtastic device settings** (via phone app):
   ```
   Settings → Bluetooth → Enabled: ON
   Settings → Bluetooth → PIN: 123456
   ```

2. **Watch the status messages** on the watch:
   - "Disconnected" → Press SELECT
   - "Scanning..." → Wait 10 seconds
   - "Connecting..." → Device found, attempting connection
   - "Connected! Syncing..." → Success!
   - "No devices found" → Check step 1 above

3. **Try changing the PIN**:
   - Press MENU when disconnected
   - Select "Settings"
   - Navigate to "BLE PIN"
   - Press SELECT and enter your Meshtastic PIN

4. **Restart both devices**:
   - Restart your Garmin watch
   - Restart your Meshtastic device
   - Try connecting again

### 6. Viewing Logs

Since the app runs on the watch, you won't see System.println logs unless connected via USB to a computer with the simulator.

To debug connection issues:
- Connect watch via USB
- Use Garmin Express or Connect IQ app to view device logs
- Look for lines starting with ">>>" showing connection progress

### 7. Expected Behavior

**When working correctly:**
1. Press SELECT on main screen
2. Status changes to "Scanning..." (blue text)
3. After ~10 seconds: "Connecting..." (yellow)
4. "Connected! Syncing..." (orange)
5. Status shows "Ready" (green) with node count

**First sync can take 30-60 seconds** depending on:
- Number of nodes in the mesh
- Signal strength
- Mesh network activity

### 8. Meshtastic Service UUIDs

The app looks for these specific Bluetooth UUIDs:

- **Service**: `6ba1b218-15a8-461f-9fa8-5dcae273eafd`
- **ToRadio**: `f75c76d2-82c7-455b-9721-6b7538f49493`
- **FromRadio**: `26432193-4482-4648-b425-4c07c409e0e5`
- **FromNum**: `18cd4359-5506-4560-8d81-1b038a838e00`

If your Meshtastic firmware uses different UUIDs, the app won't connect.

### 9. Known Limitations

- Only connects to one Meshtastic device at a time
- 10-second scan window (may miss devices that appear later)
- Auto-selects first Meshtastic device found
- Cannot manually select from multiple Meshtastic devices
- PIN entry requires system keyboard (limited on watch)

### 10. Next Steps if Still Not Working

If you've tried everything above:

1. Check Meshtastic firmware version (app tested with v2.x)
2. Verify BLE is working with another BLE app on the watch
3. Try pairing Meshtastic with another Bluetooth device to confirm BLE works
4. Check Garmin Connect IQ forums for Fenix 8 BLE issues
5. File an issue on the GitHub repo with:
   - Meshtastic firmware version
   - Garmin watch model and firmware
   - Error messages seen
   - Steps already tried
