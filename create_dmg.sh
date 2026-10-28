#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Ensure app is built
if [ ! -d "ImageToPDF.app" ]; then
    echo "ImageToPDF.app not found. Building first..."
    ./build_app.sh
fi

echo "💿 Creating ImageToPDF.dmg..."
DMG_NAME="ImageToPDF.dmg"
STAGING_DIR="dmg_staging"

rm -rf "$STAGING_DIR" "$DMG_NAME"
mkdir -p "$STAGING_DIR"

cp -R "ImageToPDF.app" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "ImageToPDF" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_NAME"

rm -rf "$STAGING_DIR"

echo "✅ Successfully created $DMG_NAME ($(du -h "$DMG_NAME" | cut -f1))!"
