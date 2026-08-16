@echo off
chcp 65001 >nul 2>nul
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"
set "ROOT=%CD%"

echo Iniciando PAES MED AI...

REM Verifica se Python esta instalado
python --version >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Python nao encontrado.
  echo Instale Python 3.11+ de https://python.org e marque "Add to PATH".
  start https://python.org/downloads/
  pause
  exit /b 1
)

REM Cria venv se nao existir
if not exist "%ROOT%\backend\.venv" (
  echo [INFO] Primeira execucao: criando ambiente virtual...
  python -m venv "%ROOT%\backend\.venv"
)

REM Verifica se backend ja esta rodando
curl -s http://127.0.0.1:8000/health >nul 2>&1
if errorlevel 1 (
  echo [INFO] Iniciando backend...
  start /min "" cmd /c "cd /d "%ROOT%\backend" && .venv\Scripts\python -m uvicorn main:app --host 127.0.0.1 --port 8000"
  timeout /t 5 /nobreak >nul
) else (
  echo [OK] Backend ja esta rodando.
)

REM Abre o app
echo [INFO] Abrindo PAES MED AI...
start "" "%ROOT%\app\paes_med_ai.exe"

exit /b 0
