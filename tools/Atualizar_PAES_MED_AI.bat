@echo off
chcp 65001 >nul
title Atualizador PAES MED AI

REM Atualizador PAES MED AI para Windows
REM Baixa e instala a ultima versao silenciosamente.

set "SCRIPT_DIR=%~dp0"
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT_DIR%tools\update.ps1"

if %errorlevel% neq 0 (
    echo.
    echo Nao foi possivel atualizar automaticamente.
    echo Verifique sua conexao com a internet ou acesse:
    echo https://github.com/ymedeiros228/PAES_MED_AI/releases
    pause
)
