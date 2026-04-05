#!/bin/bash
set -e

APP_NAME="TermGrid"
BUILD_DIR="$(pwd)/.build/release"
APP_DIR="$(pwd)/build/${APP_NAME}.app/Contents"

swift build -c release

mkdir -p "${APP_DIR}/MacOS"
mkdir -p "${APP_DIR}/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_DIR}/MacOS/${APP_NAME}"
cp "Resources/AppIcon.icns" "${APP_DIR}/Resources/AppIcon.icns"

cat > "${APP_DIR}/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>TermGrid</string>
    <key>CFBundleIdentifier</key>
    <string>com.termgrid.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>TermGrid</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
PLIST

chmod +x "${APP_DIR}/MacOS/${APP_NAME}"

echo "Built: build/${APP_NAME}.app"
echo "Run with: open build/${APP_NAME}.app"
