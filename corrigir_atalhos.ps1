$ws = New-Object -ComObject WScript.Shell

# 1. Remove o atalho antigo do Chrome (Menu Iniciar)
$chromeShortcut = "C:\Users\Yuri\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\apps do Chrome\PAES MED AI.lnk"
if (Test-Path $chromeShortcut) {
    Remove-Item $chromeShortcut -Force
    Write-Host "Removido atalho Chrome: $chromeShortcut"
}

# 2. Remove o atalho de teste antigo
$testeShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'PAES_MED_AI_TESTE.lnk'
if (Test-Path $testeShortcut) {
    Remove-Item $testeShortcut -Force
    Write-Host "Removido atalho teste: $testeShortcut"
}

# 3. Cria atalho novo "PAES MED AI" na Area de Trabalho
$desktop = [Environment]::GetFolderPath('Desktop')
$lnk = Join-Path $desktop 'PAES MED AI.lnk'
$target = 'C:\Users\Yuri\Documents\uema estudos\PAES_MED_AI\dist\PAES_MED_AI_Windows_Novo\Iniciar_PAES_MED_AI.bat'
$workdir = 'C:\Users\Yuri\Documents\uema estudos\PAES_MED_AI\dist\PAES_MED_AI_Windows_Novo'
$ico = Join-Path $workdir 'branding\app_icon.ico'

$s = $ws.CreateShortcut($lnk)
$s.TargetPath = $target
$s.WorkingDirectory = $workdir
if (Test-Path $ico) { $s.IconLocation = $ico }
$s.Description = 'PAES MED AI - Plataforma de estudos para UEMA'
$s.WindowStyle = 1
$s.Save()
Write-Host "Atalho criado: $lnk"

# 4. Tambem cria no Menu Iniciar
$startMenu = [Environment]::GetFolderPath('Programs')
$paesFolder = Join-Path $startMenu 'PAES MED AI'
if (-not (Test-Path $paesFolder)) { New-Item -ItemType Directory -Path $paesFolder -Force | Out-Null }
$startLnk = Join-Path $paesFolder 'PAES MED AI.lnk'
$s2 = $ws.CreateShortcut($startLnk)
$s2.TargetPath = $target
$s2.WorkingDirectory = $workdir
if (Test-Path $ico) { $s2.IconLocation = $ico }
$s2.Description = 'PAES MED AI - Plataforma de estudos para UEMA'
$s2.WindowStyle = 1
$s2.Save()
Write-Host "Menu Iniciar: $startLnk"
