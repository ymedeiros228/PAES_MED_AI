$ws = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$lnk = Join-Path $desktop 'PAES MED AI.lnk'
$root = (Get-Location).Path
$target = Join-Path $root 'dist\PAES_MED_AI_Windows\Iniciar_PAES_MED_AI.bat'
$workdir = Join-Path $root 'dist\PAES_MED_AI_Windows'
$ico = Join-Path $workdir 'branding\app_icon.ico'
$s = $ws.CreateShortcut($lnk)
$s.TargetPath = $target
$s.WorkingDirectory = $workdir
if (Test-Path $ico) { $s.IconLocation = $ico }
$s.Description = 'PAES MED AI - Plataforma de estudos para UEMA'
$s.Save()
Write-Host "Atalho criado: $lnk"
