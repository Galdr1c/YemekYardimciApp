# Build release APK script for YemekYardimciApp (PowerShell)

Write-Host "🚀 Building YemekYardimciApp Release APK..." -ForegroundColor Green

# Clean previous builds
Write-Host "📦 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "📥 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Analyze code
Write-Host "🔍 Analyzing code..." -ForegroundColor Yellow
flutter analyze

# Run tests
Write-Host "🧪 Running tests..." -ForegroundColor Yellow
flutter test

# Build APK
Write-Host "🔨 Building release APK..." -ForegroundColor Yellow
flutter build apk --release

# Check if build succeeded
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $apkPath) {
        $size = (Get-Item $apkPath).Length / 1MB
        Write-Host "📱 APK location: $apkPath" -ForegroundColor Cyan
        Write-Host "📊 APK size: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
    }
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

