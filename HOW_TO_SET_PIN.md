# How to Set Your T1000E PIN in the App

## Quick Setup

The default PIN is already configured in the app. If your T1000E uses the standard Meshtastic PIN `123456`, **you don't need to change anything**.

If your T1000E uses a different PIN, follow the steps below.

---

## Step 1: Find Your T1000E PIN

### Method 1: Via Meshtastic CLI
```bash
# Connect T1000E via USB
meshtastic --get bluetooth.fixed_pin
```

Output example:
```
bluetooth.fixed_pin: 654321
```

### Method 2: Check T1000E Screen
- Turn on T1000E
- Navigate to Bluetooth settings
- PIN should be displayed on screen

### Method 3: Via Meshtastic Mobile App
1. Open Meshtastic app on phone
2. Connect to T1000E
3. Settings → Bluetooth → View PIN

---

## Step 2: Update PIN in Code

**File:** `src/Config.mc`

**Line 33:**
```monkeyc
const DEFAULT_MESHTASTIC_PIN = "123456";  // ← CHANGE THIS if needed
```

**Change to your PIN:**
```monkeyc
const DEFAULT_MESHTASTIC_PIN = "654321";  // Your T1000E PIN
```

### Common PINs:
- `"123456"` - Default Meshtastic PIN (most devices)
- `"000000"` - Some devices use this
- `"111111"` - Sometimes used
- Custom - Check your specific device

---

## Step 3: Rebuild the App

```bash
# Clean previous build
rm -rf build/*

# Rebuild with new PIN
monkeyc -o build/meshtastic.prg \
  -f monkey.jungle \
  -d fenix8solar51mm \
  -y developer_key \
  -w
```

---

## Step 4: Deploy to Watch

Via Garmin Express:
1. Connect watch via USB
2. Open Garmin Express
3. Install `build/meshtastic.prg`

---

## How PIN Pairing Works

### Automatic PIN Usage
When the watch connects to your T1000E:

1. **BLE pairing request** is triggered
2. App **automatically uses** the configured PIN from `Config.mc`
3. **No user input needed** if PIN is correct
4. Connection proceeds automatically

### Manual PIN Entry (Fallback)
If automatic pairing fails, the app will show PIN entry screen:
- **UP/DOWN** buttons: Cycle through 0-9
- **SELECT**: Add digit
- **ENTER**: Submit PIN
- **BACK**: Clear and retry

---

## Advanced: Multiple Device Support

If you have multiple Meshtastic devices with different PINs:

### Option 1: Always Use Manual Entry
In `src/BleManager.mc`, line 187:
```monkeyc
// Force manual PIN entry
if (true) {  // Changed from: if (_pinCallback != null)
    _pinCallback.invoke(device, method(:onPinProvided));
} else {
    System.println("Using default PIN: " + _defaultPin);
    onPinProvided(_defaultPin);
}
```

### Option 2: Per-Device PIN Configuration
You could extend Config.mc to support multiple PINs:
```monkeyc
// In Config.mc
const PIN_MAP = {
    "T1000E" => "123456",
    "OtherDevice" => "654321"
};
```

---

## Troubleshooting PIN Issues

### Problem: "PIN entry cancelled"
**Cause:** System-level pairing timed out or wrong PIN entered

**Solution:**
1. Verify PIN in Config.mc matches T1000E
2. Rebuild and redeploy app
3. Clear Bluetooth pairings on watch
4. Try again

### Problem: Pairing still requests PIN
**Cause:** Garmin SDK limitation - `setPairingPasskey()` API not available

**Current Behavior:**
- App provides PIN to system
- System may still prompt for confirmation
- This is a platform limitation

**Workaround:**
- Use manual PIN entry UI
- Or ensure T1000E is already paired at system level

### Problem: Connection works but manual entry still appears
**Cause:** `onPairingRequest` callback being triggered even when not needed

**Solution:**
This is expected behavior. If PIN is correct, just press ENTER to skip.

---

## SDK Limitations

**Important Note:**
The Garmin Connect IQ SDK does not provide direct API to set Bluetooth pairing passkeys programmatically (no `Ble.setPairingPasskey()` method).

**What the app does:**
1. Stores your PIN in Config.mc
2. Provides PIN to system when requested
3. Shows manual entry UI as fallback

**What happens at OS level:**
- Garmin watch OS handles actual BLE pairing
- Our PIN is used as suggestion
- System may still require user confirmation

---

## Best Practice

**For Production Use:**
1. Test with default PIN first (`123456`)
2. If that fails, find your device's actual PIN
3. Update Config.mc
4. Rebuild and test
5. Document the PIN in your deployment notes

**For Development:**
- Keep default PIN for most devices
- Use manual entry UI for testing different devices
- Consider adding UI to change PIN without rebuilding

---

## Example: Setting Custom PIN

**Your T1000E PIN:** `987654`

**Edit `src/Config.mc`:**
```monkeyc
module Config {
    // ... other settings ...

    // ⚠️ CHANGED for my T1000E ⚠️
    const DEFAULT_MESHTASTIC_PIN = "987654";  // My T1000E PIN

    // ... rest of config ...
}
```

**Rebuild:**
```bash
rm -rf build/*
monkeyc -o build/meshtastic.prg -f monkey.jungle -d fenix8solar51mm -y developer_key -w
```

**Deploy and test!**

---

## Need Help?

If PIN pairing still doesn't work:
1. Check [ON_DEVICE_TEST_GUIDE.md](ON_DEVICE_TEST_GUIDE.md) for connection troubleshooting
2. Verify T1000E BLE is enabled: `meshtastic --get bluetooth.enabled`
3. Try clearing all Bluetooth pairings on watch
4. Report the issue with debug logs

The app has comprehensive logging - any pairing issues will be visible in the logs.
