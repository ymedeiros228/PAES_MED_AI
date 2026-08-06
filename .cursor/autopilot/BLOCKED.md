# Auto-Pilot — TRAVADO / PARA O CURSOR

Itens que o Auto-Pilot **não conseguiu** concluir sozinho.
Formato: `- [ ] [TÍTULO] | por quê | onde | próxima ação`

## Resolvido (host + Cloud)

- [x] dist pack | launcher + ico + exe + VERSION + Desktop .lnk | host
- [x] PR #1 draft | Conteúdo já em main | GitHub | Fechado 2026-08-06
- [x] PR #2 | Mergeado em main | GitHub | —
- [x] git para o agente Windows | MinGit em `C:\Users\Yuri\tools\MinGit\cmd` (prefixar PATH) | host/scripts
- [x] flutter | `C:\Users\Yuri\flutter\bin` | prefixar PATH
- [x] land GV–GW | branch `cursor/continue-f1-deep-2d73` @ 1.0.0+10 | Cloud

## Residual aberto

- [ ] dist pack 1.0.0+11 | `dist\` só no PC; rebuild após merge F3 | host | Fechar app/explorer e rodar `empacotar_windows.bat`
- [ ] F3 deep Tutor | em andamento GY–HA | Cloud | ver STATUS.md

## Checklist host Windows (após merge F3)

1. `git pull origin main`
2. Fechar app + explorer em `dist\`
3. `empacotar_windows.bat` → Desktop alinhado com **1.0.0+11**
4. Smoke: `backend\.venv\Scripts\python.exe backend\smoke_test.py`
