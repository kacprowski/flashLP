# ==========================================
# RPi SD Flasher (Windows)
# Google Drive + balenaEtcher
# Python EMBEDDABLE (tymczasowy)
# ==========================================

$ErrorActionPreference = "Stop"

# ===== KONFIGURACJA =====
$GOOGLE_DRIVE_FILE_ID = "1cMRIFfbPRVDvhJYm9dbR002xypPs9AhF"
$IMAGE_NAME = "9.7_29.04.2025.zip"
# =======================

$PY_URL  = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
$PIP_URL = "https://bootstrap.pypa.io/get-pip.py"
$ETCHER_EXE_URL = "https://github.com/balena-io/etcher/releases/latest/download/balenaEtcher-Setup.exe"

Write-Host ""
Write-Host "=== Raspberry Pi SD Flasher ===" -ForegroundColor Cyan
Write-Host ""

# ===== KATALOG ROBOCZY =====
$WORKDIR = Join-Path $env:TEMP ("rpi-flash-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $WORKDIR | Out-Null

$IMAGE_PATH = Join-Path $WORKDIR $IMAGE_NAME
$PY_DIR     = Join-Path $WORKDIR "python"
$PY_EXE     = Join-Path $PY_DIR "python.exe"
$ETCHER_EXE = Join-Path $WORKDIR "balenaEtcher.exe"

try {
    Write-Host "[1/7] Przygotowanie tymczasowego Pythona..."
    Invoke-WebRequest $PY_URL -OutFile "$WORKDIR\python.zip"
    Expand-Archive "$WORKDIR\python.zip" $PY_DIR -Force

    $PTH_FILE = Get-ChildItem $PY_DIR -Filter "python*._pth" | Select-Object -First 1
    $ZIP_NAME = Get-ChildItem $PY_DIR -Filter "python*.zip" | Select-Object -First 1

    $pth = @(
        $ZIP_NAME.Name
        "."
        "Lib"
        "Lib\site-packages"
        "import site"
    )
    Set-Content $PTH_FILE.FullName $pth -Encoding ASCII

    Write-Host "[2/7] Instalowanie pip..."
    Invoke-WebRequest $PIP_URL -OutFile "$PY_DIR\get-pip.py"
    & $PY_EXE "$PY_DIR\get-pip.py" | Out-Null

    Write-Host "[3/7] Instalowanie gdown..."
    & $PY_EXE -m pip install --no-cache-dir gdown | Out-Null
    & $PY_EXE -c "import encodings, gdown; print('PYTHON OK')"

    Write-Host "[4/7] Pobieranie obrazu z Google Drive..."
    & $PY_EXE -m gdown "https://drive.google.com/uc?id=$GOOGLE_DRIVE_FILE_ID" -O $IMAGE_PATH
    Write-Host "✔ Obraz pobrany poprawnie."

    Write-Host "[5/7] Pobieranie balenaEtcher..."
    Start-BitsTransfer -Source $ETCHER_EXE_URL -Destination $ETCHER_EXE


    Write-Host ""
    Write-Host "URUCHAMIAM BALENAETCHER" -ForegroundColor Yellow
    Write-Host "Flash from file -> $IMAGE_PATH"
    Write-Host "Select target -> KARTA SD"
    Write-Host "Flash!"
    Write-Host ""

    Start-Process $ETCHER_EXE -Wait
}
finally {
    Write-Host "[7/7] Usuwanie plików tymczasowych..."
    Remove-Item -Recurse -Force $WORKDIR -ErrorAction SilentlyContinue
    Write-Host "Gotowe. Na komputerze nie pozostał obraz, Python ani Etcher." -ForegroundColor Green
}
