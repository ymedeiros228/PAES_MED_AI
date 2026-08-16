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

function Read-LocalVersion {
    if (Test-Path $LocalVersionFile) {
        return (Get-Content $LocalVersionFile -Raw).Trim()
    }
    return "0.0.0"
}

function Get-LatestReleaseInfo {
    $url = "https://api.github.com/repos/$Owner/$Repo/releases/$ReleaseTag"
    try {
        $headers = @{ "User-Agent" = "PAES_MED_AI_Updater" }
        $response = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 30
        return $response
    } catch {
        throw "Nao foi possivel verificar a ultima versao no GitHub. Verifique a conexao com a internet."
    }
}

function Show-Dialog($title, $message, $buttons) {
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    return [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, "Information")
}

# Verifica versao
Write-Host "Verificando atualizacoes..."
$localVersion = Read-LocalVersion
Write-Host "  Versao local: $localVersion"

try {
    $release = Get-LatestReleaseInfo
} catch {
    Show-Dialog "Atualizacao" $_ "OK" | Out-Null
    exit 1
}

$remoteVersion = $release.tag_name
$publishedAt = $release.published_at
Write-Host "  Versao remota: $remoteVersion"

# Encontra o asset
$asset = $release.assets | Where-Object { $_.name -eq $AssetName }
if (-not $asset) {
    Show-Dialog "Atualizacao" "Arquivo $AssetName nao encontrado no release $remoteVersion." "OK" | Out-Null
    exit 1
}

# Compara versoes (simples: se diferente, atualiza)
if ($localVersion -eq $remoteVersion) {
    $res = Show-Dialog "Atualizacao" "Voce ja esta na versao mais recente ($localVersion).`n`nDeseja reinstalar a mesma versao?" "YesNo"
    if ($res -ne [System.Windows.Forms.DialogResult]::Yes) {
        exit 0
    }
} else {
    $res = Show-Dialog "Nova versao disponivel" "Versao local: $localVersion`nNova versao: $remoteVersion`nPublicada em: $publishedAt`n`nDeseja atualizar agora?" "YesNo"
    if ($res -ne [System.Windows.Forms.DialogResult]::Yes) {
        exit 0
    }
}

# Backup
$backupDir = Join-Path $env:TEMP "PAES_MED_AI_backup_$(Get-Date -Format yyyyMMdd_HHmmss)"
Write-Host "Criando backup em: $backupDir"
Copy-Item -Path $InstallDir -Destination $backupDir -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

# Download
Write-Host "Baixando atualizacao..."
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

$downloadUrl = $asset.browser_download_url
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $ZipFile -TimeoutSec 120 -UseBasicParsing
} catch {
    Show-Dialog "Atualizacao" "Erro ao baixar a atualizacao: $_" "OK" | Out-Null
    exit 1
}

# Extrai
Write-Host "Extraindo arquivos..."
if (Test-Path $ExtractDir) { Remove-Item $ExtractDir -Recurse -Force }
New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
Expand-Archive -Path $ZipFile -DestinationPath $ExtractDir -Force

# Encontra a pasta raiz do pacote
$extractedRoot = Get-ChildItem -Path $ExtractDir -Directory | Select-Object -First 1
if (-not $extractedRoot) { $extractedRoot = $ExtractDir }

# Atualiza (copia app, backend, branding, VERSION, launcher; preserva data)
Write-Host "Atualizando arquivos..."
$dirsToUpdate = @("app", "backend", "branding", "data\provas", "data\gabaritos", "data\edital", "data\aulas", "data\inventory")
foreach ($dir in $dirsToUpdate) {
    $src = Join-Path $extractedRoot.FullName $dir
    $dst = Join-Path $InstallDir $dir
    if (Test-Path $src) {
        if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
        Copy-Item $src $dst -Recurse -Force
    }
}

# Arquivos soltos
$filesToUpdate = @("Iniciar_PAES_MED_AI.bat", "Instalar_PAES_MED_AI.bat", "LEIA-ME.txt", "VERSION.txt")
foreach ($file in $filesToUpdate) {
    $src = Join-Path $extractedRoot.FullName $file
    $dst = Join-Path $InstallDir $file
    if (Test-Path $src) {
        Copy-Item $src $dst -Force
    }
}

# Preserva banco de dados do usuario se existir
$userDb = Join-Path $InstallDir "data\paes_med_ai.db"
if (Test-Path $userDb) {
    # Mantem o banco do usuario
    Write-Host "Banco local do usuario preservado."
}

# Limpa temp
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Show-Dialog "Atualizacao concluida" "PAES MED AI foi atualizado para $remoteVersion.`n`nClique OK para reiniciar o aplicativo." "OK" | Out-Null

# Reinicia o app se estava rodando
$launcher = Join-Path $InstallDir "Iniciar_PAES_MED_AI.bat"
if (Test-Path $launcher) {
    Start-Process "cmd.exe" -ArgumentList "/c `"$launcher`"" -WindowStyle Minimized
}
