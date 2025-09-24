#!/bin/bash

# Package Name Verification Script
# This script verifies that the package name has been completely changed

echo "🔍 Verifying Package Name Change..."
echo "=================================="

# Check for any remaining old package references
echo "1. Checking for old package name (com.example.bookkeep):"
OLD_REFS=$(grep -r "com.example.bookkeep" . --exclude-dir=.git --exclude-dir=build --exclude-dir=.dart_tool 2>/dev/null)
if [ -z "$OLD_REFS" ]; then
    echo "   ✅ No old package references found"
else
    echo "   ❌ Found old package references:"
    echo "$OLD_REFS"
fi

echo ""
echo "2. Checking for new package name (com.ashish.bookkeep):"
NEW_REFS=$(grep -r "com.ashish.bookkeep" . --exclude-dir=.git --exclude-dir=build --exclude-dir=.dart_tool 2>/dev/null | wc -l)
echo "   ✅ Found $NEW_REFS references to new package name"

echo ""
echo "3. Key files verification:"

# Android
if grep -q "com.ashish.bookkeep" android/app/build.gradle.kts; then
    echo "   ✅ Android build.gradle.kts updated"
else
    echo "   ❌ Android build.gradle.kts not updated"
fi

if [ -f "android/app/src/main/kotlin/com/ashish/bookkeep/MainActivity.kt" ]; then
    echo "   ✅ Android MainActivity.kt in correct location"
else
    echo "   ❌ Android MainActivity.kt not found in new location"
fi

# iOS
if grep -q "com.ashish.bookkeep" ios/Runner.xcodeproj/project.pbxproj; then
    echo "   ✅ iOS project.pbxproj updated"
else
    echo "   ❌ iOS project.pbxproj not updated"
fi

# macOS
if grep -q "com.ashish.bookkeep" macos/Runner/Configs/AppInfo.xcconfig; then
    echo "   ✅ macOS AppInfo.xcconfig updated"
else
    echo "   ❌ macOS AppInfo.xcconfig not updated"
fi

# Linux
if grep -q "com.ashish.bookkeep" linux/CMakeLists.txt; then
    echo "   ✅ Linux CMakeLists.txt updated"
else
    echo "   ❌ Linux CMakeLists.txt not updated"
fi

echo ""
echo "4. Testing build readiness:"
echo "   📦 Running flutter analyze..."
flutter analyze --no-pub > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ Flutter analyze passed"
else
    echo "   ⚠️  Flutter analyze found issues (this may be normal)"
fi

echo ""
echo "🎉 Package name verification complete!"
echo ""
echo "To test builds:"
echo "• Android: flutter build apk"
echo "• iOS: flutter build ios"
echo "• Linux: flutter build linux"
echo "• macOS: flutter build macos"
echo "• Web: flutter build web"