#!/bin/bash

# Build release APK script for YemekYardimciApp

echo "🚀 Building YemekYardimciApp Release APK..."

# Clean previous builds
echo "📦 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

# Analyze code
echo "🔍 Analyzing code..."
flutter analyze

# Run tests
echo "🧪 Running tests..."
flutter test

# Build APK
echo "🔨 Building release APK..."
flutter build apk --release

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📱 APK location: build/app/outputs/flutter-apk/app-release.apk"
    echo "📊 APK size: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
else
    echo "❌ Build failed!"
    exit 1
fi

