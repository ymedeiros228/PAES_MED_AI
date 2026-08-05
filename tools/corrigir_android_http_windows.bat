@echo off
setlocal
cd /d "%~dp0"
if not exist "android\app\src\main\AndroidManifest.xml" (
  echo Execute preparar_projeto_windows.bat primeiro.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='android/app/src/main/AndroidManifest.xml'; $s=Get-Content $p -Raw; if($s -notmatch 'usesCleartextTraffic'){ $s=$s -replace '<application', '<application android:usesCleartextTraffic=\"true\"'; Set-Content $p $s -Encoding utf8 }; Write-Host 'Android preparado para API HTTP local.'"
pause
