@echo off
chcp 65001 >nul
title Release PAES MED AI

cd /d "%~dp0.."

REM Pede a versao ao usuario
set /p VERSION="Digite a nova versao (ex: 1.0.0.18): "

if "%VERSION%"=="" (
    echo Versao invalida.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo  RELEASE PAES MED AI v%VERSION%
echo ==========================================
echo.

python tools\release_windows.py %VERSION%

if %errorlevel% neq 0 (
    echo.
    echo Release falhou.
    pause
    exit /b 1
)

echo.
echo Release concluido!
pause
