#!/bin/bash
# Berlin Transport Map - Build & Upload to TestFlight
# Current version: 1.0 (build 2) - Released
#
# Prerequisites:
# - Xcode command line tools installed
# - Valid signing certificates and provisioning profiles
# - fastlane configured (see fastlane/Fastfile)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚌 Berlin Transport Map Build & Upload Script"
echo "=============================================="
echo ""

cd "$PROJECT_DIR"

# Check if fastlane is available
if command -v fastlane &> /dev/null; then
    echo "Using fastlane for build..."
    fastlane beta
else
    echo "fastlane not found, using xcodebuild..."
    
    SCHEME="BerlinTransportMap"
    WORKSPACE="BerlinTransportMap.xcworkspace"
    BUILD_DIR="$PROJECT_DIR/build"
    ARCHIVE_PATH="$BUILD_DIR/$SCHEME.xcarchive"
    EXPORT_PATH="$BUILD_DIR/export"
    
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    
    xcodebuild archive \
        -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -destination "generic/platform=iOS" \
        -archivePath "$ARCHIVE_PATH" \
        -configuration Release
    
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$PROJECT_DIR/ExportOptions.plist"
    
    xcrun altool --upload-package "$EXPORT_PATH/$SCHEME.ipa" \
        --type ios \
        --apple-id "6757723208" \
        --bundle-id "com.ruslandautov.BerlinTransportMap"
fi

echo ""
echo "✅ Build process complete!"
