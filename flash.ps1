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
    # ===== [1/7] PYTHON EMBEDDABLE =====
    Write-Host "[1/7] Przygotowanie tymczasowego Pythona..."

    Invoke-WebRequest $PY_URL -OutFile "$WORKDIR\python.zip"
    Expand-Archive "$WORKDIR\python.zip" $PY_DIR -Force

    # ===== FIX python._pth (TO JEST KLUCZ) =====
    $PTH_FILE = Get-ChildItem $PY_DIR -Filter "python*._pth" | Select-Object -First 1
    if (-not $PTH_FILE) { throw "Nie znaleziono python._pth" }

    $pth = @(
        "."
        "Lib"
        "Lib\site-packages"
        "import site"
    )

    Set-Content -Path $PTH_FILE.FullName -Value $pth -Encoding ASCII
    # ==========================================

    # ===== [2/7] pip (lokalny, do tego Pythona) =====
    Write-Host "[2/7] Instalowanie pip..."
    Invoke-WebRequest $PIP_URL -OutFile "$PY_DIR\get-pip.py"
    & $PY_EXE "$PY_DIR\get-pip.py" | Out-Null

    # ===== [3/7] gdown =====
    Write-Host "[3/7] Instalowanie gdown..."
    & $PY_EXE -m pip install --no-cache-dir gdown | Out-Null

    # TWARDY TEST
    & $PY_EXE -c "import gdown; print('gdown OK')" 

    # ===== [4/7] POBIERANIE OBRAZU =====
    Write-Host "[4/7] Pobieranie obrazu z Google Drive..."
    & $PY_EXE -m gdown "https://drive.google.com/uc?id=$GOOGLE_DRIVE_FILE_ID" -O $IMAGE_PATH

    if (-not (Test-Path $IMAGE_PATH)) {
        throw "Pobieranie obrazu nie powiodło się."
    }

    Write-Host "✔ Obraz pobrany poprawnie."

    # ===== [5/7] ETCHER =====
    Write-Host "[5/7] Pobieranie balenaEtcher..."
    Invoke-WebRequest $ETCHER_ZIP_URL -OutFile $ETCHER_ZIP
    Expand-Archive $ETCHER_ZIP $ETCHER_DIR -Force

    $ETCHER_EXE = Get-ChildItem $ETCHER_DIR -Recurse -Filter "*.exe" |
        Where-Object { $_.Name -match "Etcher|balena" } |
        Select-Object -First 1

    if (-not $ETCHER_EXE) {
        throw "Nie znaleziono Etcher.exe"
    }

    # ===== [6/7] INSTRUKCJA =====
    Write-Host ""
    Write-Host "URUCHAMIAM BALENAETCHER" -ForegroundColor Yellow
    Write-Host "  Flash from file -> $IMAGE_PATH"
    Write-Host "  Select target  -> KARTA SD"
    Write-Host "  Flash!"
    Write-Host ""
    Write-Host "Po zakończeniu ZAMKNIJ Etcher." -ForegroundColor Yellow
    Write-Host ""

    Start-Process -FilePath $ETCHER_EXE.FullName `
        -WorkingDirectory $ETCHER_EXE.DirectoryName `
        -Wait
}
finally {
    # ===== [7/7] SPRZĄTANIE =====
    Write-Host ""
    Write-Host "[7/7] Usuwanie plików tymczasowych..." -ForegroundColor Cyan
    try {
        Remove-Item -Recurse -Force $WORKDIR
    } catch {}
    Write-Host "Gotowe. Na komputerze nie pozostał obraz ani Python." -ForegroundColor Green
}
