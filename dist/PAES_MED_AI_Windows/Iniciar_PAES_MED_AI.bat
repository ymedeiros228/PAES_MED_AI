@echo off
chcp 65001 >nul 2>nul
cd /d "%~dp0"

echo ============================================
echo    PAES MED AI - Iniciando
echo ============================================
echo.

REM Verifica Python
python --version >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Python nao encontrado!
  echo Instale Python 3.11+ de https://python.org
  echo Marque "Add Python to PATH" durante a instalacao.
  start https://python.org/downloads/
  pause
  exit /b 1
)

REM Cria venv se nao existir
if not exist "%~dp0backend\.venv" (
  echo [1/3] Criando ambiente virtual Python...
  python -m venv "%~dp0backend\.venv"
)

REM Instala dependencias se faltar fastapi
if not exist "%~dp0backend\.venv\Lib\site-packages\fastapi" (
  echo [2/3] Instalando dependencias (primeira vez, pode demorar)...
  "%~dp0backend\.venv\Scripts\python.exe" -m pip install --upgrade pip
  "%~dp0backend\.venv\Scripts\python.exe" -m pip install -r "%~dp0backend\requirements.txt"
) else (
  echo [2/3] Dependencias OK.
)

REM Verifica se backend ja esta rodando
curl -s http://127.0.0.1:8000/health >nul 2>&1
if not errorlevel 1 (
  echo [3/3] Backend ja esta rodando!
  start "" "%~dp0app\paes_med_ai.exe"
  exit /b 0
)

REM Inicia backend
echo [3/3] Iniciando backend...
start "PAES MED AI Backend" /min cmd /k "cd /d %~dp0backend && .venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000"

REM Aguarda backend ficar pronto (max 60 segundos)
echo Aguardando backend iniciar...
set /a contador=0
:ESPERA
timeout /t 2 /nobreak >nul
set /a contador+=2
curl -s http://127.0.0.1:8000/health >nul 2>&1
if not errorlevel 1 goto PRONTO
if %contador% geq 60 goto ERRO_BACKEND
goto ESPERA

:PRONTO
echo Backend pronto! Abrindo aplicativo...
start "" "%~dp0app\paes_med_ai.exe"
exit /b 0

:ERRO_BACKEND
echo.
echo [ERRO] Backend nao iniciou em 60 segundos.
echo Possiveis causas:
echo   - Python nao esta no PATH
echo   - Dependencias nao instaladas
echo   - Porta 8000 em uso
echo.
echo Tente rodar manualmente:
echo   cd backend
echo   .venv\Scripts\python -m uvicorn main:app --port 8000
echo.
pause
exit /b 1
