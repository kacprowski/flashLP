# ==========================================
# RPi SD Flasher (Windows)
# Google Drive + balenaEtcher (MS Store)
# Python EMBEDDABLE (tymczasowy)
# ==========================================

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ===== KONFIGURACJA =====
$GOOGLE_DRIVE_FILE_ID = "1cMRIFfbPRVDvhJYm9dbR002xypPs9AhF"
$IMAGE_NAME = "9.7_29.04.2025.zip"
# =======================

$PY_URL  = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
$PIP_URL = "https://bootstrap.pypa.io/get-pip.py"

Write-Host ""
Write-Host "=== Raspberry Pi SD Flasher ===" -ForegroundColor Cyan
Write-Host ""

# ===== KATALOG ROBOCZY =====
$WORKDIR = Join-Path $env:TEMP ("rpi-flash-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $WORKDIR | Out-Null

$IMAGE_PATH = Join-Path $WORKDIR $IMAGE_NAME
$PY_DIR     = Join-Path $WORKDIR "python"
$PY_EXE     = Join-Path $PY_DIR "python.exe"

try {
    # ===== [1/6] PYTHON =====
    Write-Host "[1/6] Przygotowanie tymczasowego Pythona..."
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
    Set-Content -Path $PTH_FILE.FullName -Value $pth -Encoding ASCII

    # ===== [2/6] pip =====
    Write-Host "[2/6] Instalowanie pip..."
    Invoke-WebRequest $PIP_URL -OutFile "$PY_DIR\get-pip.py"
    & $PY_EXE "$PY_DIR\get-pip.py" | Out-Null

    # ===== [3/6] gdown =====
    Write-Host "[3/6] Instalowanie gdown..."
    & $PY_EXE -m pip install --no-cache-dir gdown | Out-Null
    & $PY_EXE -c "import gdown; print('PYTHON OK')"

    # ===== [4/6] OBRAZ =====
    Write-Host "[4/6] Pobieranie obrazu z Google Drive..."
    & $PY_EXE -m gdown "https://drive.google.com/uc?id=$GOOGLE_DRIVE_FILE_ID" `
        -O $IMAGE_PATH --continue --fuzzy

    if (-not (Test-Path $IMAGE_PATH)) {
        throw "Nie udało się pobrać obrazu."
    }
    Write-Host "✔ Obraz pobrany poprawnie."

    # ===== [5/6] ETCHER =====
Write-Host "[5/6] Instalowanie / uruchamianie balenaEtcher..."
winget install --id Balena.Etcher --accept-source-agreements --accept-package-agreements

$APP = Get-StartApps | Where-Object { $_.Name -like "*Etcher*" } | Select-Object -First 1
if (-not $APP) {
    throw "Nie znaleziono balenaEtcher w systemie."
}

Write-Host ""
Write-Host "URUCHAMIAM BALENAETCHER" -ForegroundColor Yellow
Write-Host "Flash from file -> $IMAGE_PATH"
Write-Host "Select target  -> KARTA SD"
Write-Host "Flash!"
Write-Host ""

Start-Process "explorer.exe" "shell:AppsFolder\$($APP.AppID)"

Write-Host ""
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "PO ZAKOŃCZENIU FLASHOWANIA I ZAMKNIĘCIU ETCHERA" -ForegroundColor Yellow
Write-Host "NACIŚNIJ ENTER, ABY ZAKOŃCZYĆ SKRYPT" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host ""

Read-Host "Czekam"
