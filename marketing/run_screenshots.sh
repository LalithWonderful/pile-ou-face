#!/bin/bash
set -euo pipefail

# =============================================================================
# Marketing Screenshot Generator — Real Card Artwork (iOS Simulator)
# =============================================================================
# Prerequisites:
#   - iOS Simulator booted (e.g. iPhone 17)
#   - dart & flutter in PATH
#
# What it does:
#   1. Starts a tiny HTTP server on localhost:8765
#   2. Runs the integration test on the iOS simulator
#   3. The test captures 44 screenshots and POSTs them to the server
#   4. Stops the server when done
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/marketing/screenshots/daily_message"

cd "$PROJECT_ROOT"

# Clean previous screenshots
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*.png

# Start the screenshot receiver server in the background
dart marketing/screenshot_server.dart &
SERVER_PID=$!

# Ensure the server is killed on script exit
cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT

# Give the server a moment to bind
sleep 1

# Run the integration test on the iOS simulator
flutter test -d '1477886C-951C-42B9-B923-CAE6BD0329AC' integration_test/marketing_screenshots_test.dart

echo ""
echo "✅ Screenshots saved to: $OUTPUT_DIR"
ls -1 "$OUTPUT_DIR"
