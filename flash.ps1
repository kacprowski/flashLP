# ==========================================
# RPi SD Flasher (Windows)
# Google Drive + balenaEtcher
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

# =========================================================
# [1/5] PYTHON
# =========================================================
Write-Host "[1/5] Przygotowanie tymczasowego Pythona..."
Invoke-WebRequest $PY_URL -OutFile "$WORKDIR\python.zip"
Expand-Archive "$WORKDIR\python.zip" $PY_DIR -Force

$PTH_FILE = Get-ChildItem $PY_DIR -Filter "python*._pth" | Select-Object -First 1
$ZIP_NAME = Get-ChildItem $PY_DIR -Filter "python*.zip" | Select-Object -First 1

if (-not $PTH_FILE -or -not $ZIP_NAME) {
    throw "Błąd przygotowania Pythona"
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
Write-Host "[2/5] Instalowanie pip i gdown..."
Invoke-WebRequest $PIP_URL -OutFile "$PY_DIR\get-pip.py"
& $PY_EXE "$PY_DIR\get-pip.py" | Out-Null
& $PY_EXE -m pip install --no-cache-dir gdown | Out-Null
& $PY_EXE -c "import gdown; print('PYTHON OK')"

# =========================================================
# [3/5] OBRAZ
# =========================================================
Write-Host "[3/5] Pobieranie obrazu z Google Drive..."
& $PY_EXE -m gdown "https://drive.google.com/uc?id=$GOOGLE_DRIVE_FILE_ID" `
    -O $IMAGE_PATH --continue --fuzzy

if (-not (Test-Path $IMAGE_PATH)) {
    throw "Nie udało się pobrać obrazu."
}
Write-Host "✔ Obraz pobrany poprawnie."

# =========================================================
# [4/5] ETCHER
# =========================================================
Write-Host "[4/5] Instalowanie / uruchamianie balenaEtcher..."
winget install --id Balena.Etcher --accept-source-agreements --accept-package-agreements

$APP = Get-StartApps | Where-Object { $_.Name -like "*Etcher*" } | Select-Object -First 1
if (-not $APP) {
    throw "Nie znaleziono balenaEtcher w systemie."
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "URUCHAMIAM BALENAETCHER" -ForegroundColor Yellow
Write-Host "Flash from file -> $IMAGE_PATH" -ForegroundColor Yellow
Write-Host "Select target  -> KARTA SD" -ForegroundColor Yellow
Write-Host "Flash!" -ForegroundColor Yellow
Write-Host ""
Write-Host "PO ZAKOŃCZENIU FLASHOWANIA I ZAMKNIĘCIU ETCHERA" -ForegroundColor Yellow
Write-Host "NACIŚNIJ ENTER, ABY POSPRZĄTAĆ" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host ""

Start-Process "explorer.exe" "shell:AppsFolder\$($APP.AppID)"

Read-Host "Czekam"

# =========================================================
# [5/5] CLEANUP
# =========================================================
Write-Host ""
Write-Host "[5/5] Sprzątanie..."
Remove-Item -Recurse -Force $WORKDIR -ErrorAction SilentlyContinue
Write-Host "Gotowe. Na komputerze nie pozostał obraz ani Python." -ForegroundColor Green
