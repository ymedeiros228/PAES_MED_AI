@echo off
chcp 65001 >nul 2>nul
setlocal EnableExtensions

REM Atualizador PAES MED AI
REM Chama o PowerShell com permissao para baixar a ultima versao do GitHub

cd /d "%~dp0"
set "HERE=%~dp0"
set "HERE=%HERE:~0,-1%"

powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -Command "& { Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0atualizar.ps1\" -InstallDir \"%~dp0\"' -Verb runAs }"

exit /b 0
