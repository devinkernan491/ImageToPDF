#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🔨 Building ImageToPDF..."
mkdir -p .build/cache

swiftc -module-cache-path .build/cache \
    -parse-as-library \
    -O \
    Sources/ImageToPDF/Models/*.swift \
    Sources/ImageToPDF/Services/*.swift \
    Sources/ImageToPDF/Views/*.swift \
    Sources/ImageToPDF/App.swift \
    -o .build/ImageToPDF

echo "📦 Packaging ImageToPDF.app bundle..."
APP_BUNDLE="ImageToPDF.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp .build/ImageToPDF "$APP_BUNDLE/Contents/MacOS/ImageToPDF"
chmod +x "$APP_BUNDLE/Contents/MacOS/ImageToPDF"

# Copy Icon
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Write Info.plist
cat << 'EOF' > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>ImageToPDF</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.antigravity.ImageToPDF</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>ImageToPDF</string>
    <key>CFBundleDisplayName</key>
    <string>Image to PDF</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Supported Files</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.image</string>
                <string>public.jpeg</string>
                <string>public.png</string>
                <string>public.heic</string>
                <string>public.tiff</string>
                <string>public.source-code</string>
                <string>public.plain-text</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

echo "✅ Successfully built $APP_BUNDLE!"

if [ "$1" == "--install" ]; then
    echo "🚀 Installing to /Applications..."
    rm -rf "/Applications/$APP_BUNDLE"
    cp -R "$APP_BUNDLE" "/Applications/"
    echo "🎉 Installed to /Applications/$APP_BUNDLE!"
fi

echo ""
echo "To run the app:"
echo "  open \"$DIR/$APP_BUNDLE\""
echo "To install to your Applications folder:"
echo "  $0 --install"
