# PAES MED AI - Updater PowerShell
# Verifica e baixa a nova versao silenciosamente.
# Pode ser chamado pelo app desktop ou manualmente.

$GitHubUser = "ymedeiros228"
$GitHubRepo = "PAES_MED_AI"
$VersionUrl = "https://raw.githubusercontent.com/$GitHubUser/$GitHubRepo/main/VERSION"
$ReleasesUrl = "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest"

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
        Write-Host "Erro ao verificar versao: $_" -ForegroundColor Red
        return ""
    }
}

$current = Get-InstalledVersion
$latest = Get-LatestVersion

if (-not $latest) {
    Write-Host "Nao foi possivel verificar atualizacoes." -ForegroundColor Yellow
    exit 1
}

Write-Host "Versao instalada: $current"
Write-Host "Versao mais recente: $latest"

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
    Write-Host "Voce ja esta na versao mais recente." -ForegroundColor Green
    exit 0
}

Write-Host "Nova versao disponivel. Baixando..." -ForegroundColor Cyan

try {
    $release = Invoke-RestMethod -Uri $ReleasesUrl -TimeoutSec 15
    $asset = $release.assets | Where-Object { $_.name -like "PAESMedAI_Setup_*.exe" } | Select-Object -First 1
    if (-not $asset) {
        Write-Host "Instalador nao encontrado na release." -ForegroundColor Red
        exit 1
    }

    $tempDir = [System.IO.Path]::GetTempPath()
    $setupPath = Join-Path $tempDir $asset.name

    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $setupPath -TimeoutSec 120
    Write-Host "Instalador baixado em: $setupPath" -ForegroundColor Green
    Write-Host "Iniciando instalacao..." -ForegroundColor Cyan

    Start-Process -FilePath $setupPath -ArgumentList "/SILENT","/SUPPRESSMSGBOXES","/NORESTART","/CLOSEAPPLICATIONS" -Wait
    Write-Host "Atualizacao concluida!" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "Erro no update: $_" -ForegroundColor Red
    exit 1
}
