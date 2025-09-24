# Linux Icon Setup Guide

## Icon Files You Need

To properly set up icons for your BookKeep Linux application, you'll need the following icon files:

### 1. **Application Icon**

Place your main application icon at:

```
/home/feather/Documents/project/bookkeep/assets/icon.png
```

- **Size**: 512x512 pixels (PNG format)
- **Used for**: Window icon in the application

### 2. **System Icons** (for desktop integration)

Create multiple sizes for better system integration:

```
/home/feather/Documents/project/bookkeep/linux/icons/
├── 16x16/apps/bookkeep.png
├── 32x32/apps/bookkeep.png
├── 48x48/apps/bookkeep.png
├── 64x64/apps/bookkeep.png
├── 128x128/apps/bookkeep.png
├── 256x256/apps/bookkeep.png
└── 512x512/apps/bookkeep.png
```

## Installation Steps

### Option 1: Manual Installation (Development)

1. **Copy your icon file** to `/home/feather/Documents/project/bookkeep/assets/icon.png`
2. **Build your application**: `flutter build linux`
3. **The icon will be embedded** in your application bundle

### Option 2: System-wide Installation (Production)

1. **Create icon directories**:

   ```bash
   mkdir -p linux/icons/{16x16,32x32,48x48,64x64,128x128,256x256,512x512}/apps
   ```

2. **Copy your icons** (different sizes) to the respective directories

3. **Install desktop file and icons**:

   ```bash
   # Copy desktop file
   cp linux/bookkeep.desktop ~/.local/share/applications/

   # Copy icons to system
   cp -r linux/icons/* ~/.local/share/icons/hicolor/

   # Update icon cache
   gtk-update-icon-cache ~/.local/share/icons/hicolor
   ```

## Icon Requirements

### **Recommended Icon Specifications**:

- **Format**: PNG (with transparency support)
- **Primary Size**: 512x512 pixels
- **Design**: Simple, clear, recognizable at small sizes
- **Colors**: Should work on both light and dark backgrounds
- **Content**: Related to accounting/finance (calculator, ledger, money, etc.)

### **Quick Icon Creation Tips**:

1. **Use the Material Design icon** from your About page as inspiration
2. **Create a square design** with the account_balance_wallet icon
3. **Use your app's primary color scheme**
4. **Ensure good contrast** for visibility

## Testing Your Icon

After setting up the icon:

1. **Run the application**: `flutter run -d linux`
2. **Check the window title bar** - you should see your icon
3. **For desktop integration**: Install the .desktop file and check the applications menu

## Updating CMakeLists.txt (Optional)

For advanced icon integration, you can modify `/home/feather/Documents/project/bookkeep/linux/CMakeLists.txt` to install icons during build:

```cmake
# Install icons
install(DIRECTORY icons/ DESTINATION share/icons/hicolor)
install(FILES bookkeep.desktop DESTINATION share/applications)
```

## Quick Fix: Using Web Icons

As a temporary solution, you can copy one of your existing web icons:

```bash
cp web/icons/Icon-512.png assets/icon.png
```

This will give you a working icon while you create a custom one.
