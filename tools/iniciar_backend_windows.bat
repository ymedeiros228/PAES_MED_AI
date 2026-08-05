@echo off
setlocal
cd /d "%~dp0backend"

where python >nul 2>nul
if errorlevel 1 (
  echo ERRO: Python nao foi encontrado no PATH.
  pause
  exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
  python -m venv .venv
  if errorlevel 1 goto :erro
)

call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
pip install -r requirements.txt
if errorlevel 1 goto :erro

if not exist ".env" (
  copy .env.example .env >nul
  echo.
  echo O arquivo backend\.env foi criado.
  echo Abra-o e substitua cole_sua_chave_aqui pela sua chave da OpenAI.
  notepad .env
  pause
)

python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
goto :eof

:erro
echo Falha ao iniciar o backend.
pause
exit /b 1
