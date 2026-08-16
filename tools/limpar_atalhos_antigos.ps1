# Limpa atalhos antigos do PAES MED AI na Area de Trabalho e Menu Iniciar
$desktop = [Environment]::GetFolderPath('Desktop')
$startMenu = [Environment]::GetFolderPath('StartMenu')
$programs = [System.IO.Path]::Combine($startMenu, 'Programs')

$atalhos = @(
    'PAES MED AI.lnk',
    'Atualizar PAES MED AI.lnk',
    'Desinstalar PAES MED AI.lnk',
    'PAES MED AI - Estudos para Medicina.lnk'
)

foreach ($nome in $atalhos) {
    $caminhos = @(
        [System.IO.Path]::Combine($desktop, $nome),
        [System.IO.Path]::Combine($programs, $nome)
    )
    foreach ($caminho in $caminhos) {
        if (Test-Path $caminho) {
            Remove-Item $caminho -Force
            Write-Host "Removido: $caminho" -ForegroundColor Green
        }
    }
}

Write-Host "`nAtalhos antigos removidos. Instale a nova versao do PAES MED AI." -ForegroundColor Cyan
