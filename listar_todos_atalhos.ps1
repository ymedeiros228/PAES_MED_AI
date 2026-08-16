$ws = New-Object -ComObject WScript.Shell

# Lista TODOS os atalhos da Area de Trabalho
$desktop = [Environment]::GetFolderPath('Desktop')
Write-Host "=== AREA DE TRABALHO ==="
$shortcuts = Get-ChildItem -Path $desktop -Filter "*.lnk" -ErrorAction SilentlyContinue
foreach ($sc in $shortcuts) {
    $s = $ws.CreateShortcut($sc.FullName)
    if ($sc.Name -like "*PAES*" -or $sc.Name -like "*paes*") {
        Write-Host "  >>> $($sc.Name)"
        Write-Host "      Target: $($s.TargetPath)"
        Write-Host "      Args: $($s.Arguments)"
    }
}

# Lista atalhos do Menu Iniciar
$startMenu = [Environment]::GetFolderPath('Programs')
Write-Host ""
Write-Host "=== MENU INICIAR ==="
$startShortcuts = Get-ChildItem -Path $startMenu -Filter "*.lnk" -Recurse -ErrorAction SilentlyContinue
foreach ($sc in $startShortcuts) {
    $s = $ws.CreateShortcut($sc.FullName)
    if ($sc.Name -like "*PAES*" -or $sc.Name -like "*paes*") {
        Write-Host "  >>> $($sc.FullName)"
        Write-Host "      Target: $($s.TargetPath)"
        Write-Host "      Args: $($s.Arguments)"
    }
}

# Lista atalhos comuns
$commonDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
Write-Host ""
Write-Host "=== AREA DE TRABALHO COMUM ==="
$commonShortcuts = Get-ChildItem -Path $commonDesktop -Filter "*.lnk" -ErrorAction SilentlyContinue
foreach ($sc in $commonShortcuts) {
    if ($sc.Name -like "*PAES*" -or $sc.Name -like "*paes*") {
        $s = $ws.CreateShortcut($sc.FullName)
        Write-Host "  >>> $($sc.Name)"
        Write-Host "      Target: $($s.TargetPath)"
    }
}
