#!/bin/bash
# Script build release APK với obfuscation cho Linux/Mac
# Sử dụng: ./build-release.sh

echo "========================================"
echo "Building Release APK with Obfuscation"
echo "========================================"
echo ""

# Kiểm tra Flutter đã cài đặt chưa
echo "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter not found. Please install Flutter first."
    exit 1
fi

flutter --version

# Clean project
echo ""
echo "Cleaning project..."
flutter clean

# Get dependencies
echo ""
echo "Getting dependencies..."
flutter pub get

# Build APK với obfuscation
echo ""
echo "Building release APK with obfuscation..."
echo "This may take a few minutes..."
flutter build apk --release --obfuscate --split-debug-info=./debug-info

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Build completed successfully!"
    echo "========================================"
    echo ""
    echo "APK location:"
    echo "  build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "Debug info location:"
    echo "  ./debug-info/"
    echo ""
    echo "Mapping file location:"
    echo "  android/app/build/outputs/mapping/release/mapping.txt"
    echo ""
    echo "IMPORTANT: Save the mapping.txt file safely!"
    echo "It's needed to deobfuscate crash reports."
else
    echo ""
    echo "========================================"
    echo "Build failed!"
    echo "========================================"
    exit 1
fi



