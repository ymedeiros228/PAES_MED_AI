$ws = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$lnk = Join-Path $desktop 'PAES_MED_AI_TESTE.lnk'
$s = $ws.CreateShortcut($lnk)
$s.TargetPath = 'C:\Users\Yuri\Documents\uema estudos\PAES_MED_AI\dist\PAES_MED_AI_Windows_Novo\Iniciar_PAES_MED_AI.bat'
$s.WorkingDirectory = 'C:\Users\Yuri\Documents\uema estudos\PAES_MED_AI\dist\PAES_MED_AI_Windows_Novo'
$ico = 'C:\Users\Yuri\Documents\uema estudos\PAES_MED_AI\dist\PAES_MED_AI_Windows_Novo\branding\app_icon.ico'
if (Test-Path $ico) { $s.IconLocation = $ico }
$s.Description = 'PAES MED AI - Plataforma de estudos para UEMA'
$s.Save()
Write-Host "Atalho criado: $lnk"
