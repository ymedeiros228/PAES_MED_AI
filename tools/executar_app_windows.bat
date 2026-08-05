@echo off
setlocal
cd /d "%~dp0"
set "PATH=C:\Users\Yuri\flutter\bin;C:\Program Files\Git\cmd;%PATH%"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter nao encontrado em C:\Users\Yuri\flutter\bin
  pause
  exit /b 1
)

if not exist "windows" (
  echo Pasta windows ausente. Rode preparar_projeto_windows.bat
  pause
  exit /b 1
)

echo Backend deve estar em http://127.0.0.1:8000
flutter run -d windows
