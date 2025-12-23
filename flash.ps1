# ==========================================
# RPi Image Downloader (Windows)
# Google Drive
# Python EMBEDDABLE (temporary)
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
Write-Host "=== Raspberry Pi Image Downloader ===" -ForegroundColor Cyan
Write-Host ""

# ===== KATALOG ROBOCZY =====
$WORKDIR = Join-Path $env:TEMP ("rpi-image-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $WORKDIR | Out-Null

$IMAGE_PATH = Join-Path $WORKDIR $IMAGE_NAME
$PY_DIR     = Join-Path $WORKDIR "python"
$PY_EXE     = Join-Path $PY_DIR "python.exe"

# =========================================================
# [1/3] PYTHON
# =========================================================
Write-Host "[1/3] Przygotowanie tymczasowego Pythona..."
Invoke-WebRequest $PY_URL -OutFile (Join-Path $WORKDIR "python.zip")
Expand-Archive (Join-Path $WORKDIR "python.zip") $PY_DIR -Force

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
# [2/3] pip + gdown
# =========================================================
Write-Host "[2/3] Instalowanie pip i gdown..."
Invoke-WebRequest $PIP_URL -OutFile (Join-Path $PY_DIR "get-pip.py")
& $PY_EXE (Join-Path $PY_DIR "get-pip.py") | Out-Null
& $PY_EXE -m pip install --no-cache-dir gdown | Out-Null
& $PY_EXE -c "import gdown; print('PYTHON OK')" | Out-Null

# =========================================================
# [3/3] OBRAZ
# =========================================================
Write-Host "[3/3] Pobieranie obrazu z Google Drive..."

$GDOWN_URL = "https://drive.google.com/uc?id=$GOOGLE_DRIVE_FILE_ID"
Write-Host "Gdown URL: $GDOWN_URL" -ForegroundColor DarkGray
Write-Host "Output:    $IMAGE_PATH" -ForegroundColor DarkGray

# (This is the same approach as your original script.)
& $PY_EXE -m gdown $GDOWN_URL -O $IMAGE_PATH --continue --fuzzy

if (-not (Test-Path $IMAGE_PATH)) {
    throw "Nie udało się pobrać obrazu."
}

# Validate it's really a ZIP (starts with 'PK')
try {
    $fs = [System.IO.File]::OpenRead($IMAGE_PATH)
    $buf = New-Object byte[] 2
    [void]$fs.Read($buf, 0, 2)
    $fs.Close()

    $sig = [System.Text.Encoding]::ASCII.GetString($buf)
    if ($sig -ne "PK") {
        $size = (Get-Item $IMAGE_PATH).Length
        throw "Pobrany plik nie wygląda jak ZIP (signature='$sig', size=$size). To często oznacza stronę HTML z Google Drive (brak uprawnień / quota / virus scan)."
    }
} catch {
    throw $_
}

Write-Host ""
Write-Host "✔ Obraz pobrany poprawnie." -ForegroundColor Green
Write-Host "Lokalizacja:" -ForegroundColor Yellow
Write-Host "  $IMAGE_PATH" -ForegroundColor Yellow
Write-Host ""
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "GOTOWE. MOZESZ TERAZ UZYC TEGO PLIKU." -ForegroundColor Yellow
Write-Host "NACISNIJ ENTER, ABY POSPRZATAC (USUNAC TEMP)" -ForegroundColor Yellow
Write-Host "LUB ZAMKNIJ OKNO, ABY ZOSTAWIC PLIKI." -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host ""

Read-Host "Czekam"

# =========================================================
# CLEANUP (explicit only, like your original)
# =========================================================
Write-Host ""
Write-Host "Sprzątanie..."
Remove-Item -Recurse -Force $WORKDIR -ErrorAction SilentlyContinue
Write-Host "Gotowe. Na komputerze nie pozostał obraz ani Python." -ForegroundColor Green
