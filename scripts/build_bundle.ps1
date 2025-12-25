# Build App Bundle for Google Play Store (PowerShell)

Write-Host "🚀 Building YemekYardimciApp App Bundle..." -ForegroundColor Green

# Clean previous builds
Write-Host "📦 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "📥 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build App Bundle
Write-Host "🔨 Building release App Bundle..." -ForegroundColor Yellow
flutter build appbundle --release

# Check if build succeeded
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    $bundlePath = "build\app\outputs\bundle\release\app-release.aab"
    if (Test-Path $bundlePath) {
        $size = (Get-Item $bundlePath).Length / 1MB
        Write-Host "📱 Bundle location: $bundlePath" -ForegroundColor Cyan
        Write-Host "📊 Bundle size: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📤 Ready for Google Play Store upload!" -ForegroundColor Green
    }
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

