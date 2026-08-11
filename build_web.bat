@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set "PATH=C:\Users\Yuri\flutter\bin;C:\Program Files\Git\cmd;%PATH%"

echo.
echo == PAES MED AI — build web ==

REM URL da API: em deploy unificado (Render), o front e a API sao o mesmo host.
REM Em deploy separado (Vercel front + Render API), passe a URL da API:
REM   set "API_URL=https://paes-med-ai.onrender.com"
REM e descomente a linha --dart-define abaixo.
set "API_URL=%API_URL%"

echo Compilando Flutter web...
if "%API_URL%"=="" (
  call flutter build web --release --wasm
) else (
  call flutter build web --release --wasm --dart-define=API_BASE_URL=%API_URL%
)
if errorlevel 1 (
  echo Build Flutter web falhou.
  goto :erro
)

echo.
echo Build web em: build\web
echo Para testar local: cd build\web ^&^& python -m http.server 8080
echo Para deploy: copie build\web para Vercel/Netlify, OU rode o backend
echo   (que serve build/web automaticamente se existir).
echo.
echo Build web OK.
exit /b 0

:erro
echo Build web falhou.
exit /b 1
