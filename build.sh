#!/bin/bash
# Build script for Meshtastic Garmin Watch app

set -e

echo "Creating build directory..."
mkdir -p build

echo "Building main application for fenix8solar51mm..."
monkeyc \
  -o build/meshtastic.prg \
  -f monkey.jungle \
  -d fenix8solar51mm \
  -y developer_key \
  -w

echo ""
echo "✅ Build complete! Output: build/meshtastic.prg"
echo ""
echo "To run in simulator:"
echo "  monkeydo -d fenix8solar51mm -f build/meshtastic.prg"
echo ""
echo "To deploy to watch (connect via USB):"
echo "  monkeydo -d fenix8solar51mm -f build/meshtastic.prg"
