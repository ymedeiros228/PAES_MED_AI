@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "HERE=%~dp0"
set "HERE=%HERE:~0,-1%"

REM Garante pasta de logs para diagnostico
if not exist "%HERE%\data\logs" mkdir "%HERE%\data\logs"
set "LOG=%HERE%\data\logs\launcher.log"
echo [%date% %time%] === Iniciando === >> "%LOG%"

if exist "%HERE%\app\paes_med_ai.exe" (
  echo Abrindo app: %HERE%\app\paes_med_ai.exe >> "%LOG%"
  start "" "%HERE%\app\paes_med_ai.exe"
  echo Done >> "%LOG%"
  exit /b 0
)

echo ERRO: %HERE%\app\paes_med_ai.exe nao encontrado >> "%LOG%"
exit /b 1
