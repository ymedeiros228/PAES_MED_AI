$ws = New-Object -ComObject WScript.Shell

# Remove TODOS os atalhos PAES antigos
$desktop = [Environment]::GetFolderPath('Desktop')
Get-ChildItem -Path $desktop -Filter "*.lnk" | Where-Object { $_.Name -like "*PAES*" -or $_.Name -like "*paes*" } | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "Removido: $($_.Name)"
}

# Remove do Menu Iniciar
$startMenu = [Environment]::GetFolderPath('Programs')
Get-ChildItem -Path $startMenu -Filter "*.lnk" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*PAES*" -or $_.Name -like "*paes*" } | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "Removido Menu: $($_.FullName)"
}

# Cria atalho novo apontando para VBS (nao abre navegador)
$lnk = Join-Path $desktop 'PAES MED AI.lnk'
$target = 'C:\Users\Yuri\Documents\uema estudos\PAES_MED_AI\dist\PAES_MED_AI_Windows_Novo\Iniciar_PAES_MED_AI.vbs'
$workdir = 'C:\Users\Yuri\Documents\uema estudos\PAES_MED_AI\dist\PAES_MED_AI_Windows_Novo'
$ico = Join-Path $workdir 'branding\app_icon.ico'

$s = $ws.CreateShortcut($lnk)
$s.TargetPath = $target
$s.WorkingDirectory = $workdir
if (Test-Path $ico) { $s.IconLocation = $ico }
$s.Description = 'PAES MED AI - Plataforma de estudos para UEMA'
$s.Save()
Write-Host "Atalho criado: $lnk"

# Menu Iniciar tambem
$paesFolder = Join-Path $startMenu 'PAES MED AI'
if (-not (Test-Path $paesFolder)) { New-Item -ItemType Directory -Path $paesFolder -Force | Out-Null }
$startLnk = Join-Path $paesFolder 'PAES MED AI.lnk'
$s2 = $ws.CreateShortcut($startLnk)
$s2.TargetPath = $target
$s2.WorkingDirectory = $workdir
if (Test-Path $ico) { $s2.IconLocation = $ico }
$s2.Description = 'PAES MED AI - Plataforma de estudos para UEMA'
$s2.Save()
Write-Host "Menu Iniciar: $startLnk"
