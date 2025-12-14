# Script to fix bcrypt package conflict
# Run this in PowerShell as Administrator

Write-Host "=== Fixing bcrypt package conflict ===" -ForegroundColor Yellow

# Stop any running uvicorn process
Write-Host "`n1. Stopping uvicorn processes..." -ForegroundColor Cyan
Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -like "*uvicorn*"} | Stop-Process -Force
Start-Sleep -Seconds 2

# Remove bcrypt folders manually
Write-Host "`n2. Removing bcrypt packages..." -ForegroundColor Cyan
$bcryptPaths = @(
    ".venv\Lib\site-packages\bcrypt",
    ".venv\Lib\site-packages\bcrypt-3.2.2.dist-info",
    ".venv\Lib\site-packages\bcrypt-5.0.0.dist-info",
    ".venv\Lib\site-packages\_bcrypt.pyd",
    ".venv\Lib\site-packages\bcrypt-4.0.1.dist-info"
)

foreach ($path in $bcryptPaths) {
    if (Test-Path $path) {
        Write-Host "  Removing: $path" -ForegroundColor Gray
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n3. Installing bcrypt 4.0.1..." -ForegroundColor Cyan
uv pip install "bcrypt==4.0.1"

Write-Host "`n4. Verifying installation..." -ForegroundColor Cyan
uv pip list | Select-String "bcrypt"

Write-Host "`n✓ Done! Now restart your server:" -ForegroundColor Green
Write-Host "  uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000" -ForegroundColor Yellow
