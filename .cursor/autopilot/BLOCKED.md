# Auto-Pilot — TRAVADO / PARA O CURSOR

Formato: `- [ ] [TÍTULO] | por quê | onde | próxima ação`

## Resolvido

- [x] PR #3 draft | Superseded pelo F3/Mode A | GitHub | Fechado 2026-08-06
- [x] HC–HD Mode A | Sessão PT + ficha teoria→treino | Cloud | ship 1.0.0+12

## Residual aberto

- [ ] dist pack 1.0.0+12 | só no PC Windows | host | Fechar app/explorer e `empacotar_windows.bat`
- [ ] Soft landing Semana 1 | só se repro real | QUEUE P1 | validar no host

## Checklist host Windows (após merge)

1. `git pull origin main`
2. Fechar app + explorer em `dist\`
3. `empacotar_windows.bat` → Desktop **1.0.0+12**
4. Smoke: `backend\.venv\Scripts\python.exe backend\smoke_test.py`
