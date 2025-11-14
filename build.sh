#!/bin/bash
# Build script for Meshtastic Garmin Watch app

set -e

echo "Creating build directory..."
mkdir -p build

echo "Building DEVICE version for fenix8solar51mm..."
monkeyc \
  -o build/meshtastic.prg \
  -f monkey.jungle \
  -d fenix8solar51mm \
  -y developer_key \
  -w

echo ""
echo "✅ Device build complete! Output: build/meshtastic.prg"
echo ""

echo "Building SIMULATOR version for fenix8solar51mm (with mock BLE)..."
monkeyc \
  -o build/meshtastic-sim.prg \
  -f simulator.jungle \
  -d fenix8solar51mm \
  -y developer_key \
  -w

echo ""
echo "✅ Simulator build complete! Output: build/meshtastic-sim.prg"
echo ""
echo "=========================================="
echo "Build Summary:"
echo "  Device build:    build/meshtastic.prg     (real BLE)"
echo "  Simulator build: build/meshtastic-sim.prg (mock BLE, won't crash)"
echo "=========================================="
echo ""
echo "To run simulator build (recommended for testing UI):"
echo "  connectiq build/meshtastic-sim.prg &"
echo "  # Simulator will start with mock BLE, no crashes!"
echo ""
echo "To deploy to real watch (connect via USB):"
echo "  monkeydo build/meshtastic.prg fenix8solar51mm"
echo ""
echo "Watch simulator output for detailed logs!"
