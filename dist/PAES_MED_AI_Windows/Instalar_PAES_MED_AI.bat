@echo off
chcp 65001 >nul 2>nul
setlocal EnableExtensions EnableDelayedExpansion
title Instalador PAES MED AI
color 0B

cls
echo.
echo   ____    _    ____  ____     __  __    _    ___ _   _    ___   ___  __  __ 
echo  ^|  _ \  / \  / ___^|/ ___^|   ^|  \/  |  / \  |_ _^| \ ^| ^|  / _ \ ^|   \^|  \/  ^|
echo  ^| ^|_) ^|/ _ \^| ^|   ^| ^|       ^| ^|\/^| ^| / _ \  ^| ^|^|  \^| ^| ^| ^| ^| ^|^| ^|) ^| ^|\/^| ^|
echo  ^|  __// ___ \ ^|___^| ^|___    ^| ^|  ^| ^|/ ___ \ ^| ^|^| ^|\  ^| ^| ^|_^| ^|^|  _ /^| ^|  ^| ^|
echo  ^|_^|  /_/   \_\____^|\____^|   ^|_^|  ^|_/_/   \_\___^|_^| \_/ ^|\___/ ^|_^| \\\^|_^|  ^|_^|
echo.
echo   Plataforma de Estudos para PAES/UEMA Medicina
echo   ____________________________________________
echo.

REM Detecta pasta do pacote (onde este script esta)
set "PKG=%~dp0"
set "PKG=%PKG:~0,-1%"

REM Verifica arquivos essenciais
if not exist "%PKG%\app\paes_med_ai.exe" (
  echo   [ERRO] paes_med_ai.exe nao encontrado em %PKG%\app\
  echo   O pacote esta incompleto. Reempacote com empacotar_windows.bat
  pause
  exit /b 1
)

if not exist "%PKG%\backend\main.py" (
  echo   [ERRO] backend\main.py nao encontrado em %PKG%\backend\
  echo   O pacote esta incompleto.
  pause
  exit /b 1
)

echo.
echo   [1/5] Verificando Python...
where python >nul 2>nul
if errorlevel 1 (
  echo.
  echo   [ERRO] Python nao encontrado no PATH.
  echo   Instale Python 3.11+ de https://python.org
  echo   Marque "Add Python to PATH" durante a instalacao.
  start https://python.org/downloads/
  pause
  exit /b 1
)
python --version
echo   [OK] Python encontrado.

echo.
echo   [2/5] Verificando integridade do pacote...
set "OK=1"
for %%F in (app\flutter_windows.dll app\data\flutter_assets backend\requirements.txt data\paes_med_ai.db branding\app_icon.ico VERSION.txt atualizar.ps1 Atualizar_PAES_MED_AI.bat) do (
  if not exist "%PKG%\%%F" (
    echo     [FALTA] %%F
    set "OK=0"
  )
)
if "%OK%"=="0" (
  echo.
  echo   [ERRO] Pacote incompleto. Veja os itens FALTA acima.
  pause
  exit /b 1
)
echo   [OK] Pacote completo.

echo.
echo   [3/5] Criando atalho na Area de Trabalho...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell; $d=[Environment]::GetFolderPath('Desktop'); $lnk=Join-Path $d 'PAES MED AI.lnk'; $s=$ws.CreateShortcut($lnk); $s.TargetPath='%PKG%\Iniciar_PAES_MED_AI.bat'; $s.WorkingDirectory='%PKG%'; $ico='%PKG%\branding\app_icon.ico'; if (Test-Path $ico) { $s.IconLocation=$ico }; $s.Description='PAES MED AI - Plataforma de estudos UEMA'; $s.Save(); Write-Host '     [OK] Atalho criado: ' $lnk"

echo.
echo   [4/5] Criando atalho no Menu Iniciar...
set "STARTMENU=%APPDATA%\Microsoft\Windows\Start Menu\Programs\PAES MED AI"
if not exist "%STARTMENU%" mkdir "%STARTMENU%"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell; $lnk=Join-Path '%STARTMENU%' 'PAES MED AI.lnk'; $s=$ws.CreateShortcut($lnk); $s.TargetPath='%PKG%\Iniciar_PAES_MED_AI.bat'; $s.WorkingDirectory='%PKG%'; $ico='%PKG%\branding\app_icon.ico'; if (Test-Path $ico) { $s.IconLocation=$ico }; $s.Description='PAES MED AI - Plataforma de estudos UEMA'; $s.Save(); Write-Host '     [OK] Menu Iniciar: ' $lnk"

echo.
echo   [5/5] Preparando ambiente Python (primeira execucao)...
python -m pip install --upgrade pip --quiet 2>nul
python -m pip install -r "%PKG%\backend\requirements.txt" --quiet
if errorlevel 1 (
  echo   [AVISO] Nao foi possivel instalar dependencias automaticamente.
  echo           Na primeira abertura, o app tentara novamente.
) else (
  echo   [OK] Dependencias Python prontas.
)

echo.
echo   ____________________________________________
echo   INSTALACAO CONCLUIDA COM SUCESSO!
echo   ____________________________________________
echo.
echo   Atalhos criados:
echo     - Area de Trabalho: PAES MED AI
echo     - Menu Iniciar: PAES MED AI
echo.
echo   Para iniciar:
echo     1. Duplo-clique no atalho "PAES MED AI" da Area de Trabalho
echo     2. O app abre automaticamente quando o backend estiver pronto
echo.
echo   Backup automatico:
echo     - Seu progresso e salvo automaticamente a cada dia
echo     - Backups ficam em data\backups\
echo.
echo   Versao do pacote:
type "%PKG%\VERSION.txt"
echo.
pause
exit /b 0
