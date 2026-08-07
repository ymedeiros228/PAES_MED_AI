# Copia gabaritos de Downloads para data/gabaritos (local; nao commita PDFs).
# Usage: .\scripts\copy_gabaritos_from_downloads.ps1
# Matches: *gabarito*YYYY*.pdf -> data/gabaritos/gabarito_YYYY.pdf

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$dest = Join-Path $root "data\gabaritos"
$src = Join-Path $env:USERPROFILE "Downloads"
if (-not (Test-Path $src)) {
  Write-Host "Downloads not found: $src"
  exit 1
}
New-Item -ItemType Directory -Force -Path $dest | Out-Null
$copied = 0
Get-ChildItem -Path $src -Filter "*.pdf" -File -ErrorAction SilentlyContinue | ForEach-Object {
  $name = $_.Name
  if ($name -notmatch '(?i)gabarito') { return }
  if ($name -notmatch '(20\d{2})') { return }
  $year = $Matches[1]
  $target = Join-Path $dest "gabarito_$year.pdf"
  Copy-Item -LiteralPath $_.FullName -Destination $target -Force
  Write-Host "OK $year <- $($_.Name)"
  $copied++
}
if ($copied -eq 0) {
  Write-Host "Nenhum PDF *gabarito*YYYY* em Downloads."
} else {
  Write-Host "Copiados: $copied -> $dest"
  Write-Host "Proximo: Biblioteca -> Importar todos com gab"
}
