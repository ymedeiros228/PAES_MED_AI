# Auto-Pilot — STATUS

## Estado

| | |
|---|---|
| **Estado** | IDLE (pronto para continuar se você relançar Auto-Pilot) |
| **Projeto** | PAES_MED_AI |
| **Última rodada** | GR–GU ship **1.0.0+9** |
| **Branch** | `main` = `origin/main` @ `6f61f73` |
| **Smoke** | 708/708 OK |
| **Pack Desktop** | launcher + ico + exe + VERSION **1.0.0+9** + `.lnk` |
| **Atualizado** | 2026-08-06 |

### O que o Auto-Pilot fez bem (manter)

Micro-ciclos (teclado, soft-landing, erros, sync mobile, etc.) até GN–GQ estavam corretos e já estão em `main`.  
Não era bug — a rodada GR–GU só **mudou o foco** para: pack canônico + F2 “Ler teoria” + gates + ship.

### Como retomar o Auto-Pilot

Use [CONTINUE.md](CONTINUE.md) no chat, ou:

> Analise `.cursor/autopilot` e continue a partir do Auto-Pilot; priorize BLOCKED e CONTINUE.

**Sugestão de missão (evitar micro-tecla infinito):** bugs reais de uso, F1/F3 thin, UX de materiais — não mais R/S por tela.

### Shell host (para o agente)

```
PATH = C:\Users\Yuri\tools\MinGit\cmd;C:\Users\Yuri\flutter\bin;...
smoke: backend\.venv\Scripts\python.exe backend\smoke_test.py
```

Pack: após rebuild, **sempre** restaurar `Iniciar_PAES_MED_AI.bat` + `branding\app_icon.ico` + `VERSION.txt` (xcopy só de `app\` quebra o ícone Desktop).
