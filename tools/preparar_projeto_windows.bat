@echo off
setlocal
cd /d "%~dp0"

REM Flutter instalado em C:\Users\Yuri\flutter (ajuste se mudar)
set "PATH=C:\Users\Yuri\flutter\bin;C:\Program Files\Git\cmd;%PATH%"

echo ==============================================
echo PAES MED AI - Preparacao Flutter Windows
echo ==============================================

where flutter >nul 2>nul
if errorlevel 1 (
  echo ERRO: Flutter nao encontrado. Esperado em C:\Users\Yuri\flutter\bin
  pause
  exit /b 1
)

flutter --version
flutter create --platforms=windows --project-name paes_med_ai .
if errorlevel 1 goto :erro
flutter pub get
if errorlevel 1 goto :erro

echo OK. Use iniciar_backend_windows.bat e depois executar_app_windows.bat
pause
exit /b 0

:erro
echo Falha na preparacao.
pause
exit /b 1
