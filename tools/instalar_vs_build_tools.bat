@echo off
setlocal
title Instalar VS Build Tools (C++) para PAES MED AI
echo Este instalador precisa de rede e pode demorar 20-45 minutos.
echo Workload: Desktop development with C++ / VCTools
echo.
pause

where winget >nul 2>nul
if errorlevel 1 (
  echo winget nao encontrado. Baixe Build Tools em:
  echo https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
  echo Marque: Desktop development with C++
  pause
  exit /b 1
)

winget install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-package-agreements --accept-source-agreements --override "--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --add Microsoft.VisualStudio.Component.Windows11SDK.22621"
if errorlevel 1 (
  echo Tentando Community...
  winget install --id Microsoft.VisualStudio.2022.Community -e --accept-package-agreements --accept-source-agreements --override "--wait --quiet --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended"
)

echo.
echo Pronto. Feche e abra o terminal, depois:
echo   flutter doctor
echo   PAES MED AI na Desktop
pause
