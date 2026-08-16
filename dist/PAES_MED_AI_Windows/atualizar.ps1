# atualizar_paes_med_ai.ps1
# Verifica e baixa a ultima versao do GitHub Releases
param(
    [string]$InstallDir = (Split-Path $MyInvocation.MyCommand.Path -Parent)
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# Configuracao
$Owner = "ymedeiros228"
$Repo = "PAES_MED_AI"
$ReleaseTag = "latest"
$AssetName = "PAES_MED_AI_Windows.zip"

# Arquivos locais
$LocalVersionFile = Join-Path $InstallDir "VERSION.txt"
$TempDir = Join-Path $env:TEMP "PAES_MED_AI_update"
$ZipFile = Join-Path $TempDir $AssetName
$ExtractDir = Join-Path $TempDir "extracted"
$LogFile = Join-Path $env:TEMP "PAES_MED_AI_update.log"

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts - $msg" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    Write-Host $msg
}

function Show-Dialog($title, $message, $buttons) {
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    return [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, "Information")
}

Log "Iniciando atualizador. Pasta: $InstallDir"

# Verifica versao
Log "Verificando atualizacoes..."
$localVersion = if (Test-Path $LocalVersionFile) { (Get-Content $LocalVersionFile -Raw).Trim() } else { "0.0.0" }
Log "  Versao local: $localVersion"

try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/releases/$ReleaseTag" -Headers @{ "User-Agent" = "PAES_MED_AI" } -TimeoutSec 30
} catch {
    Show-Dialog "Atualizacao" "Nao foi possivel verificar atualizacoes.`n`nVerifique sua conexao com a internet.`n`nErro: $_" "OK" | Out-Null
    Log "ERRO API GitHub: $_"
    exit 1
}

$remoteVersion = $response.tag_name
$publishedAt = $response.published_at
$releaseUrl = $response.html_url
Log "  Versao remota: $remoteVersion"

$asset = $response.assets | Where-Object { $_.name -eq $AssetName }
if (-not $asset) {
    Show-Dialog "Atualizacao" "Arquivo $AssetName nao encontrado no release $remoteVersion.`n`nVerifique o release no GitHub." "OK" | Out-Null
    Log "ERRO: asset nao encontrado"
    exit 1
}

# Compara versoes simples
function Parse-Version($v) {
    $clean = ($v -replace '^v', '') -split '\+' | Select-Object -First 1
    $parts = $clean -split '\.' | ForEach-Object { try { [int]$_ } catch { 0 } }
    while ($parts.Count -lt 3) { $parts += 0 }
    return $parts[0..2]
}

function Compare-ToLocal($local, $remote) {
    $l = Parse-Version $local
    $r = Parse-Version $remote
    for ($i = 0; $i -lt 3; $i++) {
        if ($r[$i] -gt $l[$i]) { return 1 }
        if ($r[$i] -lt $l[$i]) { return -1 }
    }
    return 0
}

$comparison = Compare-ToLocal $localVersion $remoteVersion
Log "  Comparacao: $comparison"

if ($comparison -le 0) {
    $res = Show-Dialog "Atualizacao" "Voce ja esta na versao mais recente ($localVersion).`n`nDeseja reinstalar a mesma versao?" "YesNo"
    if ($res -ne [System.Windows.Forms.DialogResult]::Yes) {
        Log "Usuario cancelou reinstalacao."
        exit 0
    }
}

$res = Show-Dialog "Nova versao disponivel" "Versao local: $localVersion`nNova versao: $remoteVersion`nPublicada em: $publishedAt`n`nO atualizador fara backup automatico do seu progresso, fechara o PAES MED AI, atualizara e reiniciara tudo sozinho.`n`nDeseja atualizar agora?" "YesNo"
if ($res -ne [System.Windows.Forms.DialogResult]::Yes) {
    Log "Usuario cancelou atualizacao."
    exit 0
}

