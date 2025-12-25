# Build & Deployment Guide

## Prerequisites

- Flutter SDK 3.13.0 or higher
- Dart SDK 3.0.0 or higher
- Android SDK (for Android builds)
- Java JDK 11 or higher

## Performance Optimization

### Image Optimization

The app includes automatic image optimization for ML processing:

- **Max Dimensions**: 640x640 pixels
- **Quality**: 85% JPEG compression
- **Isolate Processing**: Images processed in separate isolates
- **Cache Management**: Optimized images cached temporarily

### ML Performance

- **Confidence Threshold**: 0.5 (configurable)
- **Batch Processing**: Up to 5 labels per image
- **Caching**: API responses cached for 24 hours

## Security

### API Keys

API keys should be set via environment variables or secure storage:

```bash
# Linux/Mac
export SPOONACULAR_API_KEY="your_key_here"
export NUTRITIONIX_APP_ID="your_app_id"
export NUTRITIONIX_API_KEY="your_api_key"

# Windows PowerShell
$env:SPOONACULAR_API_KEY="your_key_here"
$env:NUTRITIONIX_APP_ID="your_app_id"
$env:NUTRITIONIX_API_KEY="your_api_key"
```

### Network Security

- HTTPS only (cleartext traffic disabled)
- Network security config in `android/app/src/main/res/xml/network_security_config.xml`
- ProGuard rules for code obfuscation

## Building Release APK

### Using Scripts

**Windows (PowerShell):**
```powershell
.\scripts\build_release.ps1
```

**Linux/Mac:**
```bash
chmod +x scripts/build_release.sh
./scripts/build_release.sh
```

### Manual Build

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk
```

### Build Options

```bash
# Split APKs by ABI (smaller size)
flutter build apk --release --split-per-abi

# Build for specific ABI
flutter build apk --release --target-platform android-arm64
```

## Building App Bundle (Google Play)

### Using Scripts

**Windows (PowerShell):**
```powershell
.\scripts\build_bundle.ps1
```

**Linux/Mac:**
```bash
chmod +x scripts/build_bundle.sh
./scripts/build_bundle.sh
```

### Manual Build

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build App Bundle
flutter build appbundle --release

# Bundle location: build/app/outputs/bundle/release/app-release.aab
```

## Performance Testing

Run performance tests to ensure operations complete in <5s:

```bash
flutter test test/performance/performance_test.dart
```

Expected results:
- Repository initialization: <1s
- Recipe search: <2s
- Get all recipes: <1s
- Toggle favorite: <500ms
- Image optimization: <2s
- Complete workflow: <5s

## Profiling

Profile the app for performance analysis:

```bash
# Run in profile mode
flutter run --profile

# Generate performance report
flutter build apk --profile
```

## App Icons

Icons should be placed in:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `android/app/src/main/res/mipmap-*/ic_launcher_round.png`

Required sizes:
- mdpi: 48x48
- hdpi: 72x72
- xhdpi: 96x96
- xxhdpi: 144x144
- xxxhdpi: 192x192

## AndroidManifest Configuration

Key settings:
- **minSdk**: 21 (Android 5.0)
- **targetSdk**: Latest
- **Permissions**: Camera, Storage, Internet
- **Network Security**: HTTPS only
- **Hardware Acceleration**: Enabled

## ProGuard Configuration

ProGuard rules in `android/app/proguard-rules.pro`:
- Keeps Flutter classes
- Keeps ML Kit classes
- Removes logging in release
- Optimizes code size

## Deployment Checklist

- [ ] API keys configured securely
- [ ] App icons generated for all densities
- [ ] Version code and name updated in `pubspec.yaml`
- [ ] Performance tests passing (<5s)
- [ ] Code analyzed (`flutter analyze`)
- [ ] Tests passing (`flutter test`)
- [ ] Release build successful
- [ ] APK/Bundle size acceptable
- [ ] Network security configured
- [ ] ProGuard rules verified

## Sideloading APK

1. Enable "Install from Unknown Sources" on device
2. Transfer APK to device
3. Install via file manager or ADB:
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

## Google Play Store Upload

1. Build App Bundle (`.aab` file)
2. Create app listing in Google Play Console
3. Upload bundle
4. Complete store listing
5. Submit for review

## Troubleshooting

### Build Fails
- Check Flutter version: `flutter --version`
- Clean build: `flutter clean`
- Get dependencies: `flutter pub get`

### Large APK Size
- Use split APKs: `--split-per-abi`
- Enable ProGuard: `minifyEnabled true`
- Check assets size

### Performance Issues
- Profile with `flutter run --profile`
- Check image optimization
- Review ML processing thresholds

