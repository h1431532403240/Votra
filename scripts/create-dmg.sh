#!/bin/bash
# Create DMG for Votra distribution
#
# Usage: ./scripts/create-dmg.sh <app_path> <version> <output_dir> [signing_identity]
#
# Arguments:
#   app_path         - Path to the Votra.app bundle
#   version          - Version string (e.g., 1.0.0)
#   output_dir       - Directory for output DMG
#   signing_identity - Optional: Developer ID Application identity for signing
#
# Example:
#   ./scripts/create-dmg.sh build/export/Votra.app 1.0.0 build "Developer ID Application"

set -euo pipefail

# Arguments
APP_PATH="${1:-}"
VERSION="${2:-}"
OUTPUT_DIR="${3:-}"
SIGNING_IDENTITY="${4:-}"

# Validate arguments
if [[ -z "$APP_PATH" || -z "$VERSION" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage: $0 <app_path> <version> <output_dir> [signing_identity]"
    echo ""
    echo "Example:"
    echo "  $0 build/export/Votra.app 1.0.0 build \"Developer ID Application\""
    exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

# Create output directory if needed
mkdir -p "$OUTPUT_DIR"

DMG_NAME="Votra-$VERSION.dmg"
TEMP_DMG="$OUTPUT_DIR/temp.dmg"
FINAL_DMG="$OUTPUT_DIR/$DMG_NAME"
VOLUME_NAME="Votra"
MOUNT_POINT="/Volumes/$VOLUME_NAME"

echo "Creating DMG: $DMG_NAME"
echo "  App: $APP_PATH"
echo "  Output: $FINAL_DMG"

# Cleanup any existing mount
if [[ -d "$MOUNT_POINT" ]]; then
    echo "Cleaning up existing mount..."
    hdiutil detach "$MOUNT_POINT" 2>/dev/null || true
fi

# Remove existing temp DMG
rm -f "$TEMP_DMG" "$FINAL_DMG"

# Calculate app size and add buffer
APP_SIZE_MB=$(du -sm "$APP_PATH" | cut -f1)
DMG_SIZE_MB=$((APP_SIZE_MB + 50))  # 50MB buffer for symlink and filesystem overhead
echo "  App size: ${APP_SIZE_MB}MB, DMG size: ${DMG_SIZE_MB}MB"

# Create temporary writable DMG
echo "Creating temporary DMG..."
hdiutil create -size "${DMG_SIZE_MB}m" -fs HFS+ -volname "$VOLUME_NAME" "$TEMP_DMG"

# Mount the DMG
echo "Mounting DMG..."
hdiutil attach "$TEMP_DMG" -mountpoint "$MOUNT_POINT"

# Copy app to DMG
echo "Copying app..."
cp -R "$APP_PATH" "$MOUNT_POINT/"

# Create Applications symlink
echo "Creating Applications symlink..."
ln -s /Applications "$MOUNT_POINT/Applications"

# Prevent Spotlight indexing
touch "$MOUNT_POINT/.metadata_never_index"

# Unmount with retry (handles EBUSY from Spotlight/XProtect)
echo "Unmounting..."
for i in {1..5}; do
    if hdiutil detach "$MOUNT_POINT"; then
        break
    fi
    echo "  Retry $i: waiting for volume to be released..."
    sleep $((i * 2))
done

# Convert to compressed ULFO format (LZFSE compression - optimal for macOS 10.11+)
echo "Converting to compressed format (ULFO/LZFSE)..."
hdiutil convert "$TEMP_DMG" -format ULFO -o "$FINAL_DMG"

# Remove temporary DMG
rm -f "$TEMP_DMG"

# Sign DMG if signing identity provided
if [[ -n "$SIGNING_IDENTITY" ]]; then
    echo "Signing DMG with: $SIGNING_IDENTITY"
    codesign -s "$SIGNING_IDENTITY" --timestamp "$FINAL_DMG"
fi

# Show final DMG info
echo ""
echo "✅ DMG created successfully:"
ls -lh "$FINAL_DMG"
echo ""
echo "SHA-256 checksum:"
shasum -a 256 "$FINAL_DMG"

# Verify if signed
if [[ -n "$SIGNING_IDENTITY" ]]; then
    echo ""
    echo "Code signature verification:"
    codesign -dv "$FINAL_DMG" 2>&1 || true
fi
