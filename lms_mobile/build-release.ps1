# Script build release APK với obfuscation cho Windows PowerShell
# Sử dụng: .\build-release.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Release APK with Obfuscation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Flutter đã cài đặt chưa
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Flutter not found. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Clean project
Write-Host ""
Write-Host "Cleaning project..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host ""
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build APK với obfuscation
Write-Host ""
Write-Host "Building release APK with obfuscation..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
flutter build apk --release --obfuscate --split-debug-info=./debug-info

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "APK location:" -ForegroundColor Cyan
    Write-Host "  build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor White
    Write-Host ""
    Write-Host "Debug info location:" -ForegroundColor Cyan
    Write-Host "  ./debug-info/" -ForegroundColor White
    Write-Host ""
    Write-Host "Mapping file location:" -ForegroundColor Cyan
    Write-Host "  android/app/build/outputs/mapping/release/mapping.txt" -ForegroundColor White
    Write-Host ""
    Write-Host "IMPORTANT: Save the mapping.txt file safely!" -ForegroundColor Yellow
    Write-Host "It's needed to deobfuscate crash reports." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Build failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}



