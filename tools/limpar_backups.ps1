param(
  [int]$Keep = 10,
  [switch]$Apply
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$BackupDir = Join-Path $Root "data\backups"

if (-not (Test-Path -LiteralPath $BackupDir)) {
  Write-Host "Nenhuma pasta de backups encontrada: $BackupDir"
  exit 0
}

$items = Get-ChildItem -LiteralPath $BackupDir -Force |
  Where-Object { $_.Name -ne "_restore_tmp" -and ($_.PSIsContainer -or $_.Extension -ieq ".zip") } |
  Sort-Object LastWriteTime -Descending

$remove = @($items | Select-Object -Skip $Keep)
$bytes = ($remove | ForEach-Object {
  if ($_.PSIsContainer) {
    (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue |
      Measure-Object Length -Sum).Sum
  } else {
    $_.Length
  }
} | Measure-Object -Sum).Sum

Write-Host "Backups encontrados: $($items.Count)"
Write-Host "Manter: $Keep"
Write-Host "Candidatos para remover: $($remove.Count)"
Write-Host ("Espaco estimado: {0:N2} MB" -f (($bytes -as [double]) / 1MB))

if (-not $Apply) {
  Write-Host ""
  Write-Host "Simulacao apenas. Para remover, rode:"
  Write-Host "powershell -ExecutionPolicy Bypass -File tools\limpar_backups.ps1 -Keep $Keep -Apply"
  exit 0
}

$backupRoot = (Resolve-Path -LiteralPath $BackupDir).Path
foreach ($item in $remove) {
  $resolved = (Resolve-Path -LiteralPath $item.FullName).Path
  if (-not $resolved.StartsWith($backupRoot)) {
    throw "Caminho fora de data\backups: $resolved"
  }
  Remove-Item -LiteralPath $resolved -Recurse -Force
}

Write-Host "Limpeza concluida."
