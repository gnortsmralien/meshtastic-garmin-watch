# Connect IQ Device Files

This directory contains device-specific files needed for compilation.

## Setup

To add your device files:

1. On macOS, device files are located at:
   ```
   ~/Library/Application Support/Garmin/ConnectIQ/Devices/
   ```

2. Copy the device folder(s) you need (e.g., `fenix8solar51mm`) to this directory.

3. Each device folder should contain:
   - `compiler.json` - Device-specific compiler settings
   - `simulator.json` - Simulator configuration

## Required Devices

For this project, we need:
- `fenix8solar51mm/`

## License

These device files are provided by Garmin as part of the Connect IQ SDK.
Check the SDK license agreement for usage terms.
