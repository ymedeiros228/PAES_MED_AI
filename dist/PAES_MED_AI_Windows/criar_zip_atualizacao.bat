@echo off
chcp 65001 >nul 2>nul
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"

if not exist "Iniciar_PAES_MED_AI.bat" (
  echo ERRO: execute este script dentro da pasta do PAES MED AI.
  pause
  exit /b 1
)

for /f "delims=" %%V in ('powershell -NoProfile -Command "Get-Content VERSION.txt"') do set "VERSION=%%V"
if not defined VERSION (
  echo ERRO: nao foi possivel ler VERSION.txt
  pause
  exit /b 1
)

echo == Empacotando atualizacao PAES MED AI ==
echo Versao: %VERSION%

echo Criando zip...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path 'app','backend','branding','data\provas','data\gabaritos','data\edital','data\aulas','data\inventory','Iniciar_PAES_MED_AI.bat','Instalar_PAES_MED_AI.bat','LEIA-ME.txt','VERSION.txt','atualizar.ps1','Atualizar_PAES_MED_AI.bat' -DestinationPath 'PAES_MED_AI_Windows.zip' -Force"

echo.
echo Zip criado: PAES_MED_AI_Windows.zip
echo.
echo Proximo passo:
echo 1. Vá em https://github.com/%GITHUB_USER%/%GITHUB_REPO%/releases
echo    (substitua %%GITHUB_USER%%/%%GITHUB_REPO%% pelo seu repo)
echo 2. Clique em "Draft a new release"
echo 3. Tag: latest
echo 4. Anexe o arquivo PAES_MED_AI_Windows.zip

echo.
pause
exit /b 0
