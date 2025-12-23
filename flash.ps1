# ==========================================
# RPi SD Flasher (Windows)
# Google Drive + Raspberry Pi Imager
# Python EMBEDDABLE (temporary)
# ==========================================

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ===== CONFIG =====
$GOOGLE_DRIVE_FILE_ID = "1cMRIFfbPRVDvhJYm9dbR002xypPs9AhF"
$IMAGE_NAME = "9.7_29.04.2025.zip"
# ==================

$PY_URL  = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
$PIP_URL = "https://bootstrap.pypa.io/get-pip.py"

Write-Host ""
Write-Host "=== Raspberry Pi SD Flasher ===" -ForegroundColor Cyan
Write-Host ""

# ===== WORKDIR =====
$WORKDIR = Join-Path $env:TEMP ("rpi-flash-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $WORKDIR | Out-Null

$IMAGE_PATH = Join-Path $WORKDIR $IMAGE_NAME
$PY_DIR     = Join-Path $WORKDIR "python"
$PY_EXE     = Join-Path $PY_DIR "python.exe"

# =========================================================
# [1/5] PYTHON
# =========================================================
Write-Host "[1/5] Preparing temporary Python..."
Invoke-WebRequest $PY_URL -OutFile "$WORKDIR\python.zip"
Expand-Archive "$WORKDIR\python.zip" $PY_DIR -Force

$PTH_FILE = Get-ChildItem $PY_DIR -Filter "python*._pth" | Select-Object -First 1
$ZIP_NAME = Get-ChildItem $PY_DIR -Filter "python*.zip" | Select-Object -First 1

if (-not $PTH_FILE -or -not $ZIP_NAME) {
    throw "Python preparation failed."
}

$pth = @(
    $ZIP_NAME.Name
    "."
    "Lib"
    "Lib\site-packages"
    "import site"
)
Set-Content -Path $PTH_FILE.FullName -Value $pth -Encoding ASCII

# =========================================================
# [2/5] pip + gdown
# =========================================================
Write-Host "[2/5] Installing pip and gdown..."
Invoke-WebRequest $PIP_URL -OutFile "$PY_DIR\get-pip.py"
& $PY_EXE "$PY_DIR\get-pip.py" | Out-Null
& $PY_EXE -m pip install --no-cache-dir gdown | Out-Null
& $PY_EXE -c "import gdown; print('PYTHON OK')" | Out-Null

# =========================================================
# [3/5] IMAGE
# =========================================================
Write-Host "[3/5] Downloading image from Google Drive..."
& $PY_EXE -m gdown "https://drive.google.com/uc?id=$GOOGLE_DRIVE_FILE_ID" `
    -O $IMAGE_PATH --continue --fuzzy

if (-not (Test-Path $IMAGE_PATH)) {
    throw "Image download failed."
}
Write-Host "✔ Image downloaded successfully."

# =========================================================
# [4/5] RASPBERRY PI IMAGER
# =========================================================
Write-Host "[4/5] Installing / launching Raspberry Pi Imager..."

winget install --id RaspberryPiImager.RaspberryPiImager `
    --accept-source-agreements `
    --accept-package-agreements `
    --silent `
    --scope machine

# Locate Imager reliably (PATH / portable / per-user)
$IMAGER_EXE = Get-Command rpi-imager.exe -ErrorAction SilentlyContinue |
              Select-Object -ExpandProperty Source -First 1

if (-not $IMAGER_EXE) {
    throw "Raspberry Pi Imager not found."
}

Write-Host "✔ Raspberry Pi Imager found at:"
Write-Host "  $IMAGER_EXE" -ForegroundColor DarkGray

Write-Host ""
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "RASPBERRY PI IMAGER WILL START NOW" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Click:  CHOOSE OS" -ForegroundColor Yellow
Write-Host "2. Select: Use custom" -ForegroundColor Yellow
Write-Host "3. Choose file:" -ForegroundColor Yellow
Write-Host "   $IMAGE_PATH" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. Click:  CHOOSE STORAGE -> SD CARD" -ForegroundColor Yellow
Write-Host "5. Click:  WRITE" -ForegroundColor Yellow
Write-Host ""
Write-Host "AFTER FLASHING IS COMPLETE AND IMAGER IS CLOSED" -ForegroundColor Yellow
Write-Host "PRESS ENTER TO CLEAN UP" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host ""

Start-Process $IMAGER_EXE

Read-Host "Waiting"

# =========================================================
# [5/5] CLEANUP
# =========================================================
Write-Host ""
Write-Host "[5/5] Cleaning up..."
Remove-Item -Recurse -Force $WORKDIR -ErrorAction SilentlyContinue
Write-Host "Done. No image or Python left on the computer." -ForegroundColor Green
