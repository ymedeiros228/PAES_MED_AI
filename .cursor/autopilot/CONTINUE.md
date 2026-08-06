# Continuar no Cursor a partir do Auto-Pilot

## Cole isto no chat do Cursor (projeto aberto)

```
Analise a pasta .cursor/autopilot e continue a partir do Auto-Pilot.
Leia nesta ordem: PLAN.md → FOCUS.md → QUEUE.md → BLOCKED.md → STATUS.md.
1 item da QUEUE por ciclo, no modo ativo do FOCUS.
Implemente, rode smoke se tocar código, atualize DONE/STATUS/BLOCKED/QUEUE/FOCUS “Agora”.
NÃO edite PLAN.md seções norte (§2–5) nem mude o modo sozinho.
NÃO edite arquivos .cursor/plans/*.plan.md do Plan Mode.
```

Ou: `@.cursor/autopilot`

## Fonte de verdade (ordem)

| Ordem | Arquivo | Papel |
|------:|---------|--------|
| 1 | **PLAN.md** | Plano grande + quando seguir/parar + o que AP pode editar |
| 2 | **FOCUS.md** | Modo calibrado (A–E) + “Agora” |
| 3 | **QUEUE.md** | Fila do que fazer (1 item/ciclo) |
| 4 | BLOCKED.md | Travas |
| 5 | STATUS.md / DONE.md | Runtime e histórico curto |

## O Auto-Pilot pode mexer?

**Sim** em: QUEUE, FOCUS (linha Agora), STATUS, DONE, BLOCKED, live.json, log, control (se a sessão expõe).

**Não** (sem você pedir): mudar **modo** do FOCUS, reescrever norte do PLAN, apagar anti-padrões, editar plans do Plan Mode do Cursor.

## Sessão (metadados — AP pode atualizar timestamps)

- Projeto: `C:\Users\Yuri\Documents\uema estudos\PAES_MED_AI`
- Missão default: modo A (uso real), ver FOCUS.md
- Handoff: `.cursor/autopilot`
- Git host: `C:\Users\Yuri\tools\MinGit\cmd` + `C:\Users\Yuri\flutter\bin` no PATH
- Parar: `control.json` → `{ "action": "stop" }`

## Arquivos

- `PLAN.md` — planejamento grande  
- `FOCUS.md` — calibração de foco  
- `QUEUE.md` — fila  
- `STATUS.md` / `DONE.md` / `BLOCKED.md`  
- `live.json` / `control.json`  
