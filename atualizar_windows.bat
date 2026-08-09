@echo off
setlocal EnableExtensions
cd /d "%~dp0"
set "PATH=C:\Users\Yuri\flutter\bin;C:\Program Files\Git\cmd;%PATH%"
set "DEMO_BRANCH=devin/demo-cliente"
set "PACKAGE=dist\PAES_MED_AI_Windows"

echo.
echo == PAES MED AI ^| atualizacao para demonstracao ==
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo ERRO: o Git nao foi encontrado no PATH.
  echo Instale o Git ou confira o caminho antes de tentar novamente.
  goto :erro
)

if not exist "empacotar_windows.bat" (
  echo ERRO: empacotar_windows.bat nao foi encontrado na pasta do projeto.
  goto :erro
)

echo == passo 1/5 - verificar alteracoes locais ==
for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERRO: existem alteracoes locais nao salvas.
  echo Salve, descarte ou faca commit dessas alteracoes antes de atualizar.
  goto :erro
)

echo == passo 2/5 - buscar atualizacoes ==
git fetch origin
if errorlevel 1 (
  echo ERRO: nao foi possivel buscar as atualizacoes do repositorio.
  echo Confira sua conexao e tente novamente.
  goto :erro
)

git show-ref --verify --quiet "refs/remotes/origin/%DEMO_BRANCH%"
if errorlevel 1 (
  echo ERRO: a branch %DEMO_BRANCH% nao existe no repositorio remoto.
  goto :erro
)

git switch "%DEMO_BRANCH%" >nul 2>nul
if errorlevel 1 (
  git switch --track -c "%DEMO_BRANCH%" "origin/%DEMO_BRANCH%"
  if errorlevel 1 (
    echo ERRO: nao foi possivel mudar para a branch %DEMO_BRANCH%.
    echo Verifique se nao ha outra branch ou processo bloqueando o repositorio.
    goto :erro
  )
)

git pull --ff-only origin "%DEMO_BRANCH%"
if errorlevel 1 (
  echo ERRO: a branch nao pode ser atualizada automaticamente.
  echo Resolva a divergencia ou alteracao local e rode este atalho novamente.
  goto :erro
)

echo == passo 3/5 - empacotar a build ==
call "%~dp0empacotar_windows.bat"
if errorlevel 1 (
  echo ERRO: o empacotamento falhou.
  goto :erro
)

if not exist "%PACKAGE%\VERSION.txt" (
  echo ERRO: o pacote foi criado sem VERSION.txt.
  goto :erro
)

echo == passo 4/5 - registrar a versao da build ==
if not exist "pubspec.yaml" (
  echo ERRO: pubspec.yaml nao foi encontrado para identificar a versao.
  goto :erro
)
for /f "tokens=2" %%V in ('findstr /b /c:"version:" pubspec.yaml') do set "APP_VERSION=%%V"
if not defined APP_VERSION (
  echo ERRO: nao foi possivel ler a versao de pubspec.yaml.
  goto :erro
)
for /f "delims=" %%H in ('git rev-parse --short HEAD') do set "COMMIT=%%H"
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "STAMP=%%T"
if not defined COMMIT (
  echo ERRO: nao foi possivel identificar o commit da build.
  goto :erro
)
> "%PACKAGE%\VERSION.txt" echo %APP_VERSION% - commit %COMMIT% - empacotado em %STAMP%

if not exist "%PACKAGE%\VERSION.txt" (
  echo ERRO: nao foi possivel gravar a identificacao da build.
  goto :erro
)

echo == passo 5/5 - concluir ==
echo Build atualizada com sucesso.
echo Pacote: %PACKAGE%
echo Commit: %COMMIT%
echo Data e hora: %STAMP%
echo O atalho PAES MED AI usa este pacote atualizado.
exit /b 0

:erro
echo.
echo Atualizacao interrompida. Nenhuma build nova foi confirmada.
exit /b 1
