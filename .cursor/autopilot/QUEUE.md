# Auto-Pilot — QUEUE (fila operacional)

O AP **pode** reordenar, marcar `[x]`, e puxar **1** item por ciclo.  
Itens novos grandes: human ou PLAN residual — não inventar 20 microtarefas de teclado.

Prioridade: topo = primeiro.

## P0 · travas / pack

- [ ] (vazio) se Desktop órfão ou dist sem `Iniciar_*.bat` / ico → modo **C** imediato

## P1 · Uso real (modo A) — default

- [x] Sessão empties/erros jargão → **HC feito**
- [x] Ficha pós-erro “li teoria → treino” → **HD feito**
- [ ] Soft landing primeiro uso se onboarding + Semana 1 quebrar (só se repro)

## P3 · Ship / gate (modo C ou D)

- [x] Bump **1.0.0+12** (pubspec / Sobre / bat / smoke)
- [ ] Manter `ciclo_gu_pack_*` se dist existir (host)

## P4 · Não fazer (congelado)

- ~~Teclado R/S/F5 em mais telas~~ (saturação GN–GQ)
- ~~PDF inventado / multi-IA / force-push / redesign shell~~
- ~~F4 thin vídeos~~ (já Feito — MediaReinforcement)
- ~~Reabrir F3 Tutor nestes ciclos~~

## Como o AP usa

1. Primeiro checkbox `[ ]` de P0; senão P1; senão P2…  
2. Marca `[x]` + linha em DONE com 1 frase  
3. Se item for grande demais: quebra em 1 thin e deixa resto `[ ]`  

## Notas

- F3 (GY–HA) + 1.0.0+11 shipados na tip; PR #3 fechado (superseded pelo #4 / Mode A).  
- Esta fila evita looping de tecla sem valor.
