#!/usr/bin/env bash
#
# Collects Xcode test artifacts for upload:
#   - .xcresult bundles from DerivedData
#   - fastlane scan output (test_output / reports)
#   - failed snapshot images (*_FAILED.png)
#   - UI test recordings/screenshots (attachments) exported from .xcresult
#
# Usage: collect-test-results.sh <test-name>
set -euo pipefail

TEST_NAME="${1:?Usage: collect-test-results.sh <test-name>}"
WORKSPACE="${GITHUB_WORKSPACE:-$PWD}"

DEST="$WORKSPACE/test-results/$TEST_NAME"
mkdir -p "$DEST"

# Copy .xcresult bundles produced by the test run from DerivedData
find "$HOME/Library/Developer/Xcode/DerivedData" \
     -type d -name '*.xcresult' -exec cp -R {} "$DEST/" \; 2>/dev/null || true

# Also copy any fastlane scan output if the lane generated it
find "$WORKSPACE" -type d \( -iname 'test_output' -o -iname 'reports' \) \
     -exec cp -R {} "$DEST/" \; 2>/dev/null || true

# Collect failed snapshot images (e.g. Screenshots/HomeView/home_view.png_FAILED.png)
SNAP_DEST="$DEST/failed-snapshots"
mkdir -p "$SNAP_DEST"
find "$WORKSPACE" -type f -name '*_FAILED.png' \
     -exec cp -R {} "$SNAP_DEST/" \; 2>/dev/null || true

# Extract UI test recordings/screenshots (attachments) from .xcresult bundles
ATTACH_DEST="$DEST/ui-test-attachments"
mkdir -p "$ATTACH_DEST"
while IFS= read -r RESULT; do
  [ -z "$RESULT" ] && continue
  NAME="$(basename "$RESULT" .xcresult)"
  xcrun xcresulttool export attachments \
    --path "$RESULT" \
    --output-path "$ATTACH_DEST/$NAME" 2>/dev/null || true
done < <(find "$HOME/Library/Developer/Xcode/DerivedData" -type d -name '*.xcresult' 2>/dev/null)

# Prune empty helper dirs so if-no-files-found stays meaningful
rmdir "$SNAP_DEST" 2>/dev/null || true
rmdir "$ATTACH_DEST" 2>/dev/null || true

echo "Collected results in $DEST:"
ls -laR "$DEST" || true
