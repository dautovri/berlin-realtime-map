#!/bin/bash
# Berlin Transport Map - Build & Upload to TestFlight via asc
#
# Prerequisites:
# - Xcode command line tools installed
# - Signing configured for App Store distribution
# - `asc` installed + authenticated: https://github.com/rudrankriyam/App-Store-Connect-CLI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚌 Berlin Transport Map Build & Upload Script"
echo "=============================================="
echo ""

cd "$PROJECT_DIR"

if ! command -v asc >/dev/null 2>&1; then
    echo "❌ asc not found. Install with: brew install asc"
    exit 1
fi

SCHEME="BerlinTransportMap"
WORKSPACE="BerlinTransportMap.xcworkspace"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$SCHEME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"

APP_ID="${ASC_APP_ID:-6757723208}"
GROUP="${GROUP:-Internal}"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "📦 Building archive..."
xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    -allowProvisioningUpdates

echo "📤 Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$PROJECT_DIR/ExportOptions.plist"

IPA_PATH=$(ls -t "$EXPORT_PATH"/*.ipa 2>/dev/null | head -n 1 || true)
if [ -z "$IPA_PATH" ]; then
    echo "❌ No .ipa found in $EXPORT_PATH"
    exit 1
fi

echo "🚀 Uploading + distributing via asc..."
echo "   App ID: $APP_ID"
echo "   Group: $GROUP"
echo "   IPA: $IPA_PATH"

asc publish testflight \
    --app "$APP_ID" \
    --ipa "$IPA_PATH" \
    --group "$GROUP" \
    --wait \
    --notify

echo ""
echo "✅ Build process complete!"
