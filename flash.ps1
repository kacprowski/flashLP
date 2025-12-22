# ==========================================
# RPi SD Flasher (Windows)
# Google Drive + balenaEtcher
# Python EMBEDDABLE (tymczasowy)
# Etcher via WINGET
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
    # ===== [1/7] PYTHON =====
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
    Set-Content -Path $PTH_FILE.FullName -Value $pth -Encoding ASCII

    # ===== [2/7] pip =====
    Write-Host "[2/7] Instalowanie pip..."
    Invoke-WebRequest $PIP_URL -OutFile "$PY_DIR\get-pip.py"
    & $PY_EXE "$PY_DIR\get-pip.py" | Out-Null

    # ===== [3/7] gdown =====
    Write-Host "[3/7] Instalowanie gdown..."
    & $PY_EXE -m pip install --no-cache-dir gdown | Out-Null
    & $PY_EXE -c "import gdown; print('PYTHON OK')"

    # ===== [4/7] OBRAZ (RETRY + CONTINUE) =====
    Write-Host "[4/7] Pobieranie obrazu z Google Drive..."

    $success = $false
    for ($i = 1; $i -le 5; $i++) {
        Write-Host "  Próba $i/5..."
        & $PY_EXE -m gdown "https://drive.google.com/uc?id=$GOOGLE_DRIVE_FILE_ID" `
            -O $IMAGE_PATH --continue --fuzzy

        if (Test-Path $IMAGE_PATH) {
            $success = $true
            break
        }
        Start-Sleep 5
    }

    if (-not $success) {
        throw "Nie udało się pobrać obrazu po 5 próbach."
    }

    Write-Host "✔ Obraz pobrany poprawnie."

    # ===== [5/7] ETCHER =====
    Write-Host "[5/7] Instalowanie balenaEtcher (winget)..."
    winget install --id Balena.Etcher --accept-source-agreements --accept-package-agreements

    # znajdź faktyczną ścieżkę
    $ETCHER_PATHS = @(
        "$Env:ProgramFiles\balenaEtcher\balenaEtcher.exe",
        "$Env:ProgramFiles(x86)\balenaEtcher\balenaEtcher.exe"
    )

    $ETCHER_EXE = $ETCHER_PATHS | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $ETCHER_EXE) {
        throw "Nie znaleziono balenaEtcher.exe po instalacji."
    }

    # ===== [6/7] START ETCHERA =====
    Write-Host ""
    Write-Host "URUCHAMIAM BALENAETCHER" -ForegroundColor Yellow
    Write-Host "Flash from file -> $IMAGE_PATH"
    Write-Host "Select target  -> KARTA SD"
    Write-Host "Flash!"
    Write-Host ""

    Start-Process -FilePath $ETCHER_EXE -Wait
}
finally {
    # ===== [7/7] CLEANUP =====
    Write-Host ""
    Write-Host "[7/7] Sprzątanie..."
    winget uninstall --id Balena.Etcher --silent | Out-Null
    Remove-Item -Recurse -Force $WORKDIR -ErrorAction SilentlyContinue
    Write-Host "Gotowe. Na komputerze nie pozostał obraz, Python ani Etcher." -ForegroundColor Green
}
