# ==========================================
# RPi SD Flasher (Windows)
# Google Drive + balenaEtcher
# BEZ PYTHONA
# ==========================================

$ErrorActionPreference = "Stop"

# ===== KONFIGURACJA =====
$GOOGLE_DRIVE_FILE_ID = "1cMRIFfbPRVDvhJYm9dbR002xypPs9AhF"
$IMAGE_NAME = "9.7_29.04.2025.zip"

# Portable balenaEtcher ZIP
$ETCHER_ZIP_URL = "https://github.com/balena-io/etcher/releases/latest/download/balenaEtcher-Portable-Setup.zip"
# =======================

Write-Host ""
Write-Host "=== Raspberry Pi SD Flasher ===" -ForegroundColor Cyan
Write-Host ""

# ===== KATALOG ROBOCZY =====
$WORKDIR = Join-Path $env:TEMP ("rpi-flash-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $WORKDIR | Out-Null

$IMAGE_PATH = Join-Path $WORKDIR $IMAGE_NAME
$COOKIE     = Join-Path $WORKDIR "cookie.txt"
$ETCHER_ZIP = Join-Path $WORKDIR "etcher.zip"
$ETCHER_DIR = Join-Path $WORKDIR "etcher"

try {
    # ===== POBIERANIE Z GOOGLE DRIVE =====
    Write-Host "[1/4] Pobieranie obrazu z Google Drive (bez Pythona)..."

    $url = "https://drive.google.com/uc?export=download&id=$GOOGLE_DRIVE_FILE_ID"

    # Pierwsze zapytanie – zapis cookie + HTML
    $response = Invoke-WebRequest -Uri $url -SessionVariable sess -OutFile $null

    # Wyciągnij token confirm
    if ($response.Content -match "confirm=([0-9A-Za-z_]+)") {
        $confirm = $matches[1]
    } else {
        throw "Nie udało się pobrać tokenu confirm z Google Drive."
    }

    # Drugie zapytanie – prawdziwy download
    $downloadUrl = "https://drive.google.com/uc?export=download&confirm=$confirm&id=$GOOGLE_DRIVE_FILE_ID"
    Invoke-WebRequest -Uri $downloadUrl -WebSession $sess -OutFile $IMAGE_PATH

    if (-not (Test-Path $IMAGE_PATH)) {
        throw "Pobieranie obrazu nie powiodło się."
    }

    # ===== POBIERANIE ETCHERA =====
    Write-Host "[2/4] Pobieranie balenaEtcher..."
    Invoke-WebRequest -Uri $ETCHER_ZIP_URL -OutFile $ETCHER_ZIP

    Write-Host "Rozpakowywanie Etchera..."
    Expand-Archive -Path $ETCHER_ZIP -DestinationPath $ETCHER_DIR -Force

    $ETCHER_EXE = Get-ChildItem -Path $ETCHER_DIR -Recurse -Filter "*.exe" |
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

    Start-Process -FilePath $ETCHER_EXE.FullName -WorkingDirectory $ETCHER_EXE.DirectoryName -Wait
}
finally {
    # ===== SPRZĄTANIE =====
    Write-Host ""
    Write-Host "[4/4] Usuwanie plików tymczasowych..." -ForegroundColor Cyan
    try {
        Remove-Item -Recurse -Force $WORKDIR
    } catch {}
    Write-Host "Gotowe. Na komputerze nie pozostał obraz." -ForegroundColor Green
}
