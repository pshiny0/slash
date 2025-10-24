#!/bin/bash

# Fix icon format by re-exporting with proper PNG settings

SOURCE_DIR="/Users/shinypidugu/Projects/Slash/Resources/icons/app-icon"
TARGET_DIR="/Users/shinypidugu/Projects/Slash/AppIcons"

ICONS=(
    "blueprint"
    "blueprint-echo"
    "graphite"
    "graphite-echo"
    "lumen-black"
    "lumen-blue"
    "studio-black"
    "studio-blue"
    "wireframe-black"
    "wireframe-blue"
)

echo "Recreating all icons with proper PNG format..."

for icon in "${ICONS[@]}"; do
    echo "Processing $icon..."
    
    # Base (60x60) - use sipsexport with proper PNG settings
    sips -s format png -z 60 60 "$SOURCE_DIR/${icon}.png" --out "$TARGET_DIR/AppIcon-${icon}.png" 2>/dev/null
    
    # @2x (120x120)
    sips -s format png -z 120 120 "$SOURCE_DIR/${icon}.png" --out "$TARGET_DIR/AppIcon-${icon}@2x.png" 2>/dev/null
    
    # @3x (180x180)  
    sips -s format png -z 180 180 "$SOURCE_DIR/${icon}.png" --out "$TARGET_DIR/AppIcon-${icon}@3x.png" 2>/dev/null
    
    # Verify the files were created
    if [ -f "$TARGET_DIR/AppIcon-${icon}.png" ]; then
        echo "  ✓ Created 60x60, 120x120, 180x180 for $icon"
    else
        echo "  ✗ FAILED to create $icon"
    fi
done

echo ""
echo "Done! All icons recreated."
echo ""
echo "File listing:"
ls -lh "$TARGET_DIR"/*.png | grep -v "@" | head -10

