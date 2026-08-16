@echo off
chcp 65001 >nul

REM Atualizador PAES MED AI - executa PowerShell em segundo plano
REM Sem janela preta, sem travar o app.

set "SCRIPT_DIR=%~dp0"
start "" /b "wscript.exe" "%SCRIPT_DIR%update.vbs"
