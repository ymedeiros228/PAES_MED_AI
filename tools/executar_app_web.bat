@echo off
setlocal
cd /d "%~dp0"
where flutter >nul 2>nul
if errorlevel 1 (
  echo ERRO: Flutter nao foi encontrado no PATH.
  pause
  exit /b 1
)
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
if errorlevel 1 pause