# Fecha o app PAES MED AI para liberar os arquivos
Log "Fechando PAES MED AI para atualizar..."
Get-Process | Where-Object { $_.ProcessName -like '*paes_med_ai*' } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Backup dos dados do usuario ANTES de atualizar
$backupDir = Join-Path $env:TEMP "PAES_MED_AI_backup_$(Get-Date -Format yyyyMMdd_HHmmss)"
Log "Criando backup do progresso do usuario em: $backupDir"
$progressItems = @("data\paes_med_ai.db", "data\backups", "data\exports", "data\logs")
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
foreach ($item in $progressItems) {
    $src = Join-Path $InstallDir $item
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $backupDir -Recurse -Force -ErrorAction SilentlyContinue
        Log "  Backup: $item"
    }
}

# Download
Log "Baixando atualizacao..."
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $ZipFile -TimeoutSec 120 -UseBasicParsing
} catch {
    Show-Dialog "Atualizacao" "Erro ao baixar a atualizacao:`n$_" "OK" | Out-Null
    Log "ERRO download: $_"
    exit 1
}
Log "  Download concluido."

# Extrai
Log "Extraindo arquivos..."
New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
Expand-Archive -Path $ZipFile -DestinationPath $ExtractDir -Force

# Encontra a pasta raiz do pacote
$extractedRoot = Get-ChildItem -Path $ExtractDir -Directory | Select-Object -First 1
if (-not $extractedRoot) { $extractedRoot = Get-Item $ExtractDir }
Log "  Pasta extraida: $($extractedRoot.FullName)"

# Atualiza arquivos (preserva dados do usuario)
Log "Atualizando arquivos..."
$dirsToUpdate = @("app", "backend", "branding", "data\provas", "data\gabaritos", "data\edital", "data\aulas", "data\inventory")
foreach ($dir in $dirsToUpdate) {
    $src = Join-Path $extractedRoot.FullName $dir
    $dst = Join-Path $InstallDir $dir
    if (Test-Path $src) {
        if (Test-Path $dst) { Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue }
        Copy-Item $src $dst -Recurse -Force
        Log "  Atualizado: $dir"
    }
}

# Arquivos soltos
$filesToUpdate = @("Iniciar_PAES_MED_AI.bat", "Instalar_PAES_MED_AI.bat", "LEIA-ME.txt", "VERSION.txt", "atualizar.ps1", "Atualizar_PAES_MED_AI.bat")
foreach ($file in $filesToUpdate) {
    $src = Join-Path $extractedRoot.FullName $file
    $dst = Join-Path $InstallDir $file
    if (Test-Path $src) {
        Copy-Item $src $dst -Force
        Log "  Atualizado: $file"
    }
}

# Restaura dados do usuario (sobrescreve apenas se backup existir)
Log "Restaurando progresso do usuario..."
foreach ($item in $progressItems) {
    $src = Join-Path $backupDir $item
    $dst = Join-Path $InstallDir $item
    if (Test-Path $src) {
        if (Test-Path $dst) { Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue }
        Copy-Item $src $dst -Recurse -Force -ErrorAction SilentlyContinue
        Log "  Restaurado: $item"
    }
}

# Limpa temp
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Log "Atualizacao concluida para $remoteVersion."
$logLocation = "Log salvo em: $LogFile"
Show-Dialog "Atualizacao concluida" "PAES MED AI foi atualizado para $remoteVersion.`n`nSeu progresso foi preservado automaticamente.`n`nO aplicativo sera reiniciado sozinho.`n`n$logLocation" "OK" | Out-Null

# Limpa temp
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

# Reinicia o app automaticamente
$launcher = Join-Path $InstallDir "Iniciar_PAES_MED_AI.bat"
if (Test-Path $launcher) {
    Log "Reiniciando PAES MED AI..."
    Start-Process "cmd.exe" -ArgumentList "/c `"$launcher`"" -WindowStyle Minimized
    exit 0
}

Log "Launcher nao encontrado em $launcher"
