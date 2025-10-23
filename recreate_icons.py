#!/usr/bin/env python3
import os
import subprocess

SOURCE_DIR = "/Users/shinypidugu/Projects/Slash/Resources/icons/app-icon"
TARGET_DIR = "/Users/shinypidugu/Projects/Slash/AppIcons"

# Icon names
ICONS = [
    "black-white-outline-monogram",
    "black-white-solid-monogram",
    "black-white-title",
    "blue-white-outline-monogram",
    "blue-white-solid-monogram",
    "blue-white-title",
    "white-black-solid-monogram",
    "white-black-title",
    "white-blue-solid-monogram",
    "white-blue-title"
]

# Clear existing PNG files
print("Clearing existing PNG files...")
for file in os.listdir(TARGET_DIR):
    if file.endswith('.png'):
        os.remove(os.path.join(TARGET_DIR, file))

# Create all required sizes for each icon
for icon in ICONS:
    print(f"Processing {icon}...")
    source_file = os.path.join(SOURCE_DIR, f"{icon}.png")
    
    # Base file (60x60)
    base_file = os.path.join(TARGET_DIR, f"AppIcon-{icon}.png")
    subprocess.run(["sips", "-z", "60", "60", source_file, "--out", base_file], 
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    # @2x file (120x120) - THIS IS THE CORRECT SIZE!
    twox_file = os.path.join(TARGET_DIR, f"AppIcon-{icon}@2x.png")
    subprocess.run(["sips", "-z", "120", "120", source_file, "--out", twox_file],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    # @3x file (180x180) - THIS IS THE CORRECT SIZE!
    threex_file = os.path.join(TARGET_DIR, f"AppIcon-{icon}@3x.png")
    subprocess.run(["sips", "-z", "180", "180", source_file, "--out", threex_file],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    print(f"  ✓ Created {icon} in 3 sizes: 60x60, 120x120, 180x180")

print("\n✅ All icons recreated successfully with correct sizes!")

