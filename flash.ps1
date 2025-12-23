# ==========================================
# RPi Image Downloader (Windows)
# Google Drive
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
Write-Host "=== Raspberry Pi Image Downloader ===" -ForegroundColor Cyan
Write-Host ""

# ===== WORKDIR =====
$WORKDIR = Join-Path $env:TEMP ("rpi-image-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $WORKDIR | Out-Null

$IMAGE_PATH = Join-Path $WORKDIR $IMAGE_NAME
$PY_DIR     = Join-Path $WORKDIR "python"
$PY_EXE     = Join-Path $PY_DIR "python.exe"

# =========================================================
# CLEANUP HANDLER (runs on window close)
# =========================================================
Register-EngineEvent PowerShell.Exiting -Action {
    if (Test-Path $using:WORKDIR) {
        Remove-Item -Recurse -Force $using:WORKDIR -ErrorAction SilentlyContinue
    }
}

# =========================================================
# [1/3] PYTHON
# =========================================================
Write-Host "[1/3] Preparing temporary Python..."
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
# [2/3] pip + gdown
# =========================================================
Write-Host "[2/3] Installing pip and gdown..."
Invoke-WebRequest $PIP_URL -OutFile "$PY_DIR\get-pip.py"
& $PY_EXE "$PY_DIR\get-pip.py" | Out-Null
& $PY_EXE -m pip install --no-cache-dir gdown | Out-Null

# =========================================================
# [3/3] IMAGE
# =========================================================
Write-Host "[3/3] Downloading image from Google Drive..."
& $PY_EXE -m gdown "https://drive.google.com/uc?id=$GOOGLE_DRIVE_FILE_ID" `
    -O $IMAGE_PATH --continue --fuzzy

if (-not (Test-Path $IMAGE_PATH)) {
    throw "Image download failed."
}

Write-Host ""
Write-Host "✔ Image downloaded successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Location:" -ForegroundColor Yellow
Write-Host "  $IMAGE_PATH" -ForegroundColor Yellow
Write-Host ""
Write-Host "You may now use this image with any flasher." -ForegroundColor Cyan
Write-Host ""
Write-Host "==================================================" -ForegroundColor DarkYellow
Write-Host "PRESS ENTER WHEN YOU ARE DONE" -ForegroundColor DarkYellow
Write-Host "OR JUST CLOSE THIS WINDOW" -ForegroundColor DarkYellow
Write-Host "==================================================" -ForegroundColor DarkYellow
Write-Host ""

Read-Host "Waiting"

# =========================================================
# FINAL CLEANUP
# =========================================================
Write-Host ""
Write-Host "Cleaning up temporary files..."
Remove-Item -Recurse -Force $WORKDIR -ErrorAction SilentlyContinue
Write-Host "Done. Temporary files removed." -ForegroundColor Green
