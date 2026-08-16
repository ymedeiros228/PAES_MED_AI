# Release Automatizado PAES MED AI

## Requisitos

- Python 3.11+
- Flutter (`C:\Users\Yuri\flutter\bin\flutter.bat`)
- Inno Setup 6 (`C:\Program Files (x86)\Inno Setup 6\ISCC.exe`)
- GitHub CLI `gh` logado

## Como lançar uma nova versão

### Opção 1: Um comando

```bash
python tools/release_windows.py 1.0.0.18
```

Isso faz tudo automaticamente:
1. Atualiza `pubspec.yaml`, `lib/core/app_version.dart`, `VERSION`, `installer/paes_med_ai.iss`
2. Build Flutter Windows
3. Build Flutter Web
4. Sincroniza `deploy/data` (banco + PDFs)
5. Compila o instalador Inno Setup
6. Commita e pusha para `main`
7. Cria release no GitHub com o `.exe`

### Opção 2: Duplo clique

Execute `tools/release.bat` e digite a versão.

## Fluxo de update automático para o usuário

1. Usuário com `v1.0.0.17` abre o app
2. Vai em **Configurações → Atualizações**
3. App lê `VERSION.txt` na pasta de instalação
4. Compara com `https://raw.githubusercontent.com/ymederos228/PAES_MED_AI/main/VERSION`
5. Se houver nova versão, clica **Atualizar agora**
6. O app chama `Atualizar_PAES_MED_AI.bat` → `tools/update.ps1`
7. PowerShell baixa `PAESMedAI_Setup_X.X.X.X.exe` do release
8. Setup roda `/SILENT` e atualiza o app (preserva dados)

## Sempre que for publicar

```bash
python tools/release_windows.py X.Y.Z.W
```

Substitua `X.Y.Z.W` pela versão desejada (ex: `1.0.0.18`).
