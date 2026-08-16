import os, shutil, subprocess, json, datetime
from pathlib import Path

root = Path("C:/Users/Yuri/Documents/uema estudos/PAES_MED_AI")
dist = root / "dist" / "PAES_MED_AI_Windows_Novo"
release = root / "build" / "windows" / "x64" / "runner" / "Release"
data = root / "data"
backend = root / "backend"
branding = root / "assets" / "branding"

# Limpa dist
if dist.exists():
    shutil.rmtree(dist, ignore_errors=True)
dist.mkdir(parents=True, exist_ok=True)

# Copia app
shutil.copytree(release, dist / "app", dirs_exist_ok=True)

# Copia backend
shutil.copytree(backend, dist / "backend", dirs_exist_ok=True)

# Copia branding
shutil.copytree(branding, dist / "branding", dirs_exist_ok=True)

# Copia dados essenciais (sem backups - eles sao gerados localmente)
for sub in ["provas", "gabaritos", "edital", "aulas", "inventory", "materiais", "media"]:
    src = data / sub
    dst = dist / "data" / sub
    if src.exists():
        shutil.copytree(src, dst, dirs_exist_ok=True)
    else:
        dst.mkdir(parents=True, exist_ok=True)

# Arquivos soltos do data
for f in ["ACERVO.md", "ACERVO_MANIFEST.json", "perfil_banca.md"]:
    src = data / f
    if src.exists():
        shutil.copy2(src, dist / "data" / f)

# Pastas vazias para uso do usuario
for sub in ["backups", "exports", "logs"]:
    (dist / "data" / sub).mkdir(parents=True, exist_ok=True)

# CONTEUDO_PROGRAMATICO na raiz
cp = root / "CONTEUDO_PROGRAMATICO_PAES.md"
if cp.exists():
    shutil.copy2(cp, dist / "CONTEUDO_PROGRAMATICO_PAES.md")

# Copia banco
shutil.copy2(data / "paes_med_ai.db", dist / "data" / "paes_med_ai.db")

# VERSION.txt
version = "1.0.0+20"
commit = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=root, text=True).strip()
branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=root, text=True).strip()
with open(dist / "VERSION.txt", "w", encoding="utf-8") as f:
    f.write(f"{version}\n")
    f.write(f"branch: {branch}\n")
    f.write(f"commit: {commit}\n")
    f.write(f"built: {datetime.datetime.now().isoformat()}\n")

# Copia launchers
for f in ["Iniciar_PAES_MED_AI.bat", "Instalar_PAES_MED_AI.bat", "LEIA-ME.txt", "atualizar.ps1", "Atualizar_PAES_MED_AI.bat", "criar_zip_atualizacao.bat"]:
    src = root / "dist" / "PAES_MED_AI_Windows" / f
    if src.exists():
        shutil.copy2(src, dist / f)

# Atualiza icone no executavel (copia do windows runner)
app_ico_src = root / "windows" / "runner" / "resources" / "app_icon.ico"
if app_ico_src.exists():
    shutil.copy2(app_ico_src, dist / "branding" / "app_icon.ico")

print(f"Empacotado em: {dist}")
print(f"Tamanho total: {sum(f.stat().st_size for f in dist.rglob('*') if f.is_file()) / 1024 / 1024:.1f} MB")
