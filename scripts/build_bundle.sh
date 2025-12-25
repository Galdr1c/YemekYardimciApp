#!/bin/bash

# Build App Bundle for Google Play Store

echo "🚀 Building YemekYardimciApp App Bundle..."

# Clean previous builds
echo "📦 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

# Build App Bundle
echo "🔨 Building release App Bundle..."
flutter build appbundle --release

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📱 Bundle location: build/app/outputs/bundle/release/app-release.aab"
    echo "📊 Bundle size: $(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)"
    echo ""
    echo "📤 Ready for Google Play Store upload!"
else
    echo "❌ Build failed!"
    exit 1
fi

