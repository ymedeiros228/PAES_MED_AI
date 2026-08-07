# PAES MED AI

App **local** (Windows) para estudar PAES/UEMA Medicina: Flutter + FastAPI + SQLite.  
Offline-first, sem inventar prova oficial nem % de aprovação.

**Status:** projeto **pessoal / licença controlada** (ver [LICENSE](LICENSE)).  
Não é software livre para o mundo inteiro — o autor pode cobra uso ou liberar só para quem escolher (ex.: primo).

## Conta

- GitHub: [ymedeiros228](https://github.com/ymedeiros228) (repositório preferencialmente **privado**).

## Como rodar (desenvolvimento)

1. Python 3 + venv em `backend/` (`pip install -r requirements.txt`).
2. Flutter Windows; `flutter pub get`.
3. Backend: `uvicorn main:app --reload` a partir de `backend/` (ou o launcher do project).
4. App: `flutter run -d windows` ou pack canônico.

## Pack pro primo (uso no PC)

1. Fechar o app.
2. Rodar `empacotar_windows.bat`.
3. Entregar pasta `dist\PAES_MED_AI_Windows` **ou** atalho Desktop “PAES MED AI”.
4. **Não** copiar `backend/.env` com suas chaves OpenAI/YouTube se for só ele usar sem IA online; chaves ficam no **seu** PC se for o caso.

## O que NÃO vai pro GitHub

- `backend/.env` (chaves)
- `data/*.db`, backups, logs
- `dist/`, `build/`, venv
- ephemera do Flutter Windows

PDFs oficiais em `data/provas` / `data/gabaritos` podem ir no repo **privado** para o primo clonar e usar; se o repo for público no futuro, retire-os.

## Documentação

- [COMO_LIGAR.md](COMO_LIGAR.md) — fluxo de uso e ciclos
- [ROADMAP_FUTURO.md](ROADMAP_FUTURO.md) — ideias futuras

## Smoke (dev)

```text
backend\.venv\Scripts\python.exe backend\smoke_test.py
```
(rode a partir do layout do projeto; ver scripts locais)

Smoke sem alterar a base local:

```text
backend\.venv\Scripts\python.exe backend\smoke_readonly.py
```

## Backups

Backups novos são verificados em `.zip` e a pasta temporária é removida quando a verificação passa. Para auditar backups antigos antes de apagar:

```text
powershell -ExecutionPolicy Bypass -File tools\limpar_backups.ps1 -Keep 10
```

Para aplicar a limpeza:

```text
powershell -ExecutionPolicy Bypass -File tools\limpar_backups.ps1 -Keep 10 -Apply
```

---

© 2026 — todos os direitos reservados (ver LICENSE).  
Uso compartilhado com o primo = com sua autorização; revenda/redistribuição sem acordo = não autorizada.
