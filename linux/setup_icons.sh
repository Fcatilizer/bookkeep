#!/bin/bash

# Linux Icon Setup Script for BookKeep
# This script properly installs icons for GNOME/GTK integration

echo "Setting up BookKeep icons for Linux desktop integration..."

# Create icon directories
mkdir -p ~/.local/share/icons/hicolor/{16x16,32x32,48x48,64x64,128x128,256x256,512x512}/apps
mkdir -p ~/.local/share/pixmaps

# Copy the main icon to pixmaps (fallback location)
if [ -f "assets/icon.png" ]; then
    cp assets/icon.png ~/.local/share/pixmaps/bookkeep.png
    echo "✓ Copied icon to pixmaps"
else
    echo "✗ assets/icon.png not found!"
    exit 1
fi

# Create different sizes for hicolor theme
# Using ImageMagick to resize (install with: sudo apt install imagemagick)
if command -v convert &> /dev/null; then
    echo "Creating different icon sizes..."
    convert assets/icon.png -resize 16x16 ~/.local/share/icons/hicolor/16x16/apps/bookkeep.png
    convert assets/icon.png -resize 32x32 ~/.local/share/icons/hicolor/32x32/apps/bookkeep.png
    convert assets/icon.png -resize 48x48 ~/.local/share/icons/hicolor/48x48/apps/bookkeep.png
    convert assets/icon.png -resize 64x64 ~/.local/share/icons/hicolor/64x64/apps/bookkeep.png
    convert assets/icon.png -resize 128x128 ~/.local/share/icons/hicolor/128x128/apps/bookkeep.png
    convert assets/icon.png -resize 256x256 ~/.local/share/icons/hicolor/256x256/apps/bookkeep.png
    cp assets/icon.png ~/.local/share/icons/hicolor/512x512/apps/bookkeep.png
    echo "✓ Created multiple icon sizes"
else
    echo "⚠ ImageMagick not found. Installing just the main icon..."
    cp assets/icon.png ~/.local/share/icons/hicolor/512x512/apps/bookkeep.png
fi

# Install desktop file
cp linux/bookkeep.desktop ~/.local/share/applications/
echo "✓ Installed desktop file"

# Update icon cache
if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache ~/.local/share/icons/hicolor
    echo "✓ Updated icon cache"
fi

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database ~/.local/share/applications
    echo "✓ Updated desktop database"
fi

echo ""
echo "🎉 Icon setup complete!"
echo ""
echo "To test:"
echo "1. Build: flutter build linux"
echo "2. Run: flutter run -d linux"
echo "3. Check Activities/Applications menu for BookKeep"
echo ""
echo "If the icon still doesn't appear in the dock:"
echo "• Try logging out and back in"
echo "• Or run: killall nautilus && nautilus & (to restart file manager)"
echo "• Check that the window class matches in desktop file"