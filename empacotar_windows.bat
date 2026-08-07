@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set "PATH=C:\Users\Yuri\flutter\bin;C:\Program Files\Git\cmd;%PATH%"

echo.
echo == PAES MED AI pack · passo 1/5 — limpar processos ==
echo Encerrando app/API se estiverem abertos ^(evita lock do dist^)...
taskkill /F /IM paes_med_ai.exe >nul 2>nul
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *uvicorn*" >nul 2>nul
ping -n 3 127.0.0.1 >nul

echo.
echo == passo 2/5 — build Flutter Windows Release ==
call flutter build windows --release
if errorlevel 1 (
  echo Build Flutter falhou.
  goto :erro
)

echo.
echo == passo 3/5 — montar dist\PAES_MED_AI_Windows ==
set "OUT=dist\PAES_MED_AI_Windows"
if exist "%OUT%" (
  rmdir /s /q "%OUT%" 2>nul
)
if exist "%OUT%" (
  echo Pasta em uso - renomeando stale...
  set "STALE=dist\PAES_MED_AI_Windows_stale_!RANDOM!!RANDOM!"
  move "%OUT%" "!STALE!" >nul 2>nul
)
if exist "%OUT%" (
  echo ERRO: nao deu para liberar %OUT% - feche o app e qualquer explorer em dist\.
  echo PIDs que podem estar segurando lock:
  tasklist /FI "IMAGENAME eq paes_med_ai.exe" 2>nul
  tasklist /FI "IMAGENAME eq python.exe" 2>nul
  tasklist /FI "IMAGENAME eq dart.exe" 2>nul
  echo.
  echo Nao criamos pasta alternativa _AEAH/_AAAD. Feche processos e rode de novo.
  echo Packs legados dist\*_KN *_AAAD *_AEAH *_stale_* podem apagar com o app fechado.
  goto :erro
)
mkdir "%OUT%\app"
mkdir "%OUT%\backend"
mkdir "%OUT%\data\provas"
mkdir "%OUT%\data\gabaritos"
mkdir "%OUT%\data\edital"
mkdir "%OUT%\data\aulas"
mkdir "%OUT%\data\backups"
mkdir "%OUT%\data\inventory"
mkdir "%OUT%\data\logs"
mkdir "%OUT%\branding"

xcopy /e /i /y "build\windows\x64\runner\Release\*" "%OUT%\app\"
if not exist "%OUT%\app\data\flutter_assets" (
  echo ERRO: empacote incompleto - falta app\data\flutter_assets
  echo Feche o app ^(paes_med_ai.exe^) e rode de novo empacotar_windows.bat
  goto :erro
)
if not exist "%OUT%\app\flutter_windows.dll" (
  echo ERRO: falta flutter_windows.dll no pacote.
  goto :erro
)
xcopy /e /i /y "data\edital" "%OUT%\data\edital\"
xcopy /e /i /y "data\inventory" "%OUT%\data\inventory\"
if exist "data\media" xcopy /e /i /y "data\media" "%OUT%\data\media\"
if exist "assets\branding\app_icon.ico" (
  copy /y "assets\branding\app_icon.ico" "%OUT%\branding\" >nul
) else if exist "windows\runner\resources\app_icon.ico" (
  copy /y "windows\runner\resources\app_icon.ico" "%OUT%\branding\app_icon.ico" >nul
)

echo.
echo == passo 4/5 — copiar backend + dados ==
REM Copia todos os .py do backend (exceto __pycache__)
for %%F in (backend\*.py) do copy /y "%%F" "%OUT%\backend\" >nul
copy /y backend\requirements.txt "%OUT%\backend\" >nul
if exist "backend\.env.example" copy /y backend\.env.example "%OUT%\backend\" >nul
copy /y COMO_LIGAR.md "%OUT%\" >nul
if exist "README.md" copy /y README.md "%OUT%\" >nul
if exist "data\ACERVO.md" copy /y "data\ACERVO.md" "%OUT%\data\" >nul
if exist "data\ACERVO_MANIFEST.json" copy /y "data\ACERVO_MANIFEST.json" "%OUT%\data\" >nul
xcopy /e /i /y "data\provas" "%OUT%\data\provas\" >nul 2>nul
xcopy /e /i /y "data\gabaritos" "%OUT%\data\gabaritos\" >nul 2>nul
copy /y PAES_MED_AI_Iniciar.bat "%OUT%\Iniciar_PAES_MED_AI.bat" >nul

REM Verificacao minima do pacote
if not exist "%OUT%\backend\main.py" (
  echo ERRO: main.py nao copiado para dist.
  goto :erro
)
if not exist "%OUT%\backend\db.py" (
  echo ERRO: db.py nao copiado para dist.
  goto :erro
)
if not exist "%OUT%\app\paes_med_ai.exe" (
  echo ERRO: exe nao encontrado no pacote.
  goto :erro
)
if not exist "%OUT%\app\data\app.so" (
  echo ERRO: app\data\app.so ausente - o icone da Desktop nao vai abrir.
  goto :erro
)
if not exist "%OUT%\app\flutter_windows.dll" (
  echo ERRO: flutter_windows.dll ausente apos copias.
  goto :erro
)

REM Gate minimo pos-copia
if not exist "%OUT%\backend\services_extra.py" (
  echo ERRO: services_extra.py ausente no dist.
  goto :erro
)
if not exist "%OUT%\Iniciar_PAES_MED_AI.bat" (
  echo ERRO: launcher ausente no dist.
  goto :erro
)
if not exist "%OUT%\branding\app_icon.ico" (
  echo ERRO: branding\app_icon.ico ausente no pacote.
  goto :erro
)

echo.
echo == passo 5/5 — VERSION + atalho Desktop ==
echo 1.0.0+17> "%OUT%\VERSION.txt"
if not exist "%OUT%\VERSION.txt" (
  echo ERRO: VERSION.txt nao gravado no dist.
  goto :erro
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell; $d=[Environment]::GetFolderPath('Desktop'); $lnk=Join-Path $d 'PAES MED AI.lnk'; $s=$ws.CreateShortcut($lnk); $s.TargetPath=(Resolve-Path '%CD%\%OUT%\Iniciar_PAES_MED_AI.bat').Path; $s.WorkingDirectory=(Resolve-Path '%CD%\%OUT%').Path; $ico=Join-Path '%CD%' '%OUT%\branding\app_icon.ico'; if (Test-Path $ico) { $s.IconLocation=$ico }; $s.Description='PAES MED AI'; $s.Save(); Write-Host \"Atalho: $lnk\""

echo.
echo Pacote: %OUT%
echo Abra apenas o atalho Desktop: PAES MED AI
echo venv permanece no projeto ^(launcher usa PROJECT\.venv^).
echo Pack OK · 5/5.
exit /b 0

:erro
echo Build falhou.
exit /b 1
