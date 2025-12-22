# ==========================================
# RPi SD Flasher (Windows)
# Google Drive + balenaEtcher
# Python EMBEDDABLE (tymczasowy)
# ==========================================

$ErrorActionPreference = "Stop"

# ===== KONFIGURACJA (ZMIENIASZ TYLKO TO) =====
$GOOGLE_DRIVE_FILE_ID = "1cMRIFfbPRVDvhJYm9dbR002xypPs9AhF"
$IMAGE_NAME = "9.7_29.04.2025.zip"
# ============================================

$ETCHER_ZIP_URL = "https://github.com/balena-io/etcher/releases/latest/download/balenaEtcher-Portable-Setup.zip"
$PY_URL  = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
$PIP_URL = "https://bootstrap.pypa.io/get-pip.py"

Write-Host ""
Write-Host "=== Raspberry Pi SD Flasher ===" -ForegroundColor Cyan
Write-Host ""

# ===== KATALOG ROBOCZY =====
$WORKDIR = Join-Path $env:TEMP ("rpi-flash-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $WORKDIR | Out-Null

$IMAGE_PATH = Join-Path $WORKDIR $IMAGE_NAME
$ETCHER_ZIP = Join-Path $WORKDIR "etcher.zip"
$ETCHER_DIR = Join-Path $WORKDIR "etcher"
$PY_DIR     = Join-Path $WORKDIR "python"
$PY_EXE     = Join-Path $PY_DIR "python.exe"

try {
    # ===== PYTHON EMBEDDABLE =====
    Write-Host "[1/6] Przygotowanie tymczasowego Pythona..."

    Invoke-WebRequest $PY_URL -OutFile "$WORKDIR\python.zip"
    Expand-Archive "$WORKDIR\python.zip" $PY_DIR -Force

    Invoke-WebRequest $PIP_URL -OutFile "$PY_DIR\get-pip.py"
    & $PY_EXE "$PY_DIR\get-pip.py" | Out-Null

    & $PY_EXE -m pip install gdown --no-warn-script-location | Out-Null

    # ===== POBIERANIE OBRAZU =====
    Write-Host "[2/6] Pobieranie obrazu z Google Drive..."
    & $PY_EXE -m gdown "https://drive.google.com/uc?id=$GOOGLE_DRIVE_FILE_ID" -O $IMAGE_PATH

    if (-not (Test-Path $IMAGE_PATH)) {
        throw "Pobieranie obrazu nie powiodło się."
    }

    Write-Host "✔ Obraz pobrany poprawnie."

    # ===== POBIERANIE ETCHERA =====
    Write-Host "[3/6] Pobieranie balenaEtcher..."
    Invoke-WebRequest $ETCHER_ZIP_URL -OutFile $ETCHER_ZIP

    Expand-Archive $ETCHER_ZIP $ETCHER_DIR -Force

    $ETCHER_EXE = Get-ChildItem $ETCHER_DIR -Recurse -Filter "*.exe" |
        Where-Object { $_.Name -match "Etcher|balena" } |
        Select-Object -First 1

    if (-not $ETCHER_EXE) {
        throw "Nie znaleziono Etcher.exe"
    }

    # ===== INSTRUKCJA =====
    Write-Host ""
    Write-Host "URUCHAMIAM BALENAETCHER" -ForegroundColor Yellow
    Write-Host "  Flash from file -> $IMAGE_PATH"
    Write-Host "  Select target  -> KARTA SD"
    Write-Host "  Flash!"
    Write-Host ""
    Write-Host "Po zakończeniu ZAMKNIJ Etcher." -ForegroundColor Yellow
    Write-Host ""

    # ===== START ETCHERA =====
    Start-Process -FilePath $ETCHER_EXE.FullName -WorkingDirectory $ETCHER_EXE.DirectoryName -Wait
}
finally {
    # ===== SPRZĄTANIE =====
    Write-Host ""
    Write-Host "[6/6] Usuwanie plików tymczasowych..." -ForegroundColor Cyan
    try {
        Remove-Item -Recurse -Force $WORKDIR
    } catch {}
    Write-Host "Gotowe. Na komputerze nie pozostał obraz ani Python." -ForegroundColor Green
}
