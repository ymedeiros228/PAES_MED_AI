# Auto-Pilot — STATUS

## Cloud Agent — F1 deep GV–GW (ship 1.0.0+10) → F3 deep next

| | |
|---|---|
| **Estado** | DONE (product GV–GW) / F3 deep IN_PROGRESS |
| **Projeto** | PAES_MED_AI |
| **Ciclo** | GV–GW feito; próximo GY–HA (F3 Tutor) |
| **Versão** | 1.0.0+10 (alvo F3: 1.0.0+11) |
| **Branch** | `cursor/continue-f1-deep-2d73` → merge main → `cursor/f3-deep-tutor-2d73` |
| **Atualizado** | 2026-08-06 |

### Missão encerrada (GV–GW)

Card Acervo no Dashboard + gates honestidade 2017–23 + ship **1.0.0+10**.

### Agora (F3 deep)

1. GY: grounding por pergunta + `/api/tutor/ask` + aliases cite.
2. GZ: UI block sem fonte + chips.
3. HA: `preferOfficial` + Natureza e2e.
4. Ship **1.0.0+11**.

### Host Windows (residual)

1. `git pull origin main`
2. Fechar app + explorer em `dist\`
3. `empacotar_windows.bat`
4. Smoke: `backend\.venv\Scripts\python.exe backend\smoke_test.py`

Ver também `PLAN.md` / `FOCUS.md` / `QUEUE.md` (calibração long-run do host).
