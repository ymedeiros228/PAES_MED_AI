# Auto-Pilot — FOCO CALIBRADO

Atualizado: 2026-08-06  
Ler **depois** de [PLAN.md](PLAN.md).

## Modo ativo

| Campo | Valor |
|-------|--------|
| **Modo** | **A · Uso real** |
| **Secundário** | B · Material thin (só se fila A vazia) |
| **Evitar** | Micro-teclas R/S por tela; redesign; PDF inventado |
| **Versão alvo** | **1.0.0+10** (ship HJ–HM); residual = gab host 2014–23 |

## Quem mexe no quê

| Você (humano) | Auto-Pilot (Cursor) |
|---------------|---------------------|
| Define **modo** (A/B/C/D/E) | Preenche **Agora / Próximo / Fez** |
| Pode editar PLAN norte §2–5 | Edita **só** tabela abaixo + QUEUE |
| `control.json` stop | STATUS / DONE / BLOCKED / log |
| Planos em `.cursor/plans/*.plan.md` | **Não edita** esses planos |

**O Auto-Pilot PODE e DEVE mexer** em: STATUS, DONE, BLOCKED, QUEUE, live.json, log.txt, e a tabela **Agora** deste FOCUS.  
**Não deve reescrever sozinho** o modo ativo nem o PLAN mestre (exceto § “Ajustes do ciclo” / fila dinâmica).

## Agora (AP atualiza)

| | |
|---|---|
| **Agora** | — idle; ciclo 10 concluído |
| **Próximo** | fila vazia — aguarda humano |
| **Último feito** | HJ–HM: parser, import-all, oficiais-com-gab, **1.0.0+10** |

## Prompt curto para missões novas (cole no Auto-Pilot)

```
Missão: modo A (uso real). Ler .cursor/autopilot/PLAN.md + FOCUS.md + QUEUE.md.
1 item da QUEUE por ciclo. Smoke verde. Atualize DONE/STATUS/BLOCKED/QUEUE.
Não micro-teclas R/S por tela. Não inventar PDF. Pack: nunca deixar dist sem launcher+ico.
Git: PATH MinGit + flutter se commit/push; sem force. Host se travar em git/pack.
```

## Checklist de calibração (30s no início do ciclo)

1. [ ] Li PLAN §2–4 e FOCUS **modo ativo**  
2. [ ] Peguei **1** item da QUEUE (não 10)  
3. [ ] Não estou repetindo teclado já coberto  
4. [ ] Se mexer em dist → restaurar launcher+ico+VERSION  
5. [ ] No fim: DONE + STATUS + (smoke se código)

## Se você quiser “calibrar” de novo

Edite **só** a linha **Modo** na tabela “Modo ativo”, ou diga no chat:

> Muda o Auto-Pilot para modo B (material)

Sem você mudar o modo, o AP **não** promove reescrita de foco “porque achou melhor”.
