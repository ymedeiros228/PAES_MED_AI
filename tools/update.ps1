# PAES MED AI - Updater PowerShell
# Baixa a nova versao silenciosamente e mostra avisos amigaveis.

$GitHubUser = "ymedeiros228"
$GitHubRepo = "PAES_MED_AI"
$VersionUrl = "https://raw.githubusercontent.com/$GitHubUser/$GitHubRepo/main/VERSION"
$ReleasesUrl = "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest"

Add-Type -AssemblyName System.Windows.Forms

function Show-Info($msg) {
    [System.Windows.Forms.MessageBox]::Show($msg, "PAES MED AI - Atualizacao", "OK", "Information") | Out-Null
}

function Show-Error($msg) {
    [System.Windows.Forms.MessageBox]::Show($msg, "PAES MED AI - Erro", "OK", "Error") | Out-Null
}

function Get-InstalledVersion {
    try {
        $key = "HKCU:\Software\PAES_MED_AI"
        return (Get-ItemProperty -Path $key -Name Version -ErrorAction Stop).Version
    } catch {
        return ""
    }
}

function Get-LatestVersion {
    try {
        $resp = Invoke-RestMethod -Uri $VersionUrl -TimeoutSec 15
        return $resp.Trim()
    } catch {
        return ""
    }
}

$current = Get-InstalledVersion
$latest = Get-LatestVersion

if (-not $latest) {
    Show-Error "Nao foi possivel verificar atualizacoes.\n\nVerifique sua conexao com a internet."
    exit 1
}

# Parse simples de versao
function To-VersionArray($v) {
    if (-not $v) { return @(0,0,0,0) }
    return $v.Split('.') | ForEach-Object { [int]($_ -replace '\D','') }
}

$currArr = To-VersionArray $current
$lateArr = To-VersionArray $latest

$needsUpdate = $current -eq "" -or ($lateArr[0] -gt $currArr[0]) -or
    ($lateArr[0] -eq $currArr[0] -and $lateArr[1] -gt $currArr[1]) -or
    ($lateArr[0] -eq $currArr[0] -and $lateArr[1] -eq $currArr[1] -and $lateArr[2] -gt $currArr[2]) -or
    ($lateArr[0] -eq $currArr[0] -and $lateArr[1] -eq $currArr[1] -and $lateArr[2] -eq $currArr[2] -and $lateArr[3] -gt $currArr[3])

if (-not $needsUpdate) {
    Show-Info "Voce ja esta na versao mais recente ($current)."
    exit 0
}

# Pergunta se quer baixar e instalar
$confirm = [System.Windows.Forms.MessageBox]::Show(
    "Nova versao disponivel: $latest\n\nVersao instalada: $current\n\nDeseja baixar e instalar agora?",
    "PAES MED AI - Atualizacao",
    "YesNo",
    "Question"
)

if ($confirm -ne "Yes") {
    exit 0
}

# Mostra que comecou o download
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.BalloonTipTitle = "PAES MED AI"
$notify.BalloonTipText = "Baixando atualizacao v$latest..."
$notify.Visible = $true
$notify.ShowBalloonTip(3000)

try {
    $release = Invoke-RestMethod -Uri $ReleasesUrl -TimeoutSec 15
    $asset = $release.assets | Where-Object { $_.name -like "PAESMedAI_Setup_*.exe" } | Select-Object -First 1
    if (-not $asset) {
        Show-Error "Instalador nao encontrado na release."
        exit 1
    }

    $downloadDir = Join-Path $env:TEMP "PAES_MED_AI_Update"
    New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
    $setupPath = Join-Path $downloadDir $asset.name

    # Baixa mostrando progresso (em memoria - rapido)
    $ProgressPreference = 'Continue'
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $setupPath -TimeoutSec 180

    $notify.BalloonTipText = "Download concluido. Iniciando instalacao..."
    $notify.ShowBalloonTip(3000)

    # Fecha o app atual para poder instalar
    $processes = Get-Process | Where-Object { $_.ProcessName -like "paes_med_ai" }
    foreach ($p in $processes) {
        $p.Kill() | Out-Null
    }

    Start-Sleep -Seconds 2

    # Executa o instalador silencioso com permissao de admin
    Start-Process -FilePath $setupPath -ArgumentList "/SILENT","/SUPPRESSMSGBOXES","/NORESTART","/CLOSEAPPLICATIONS" -Verb runAs -Wait

    Show-Info "Atualizacao concluida! O PAES MED AI foi atualizado para v$latest."
    exit 0
} catch {
    Show-Error "Erro no update: $_"
    exit 1
} finally {
    $notify.Visible = $false
    $notify.Dispose()
}
