@echo off
setlocal EnableExtensions
set "HERE=%~dp0"
set "HERE=%HERE:~0,-1%"

REM Sobe dois niveis: tools/ -> raiz do app
set "ROOT=%HERE%\.."

REM Acha Python
set "PY="
for %%P in (python.exe) do (
  if exist "%%~$PATH:P" set "PY=%%~$PATH:P"
)
if not defined PY (
  if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python313\python.exe" (
    set "PY=C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python313\python.exe"
  )
)
if not defined PY (
  if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python312\python.exe" (
    set "PY=C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python312\python.exe"
  )
)
if not defined PY (
  if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python311\python.exe" (
    set "PY=C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python311\python.exe"
  )
)
if not defined PY (
  if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python310\python.exe" (
    set "PY=C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python310\python.exe"
  )
)

if not defined PY (
  echo Python nao encontrado. Instale do site python.org
  pause
  exit /b 1
)

REM Executa o atualizador visual (tkinter)
start "" "!PY!" "%HERE%\updater_gui.py"
exit /b 0
