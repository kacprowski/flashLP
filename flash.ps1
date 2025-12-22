# flash.ps1
$ErrorActionPreference = "Stop"

# ====== USTAWIENIA (TY PODMIENIASZ) ======
$IMAGE_URL      = "https://twoj-host/twoj-obraz.img.xz"
$IMAGE_FILENAME = "twoj-obraz.img.xz"

# Etcher for Windows jest dostępny z oficjalnej strony / dystrybucji.
# Najprościej: pobierz z etcher.balena.io, a tu wstaw bezpośredni link do ZIP (portable) jeśli taki wystawiasz u siebie.
# Alternatywa: wrzuć ZIP Etchera na ten sam hosting co obraz i podaj swój URL.
$ETCHER_ZIP_URL = "https://twoj-host/balenaEtcher-portable.zip"
# =========================================

$work = Join-Path $env:TEMP ("rpi-flash-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $work | Out-Null

$imagePath = Join-Path $work $IMAGE_FILENAME
$etcherZip = Join-Path $work "etcher.zip"
$etcherDir = Join-Path $work "etcher"

Write-Host ""
Write-Host "== RPi SD Flasher (Windows + balenaEtcher) ==" -ForegroundColor Cyan
Write-Host "Folder roboczy: $work"
Write-Host ""

try {
  Write-Host "[1/3] Pobieranie obrazu do TEMP..."
  Invoke-WebRequest -Uri $IMAGE_URL -OutFile $imagePath

  Write-Host "[2/3] Pobieranie balenaEtcher (portable) do TEMP..."
  Invoke-WebRequest -Uri $ETCHER_ZIP_URL -OutFile $etcherZip

  Write-Host "Rozpakowywanie Etchera..."
  Expand-Archive -Path $etcherZip -DestinationPath $etcherDir -Force

  # Znajdź exe (różne paczki mogą mieć różne nazwy plików)
  $etcherExe = Get-ChildItem -Path $etcherDir -Recurse -Filter "*.exe" |
               Where-Object { $_.Name -match "Etcher|balena" } |
               Select-Object -First 1

  if (-not $etcherExe) {
    throw "Nie znalazłem pliku .exe Etchera w paczce. Sprawdź, czy ZIP jest poprawny."
  }

  Write-Host ""
  Write-Host "URUCHAMIAM ETCHER..." -ForegroundColor Yellow
  Write-Host "W Etcherze wybierz:" -ForegroundColor Yellow
  Write-Host "  1) Flash from file -> $imagePath" -ForegroundColor Yellow
  Write-Host "  2) Select target -> Twoja karta SD" -ForegroundColor Yellow
  Write-Host "  3) Flash!" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "Po zakończeniu i weryfikacji ZAMKNIJ Etcher, a skrypt posprząta pliki." -ForegroundColor Yellow
  Write-Host ""

  # Start Etcher i czekaj aż użytkownik zamknie okno
  Start-Process -FilePath $etcherExe.FullName -WorkingDirectory $etcherExe.DirectoryName -Wait

} finally {
  Write-Host ""
  Write-Host "[3/3] Sprzątanie: usuwanie obrazu i narzędzi z TEMP..." -ForegroundColor Cyan
  try { Remove-Item -Recurse -Force $work } catch {}
  Write-Host "Gotowe. Na komputerze nie zostawiono obrazu." -ForegroundColor Green
}
