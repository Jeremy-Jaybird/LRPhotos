#!/usr/bin/env bash
cd "$(dirname "$0")"
export SCRIPT_DIR="$(pwd)"

PLUGIN_NAME="LRPhotos"
LR_MODULES_DIR="$HOME/Library/Application Support/Adobe/Lightroom/Modules"
SCRIPT_LIBRARIES_DIR="$HOME/Library/Script Libraries"
SERVICES_DIR="$HOME/Library/Services"

echo "Installing $PLUGIN_NAME..."

# Create directories if they don't exist
mkdir -p "$LR_MODULES_DIR"
mkdir -p "$SCRIPT_LIBRARIES_DIR"
mkdir -p "$SERVICES_DIR"

# Remove old plugin if it exists
if [ -d "$LR_MODULES_DIR/$PLUGIN_NAME.lrplugin" ]; then
    echo "Removing old plugin..."
    rm -rf "$LR_MODULES_DIR/$PLUGIN_NAME.lrplugin"
fi

# Copy plugin
echo "Copying plugin to $LR_MODULES_DIR..."
cp -R "$SCRIPT_DIR/src/main/lrphotos.lrdevplugin" "$LR_MODULES_DIR/$PLUGIN_NAME.lrplugin"

# Copy AppleScript libraries
echo "Copying AppleScript libraries to $SCRIPT_LIBRARIES_DIR..."
cp -R "$SCRIPT_DIR/Script Libraries/"* "$SCRIPT_LIBRARIES_DIR/"

# Copy Services
echo "Copying Services to $SERVICES_DIR..."
cp -R "$SCRIPT_DIR/Services/"* "$SERVICES_DIR/"

echo "Done! Restart Lightroom Classic to use the plugin."
