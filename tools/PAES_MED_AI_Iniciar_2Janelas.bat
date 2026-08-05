@echo off
setlocal
title PAES MED AI - Abrir (2 janelas)
cd /d "%~dp0"

set "PATH=C:\Users\Yuri\flutter\bin;C:\Program Files\Git\cmd;%PATH%"

echo ========================================
echo   PAES MED AI
echo   Abrindo Backend + App em 2 janelas
echo ========================================
echo.

start "PAES MED AI - Backend" cmd /k "title PAES MED AI - Backend && call ""%~dp0iniciar_backend_windows.bat"""
echo Backend: janela "PAES MED AI - Backend"

timeout /t 4 /nobreak >nul

start "PAES MED AI - App" cmd /k "title PAES MED AI - App && cd /d ""%~dp0"" && set ""PATH=C:\Users\Yuri\flutter\bin;C:\Program Files\Git\cmd;%PATH%"" && echo Iniciando Flutter... && flutter run -d windows || (echo. && echo Falha no Flutter. Instale Visual Studio com carga C++ Desktop. && pause)"
echo App: janela "PAES MED AI - App"
echo.
echo Duas janelas abertas. Pode fechar esta.
timeout /t 3 /nobreak >nul
endlocal
