@echo off
setlocal EnableExtensions
title PAES MED AI

REM Launcher unico: sobe API local e o exe Windows.
set "HERE=%~dp0"
set "HERE=%HERE:~0,-1%"

REM Preferir pacote dist; senao Release do projeto (sem path hardcoded unico).
set "PROJECT=%HERE%"
if exist "%HERE%\..\..\backend\.venv\Scripts\python.exe" (
  rem dist\PAES_MED_AI_Windows -> sobe 2 niveis ate a raiz do repo
  for %%I in ("%HERE%\..\..") do set "PROJECT=%%~fI"
)
if exist "%HERE%\backend\.venv\Scripts\python.exe" set "PROJECT=%HERE%"
REM Removido path absoluto hardcoded — use venv do pacote ou do projeto relativo.

if exist "%HERE%\app\paes_med_ai.exe" (
  set "ROOT=%HERE%"
  set "EXE=%HERE%\app\paes_med_ai.exe"
  set "BACKEND=%HERE%\backend"
  REM Sempre usar data do projeto quando o repo existe — uma pasta canônica
  if exist "%PROJECT%\data" (
    set "DATA=%PROJECT%\data"
  ) else (
    set "DATA=%HERE%\data"
  )
) else if exist "%HERE%\build\windows\x64\runner\Release\paes_med_ai.exe" (
  set "ROOT=%HERE%"
  set "EXE=%HERE%\build\windows\x64\runner\Release\paes_med_ai.exe"
  set "BACKEND=%HERE%\backend"
  set "DATA=%HERE%\data"
) else if exist "%PROJECT%\build\windows\x64\runner\Release\paes_med_ai.exe" (
  set "ROOT=%PROJECT%"
  set "EXE=%PROJECT%\build\windows\x64\runner\Release\paes_med_ai.exe"
  set "BACKEND=%PROJECT%\backend"
  set "DATA=%PROJECT%\data"
) else (
  echo ERRO: paes_med_ai.exe nao encontrado.
  echo Rode empacotar_windows.bat
  pause
  exit /b 1
)

REM Python: 1) venv do pacote  2) venv do projeto  3) python do PATH
set "PY="
if exist "%BACKEND%\.venv\Scripts\python.exe" set "PY=%BACKEND%\.venv\Scripts\python.exe"
if not defined PY if exist "%PROJECT%\backend\.venv\Scripts\python.exe" set "PY=%PROJECT%\backend\.venv\Scripts\python.exe"
if not defined PY (
  where python >nul 2>nul
  if errorlevel 1 (
    echo ERRO: Python nao encontrado. Instale Python 3 ou rode o backend uma vez no projeto.
    pause
    exit /b 1
  )
  set "PY=python"
)

for %%D in ("%DATA%" "%DATA%\logs" "%DATA%\provas" "%DATA%\gabaritos" "%DATA%\edital" "%DATA%\aulas" "%DATA%\backups") do (
  if not exist %%D mkdir %%D
)

echo ========================================
echo   PAES MED AI
echo ========================================
echo Root: %ROOT%
echo Python: %PY%
echo Backend: %BACKEND%
echo.

echo [%date% %time%] start root=%ROOT% py=%PY% >> "%DATA%\logs\launcher.log"

REM Fecha instancia antiga da API na 8000 (mesmo usuario)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { $c=Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1; if ($c) { Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue } } catch {}" >nul 2>nul

REM Script auxiliar sem aspas aninhadas quebradas pelo espaco no caminho
set "BOOT=%DATA%\logs\_boot_backend.cmd"
> "%BOOT%" echo @echo off
>> "%BOOT%" echo set "PAES_DATA_DIR=%DATA%"
>> "%BOOT%" echo cd /d "%BACKEND%"
>> "%BOOT%" echo if not exist .env if exist .env.example copy /y .env.example .env ^>nul
>> "%BOOT%" echo "%PY%" -m uvicorn main:app --host 127.0.0.1 --port 8000
start "PAES MED AI - Backend" /MIN cmd /k call "%BOOT%"

echo Data: %DATA%
echo Aguardando API em http://127.0.0.1:8000/health ...
set /a TRIES=0
:wait_health
set /a TRIES+=1
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { $r=Invoke-WebRequest -Uri 'http://127.0.0.1:8000/health' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"
if not errorlevel 1 goto health_ok
if %TRIES% GEQ 30 goto health_fail
timeout /t 1 /nobreak >nul
goto wait_health

:health_fail
echo.
echo FALHA: backend nao respondeu em ~30s.
echo Veja a janela "PAES MED AI - Backend" e o log:
echo   %DATA%\logs\backend.log
echo [%date% %time%] health FAIL >> "%DATA%\logs\launcher.log"
pause
exit /b 1

:health_ok
echo API OK.
echo [%date% %time%] health OK >> "%DATA%\logs\launcher.log"
echo Abrindo app...
start "" "%EXE%"
exit /b 0
