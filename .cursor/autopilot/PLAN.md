# PAES MED AI — Plano mestre do Auto-Pilot

> **Fonte de verdade da direção.**  
> Leia isto no início de **cada** ciclo, **antes** de STATUS/DONE.  
> Atualizado: 2026-08-06 · produto **1.0.0+11** (alvo Mode A **+12**)

---

## 1. Posso mexer neste plano?

| Arquivo | Auto-Pilot pode | Quem é “dono” |
|---------|-----------------|---------------|
| **PLAN.md** (este) | Só seções **§ Ajustes do ciclo** e **§ Fila dinâmica** | Você = norte; AP = fila fina |
| **FOCUS.md** | Atualizar “agora / próximo / evitado hoje” (curto) | Você redefine o **modo**; AP preenche o **agora** |
| **QUEUE.md** | Reordenar, marcar feito, puxar 1 item | AP livre dentro da fila |
| **STATUS / DONE / BLOCKED / log / live** | Sim, sempre | AP |
| **CONTINUE.md** | Podem atualizar “sessão atual”; **não** mudar o prompt base sem você pedir | Misto |
| `.cursor/plans/*.plan.md` do Cursor (Plan Mode) | **Não** — planos de chat/plan mode não editar | Você / chat |

**Regra de ouro:** se o Auto-Pilot quiser **mudar de modo** (ex.: sair de “produto thin” e voltar a “micro-tecla infinita”), **não muda o PLAN sozinho** — escreve em BLOCKED:  
`quer mudança de modo: X → Y | motivo` e termina o ciclo.

---

## 2. Quando seguir / quando parar

### Seguir (ciclo verde)

1. `control.json` **não** manda `stop`.
2. Há item em **QUEUE.md** (ou residual real em BLOCKED).
3. Smoke suite **não** está vermelha por causa da última mudança (ou você reverte/fixa antes de avançar).
4. Não está travado em git/pack **no agente** sem saída documentada em BLOCKED.

### Parar / handoff humano

- `control.json` → `{ "action": "stop" }`
- 2 ciclos seguidos sem valor de uso (só churn de string/smoke cosmético)
- Precisa force-push, secrets, `.env`, ou inventar PDF/edital
- Pack Desktop partial (só `app\`) **sem** restaurar launcher+ico → **corrigir pack** antes de feature nova
- Sessão de horas (ex. 1h) acabou → atualiza STATUS + CONTINUE e para limpo

### Depois de ship grande (ex. GR–GU)

- **1 ciclo só** de estabilização (smoke + pack se sujou)
- Depois retoma **QUEUE** pelo modo atual do FOCUS — **não** reinicia stack de micro-teclas

---

## 3. Modos de foco (calibração)

O Auto-Pilot roda **um modo por vez** (marcado em FOCUS.md).

| Modo | O que faz | Máx. por ciclo | Proibido |
|------|-----------|----------------|----------|
| **A · Uso real** | Bug que trava estudo, empty/error legível, CTA ≤2 cliques | 1 bug ou 1 thin | redesign, multi-IA |
| **B · Material / F2–F3** | teoria, biblioteca, open-path, empty honesto | 1 fatia thin | scraper, inventar ano PDF |
| **C · Ship / pack** | dist, VERSION, launcher, ico, Desktop .lnk, gates smoke | pack + smoke | features soltas |
| **D · Hardening** | smoke gate, human errors, health soft | 1–2 checks | teclado R/S por tela |
| **E · Exploração** | só se QUEUE vazia: 1 ideia pequena + smoke | 1 | commit de 15 arquivos “melhorias” |

**Default pós-GR–GU:** modo **A**, com fila **B** em segundo.

**Anti-padrão calibrado:** microciclos de teclado R/S/`F5` por tela (já saturado na rodada GN–GQ). Só voltar se **você** colocar item explícito na QUEUE.

---

## 4. Definition of Done (todo ciclo)

1. Mudança pequena e **testável no uso** (ou gate de pack/smoke).
2. `smoke_test.py` verde (prefixo `ciclo_*` se criou check novo).
3. Atualiza: DONE (1 bullet), STATUS (agora), QUEUE (check), BLOCKED se travou.
4. **Não** commit de: `.env`, `*.db`, `dist/`, logs grandes, exports.
5. Git: se PATH tem MinGit (`C:\Users\Yuri\tools\MinGit\cmd`) + Flutter (`C:\Users\Yuri\flutter\bin`), commit autor **Yuri Medeiros** + push quando host permitir; senão marca BLOCKED sem inventar git.

### Pack (sempre)

Se tocar/rebuild pack:

- `Iniciar_PAES_MED_AI.bat`
- `branding\app_icon.ico` (ou source `assets\branding\` + bat grava)
- `VERSION.txt` alinhado a `pubspec`
- Nunca deixar dist “só app\”

---

## 5. Fora de escopo (fixo, não discute sozinho)

- SaaS cobrando aluno / % de aprovação mágica  
- Multi-IA / inventário UEMA completo em um ciclo  
- force-push `main`  
- Redesenhar shell inteiro  
- `stats/predict` fantasia  
- PDF inventado  

---

## 6. Fila dinâmica (AP edita)

A fila **operacional** é [QUEUE.md](QUEUE.md). Este plano só define **política**.

Se a QUEUE esvaziar no modo A: puxar 1 item honesto de residual ROADMAP (F1/F3 thin) **ou** parar com STATUS “fila vazia — aguarda humano”.

---

## 7. Ajustes do ciclo (AP pode preencher)

_Use no máximo 5 linhas por ciclo._

```
<!-- ciclo: HC–HD Mode A
modo: A
item: Sessão sem jargão + ficha teoria→treino
smoke: ciclo_hc_* / ciclo_hd_*
nota: ship alvo 1.0.0+12; PR #3 fechado
-->
```

---

## 8. Histórico de modos (humano)

| Data | Evento | Modo |
|------|--------|------|
| 2026-08 pré | Microciclos teclado/erros/sync | E/A mistura (autopilot OK) |
| 2026-08-05/06 | GR–GU pack + F2 teoria + 1.0.0+9 | C + B thin → ship |
| 2026-08-06 | F1 GV–GW + F3 GY–HA → 1.0.0+11 | B/F3 → ship |
| 2026-08-06+ | Pós-F3 · Mode A HC–HD | **A** default |
