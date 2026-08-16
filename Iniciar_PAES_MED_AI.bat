@echo off
setlocal EnableExtensions EnableDelayedExpansion
title PAES MED AI

set "HERE=%~dp0"
set "HERE=%HERE:~0,-1%"

set "LOG=%HERE%\data\logs\launcher.log"
if not exist "%HERE%\data\logs" mkdir "%HERE%\data\logs"
echo [%date% %time%] === Iniciando === >> "%LOG%"

if exist "%HERE%\app\paes_med_ai.exe" (
  set "EXE=%HERE%\app\paes_med_ai.exe"
  set "BACKEND=%HERE%\backend"
  set "DATA=%HERE%\data"
) else (
  echo ERRO: exe nao encontrado >> "%LOG%"
  exit /b 1
)

REM Abre o app IMEDIATAMENTE (nao faz o usuario esperar)
echo Abrindo app imediatamente >> "%LOG%"
start "" "!EXE!"

REM Tenta subir o backend em paralelo (nao bloqueia)
set "PY="
where python >nul 2>nul
if not errorlevel 1 set "PY=python"

if defined PY (
  echo Python encontrado: !PY! >> "%LOG%"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $c=Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1; if ($c) { Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue } } catch {}" >nul 2>nul
  set "BOOT=%HERE%\data\logs\_boot_backend.cmd"
  > "%BOOT%" echo @echo off
  >> "%BOOT%" echo set "PAES_DATA_DIR=!DATA!"
  >> "%BOOT%" echo cd /d "!BACKEND!"
  >> "%BOOT%" echo "!PY!" -m uvicorn main:app --host 127.0.0.1 --port 8000 ^>^> "%LOG%" 2^>^&1
  start "PAES MED AI - Backend" /MIN cmd /k call "%BOOT%"
  echo Backend iniciado em paralelo >> "%LOG%"
) else (
  echo Python nao encontrado - app em modo offline >> "%LOG%"
)

echo Done >> "%LOG%"
exit /b 0
