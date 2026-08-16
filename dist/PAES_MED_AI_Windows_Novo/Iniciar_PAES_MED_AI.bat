@echo off
chcp 65001 >nul 2>nul
cd /d "%~dp0"

echo Iniciando PAES MED AI...

REM Inicia backend em janela minimizada separada
start "PAES MED AI Backend" /min cmd /k "cd /d %~dp0backend && python -m uvicorn main:app --host 127.0.0.1 --port 8000"

REM Aguarda backend ficar pronto (max 30 segundos)
echo Aguardando backend...
set /a contador=0
:ESPERA
timeout /t 1 /nobreak >nul
set /a contador+=1
curl -s http://127.0.0.1:8000/health >nul 2>&1
if not errorlevel 1 goto PRONTO
if %contador% geq 30 goto ERRO_BACKEND
goto ESPERA

:PRONTO
echo Backend pronto! Abrindo app...
start "" "%~dp0app\paes_med_ai.exe"
exit /b 0

:ERRO_BACKEND
echo [ERRO] Backend nao respondeu em 30 segundos.
echo Verifique se Python esta instalado: python --version
echo.
pause
exit /b 1
