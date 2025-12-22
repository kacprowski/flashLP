# ==========================================
# RPi SD Flasher (Windows)
# Google Drive + balenaEtcher
# BEZ PYTHONA
# ==========================================

$ErrorActionPreference = "Stop"

# ===== KONFIGURACJA =====
$GOOGLE_DRIVE_FILE_ID = "1cMRIFfbPRVDvhJYm9dbR002xypPs9AhF"
$IMAGE_NAME = "9.7_29.04.2025.zip"

$ETCHER_ZIP_URL = "https://github.com/balena-io/etcher/releases/latest/download/balenaEtcher-Portable-Setup.zip"
# =======================

Write-Host ""
Write-Host "=== Raspberry Pi SD Flasher ===" -ForegroundColor Cyan
Write-Host ""

# ===== KATALOG ROBOCZY =====
$WORKDIR = Join-Path $env:TEMP ("rpi-flash-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $WORKDIR | Out-Null

$IMAGE_PATH = Join-Path $WORKDIR $IMAGE_NAME
$ETCHER_ZIP = Join-Path $WORKDIR "etcher.zip"
$ETCHER_DIR = Join-Path $WORKDIR "etcher"

try {
    # ===== POBIERANIE Z GOOGLE DRIVE =====
    Write-Host "[1/4] Pobieranie obrazu z Google Drive (bez Pythona)..."

    $baseUrl = "https://drive.google.com/uc?export=download&id=$GOOGLE_DRIVE_FILE_ID"

    # SESJA HTTP (cookies!)
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    # 1️⃣ Pierwsze zapytanie – HTML + cookies
    $response = Invoke-WebRequest -Uri $baseUrl -WebSession $session

    # 2️⃣ Wyciągnięcie tokenu confirm
    if ($response.Content -match 'confirm=([0-9A-Za-z_-]+)') {
        $confirm = $matches[1]
    } else {
        throw "Google Drive nie zwrócił tokenu confirm (blokada / zmiana HTML)."
    }

    # 3️⃣ Drugie zapytanie – PRAWDZIWY DOWNLOAD
    $downloadUrl = "https://drive.google.com/uc?export=download&confirm=$confirm&id=$GOOGLE_DRIVE_FILE_ID"

    Invoke-WebRequest -Uri $downloadUrl -WebSession $session -OutFile $IMAGE_PATH

    # ===== WALIDACJA =====
    if (-not (Test-Path $IMAGE_PATH)) {
        throw "Plik nie został pobrany."
    }

    $firstBytes = Get-Content -Path $IMAGE_PATH -TotalCount 1 -Raw
    if ($firstBytes -match '<!DOCTYPE html>|<html') {
        throw "Pobrano HTML zamiast ZIP. Google Drive zablokował pobieranie."
    }

    Write-Host "✔ Obraz pobrany poprawnie."

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
