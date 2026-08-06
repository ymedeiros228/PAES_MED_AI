# PAES MED AI — Como ligar

## Um clique (único caminho)

Na **Desktop**, use só o atalho com ícone: **PAES MED AI**

Ele abre `dist\PAES_MED_AI_Windows\Iniciar_PAES_MED_AI.bat` → sobe a API local e o app nativo.

Não use outros `.bat` / `.lnk` antigos na Desktop.

## Depois de atualizar o código

Feche o app (evita lock do exe) e rode:

```bat
empacotar_windows.bat
```

Isso rebuilda o exe, atualiza `dist\` e (se o script criar) refresca o atalho.

## Scripts de desenvolvimento

Ficam em `tools\` (não use no dia a dia):

- `iniciar_backend_windows.bat`
- `executar_app_windows.bat` (`flutter run`)
- `PAES_MED_AI_Iniciar_2Janelas.bat`
- etc.

Na raiz do projeto (dev): `PAES_MED_AI_Iniciar.bat` também sobe API + Release do projeto.

## Semana 1 real (Ciclo S)

1. Biblioteca → **Semana 1 real (2024–26)** — fetch+commit found + dialog de saúde por ano + pack Natureza.
2. Se sem PDFs / fetch falhou: playbook **Portal / Abrir provas / Abrir gabaritos / Tentar de novo / Commitar disco**.
3. Dashboard / Fila: bloco **Fecho da semana** (due + gaps + Sessão Natureza / Simulado / Fila due).
4. Com **≥10 oficiais**: banner **Base oficial ativa** (treino→oficial).

## Semana 1 oficial (Ciclo Q) + Histórico (R)

1. Board 2024–26: Fetch / Commitar / Estudar por ano; gate soft de parse.
2. Fim de sessão: painel Domínio.
3. Histórico 2017–23: drop PDF → Commitar ano / todos no disco.
4. Edital sync → teoria; Medicina: Aceitar/Editar/Pular rascunhos; simulado com relatório acionável.

## Recuperar lacunas (Ciclo T)

1. Erro em questão **abre gap** (mesmo em TREINO).
2. Fim de sessão Domínio → **Remediar agora** (adaptativo do tópico).
3. Dashboard / Fila: bloco **Recuperar lacunas** → Treinar.
4. **Recovered** = 2 acertos seguidos no tópico **ou** flashcard remembered + 1 acerto.

## Acervo oficial (Ciclo W)

1. Biblioteca → **Semana 1 real (2024–26)** (fetch UEMA + commit altas) **ou** drope `paes_YYYY.pdf` + `gabarito_YYYY.pdf` → Commitar disco.
2. Playbook: **Portal** abre o site UEMA no navegador; Abrir provas/gabaritos; Tentar de novo.
3. Com **≥10 oficiais**: Dashboard **Base oficial ativa** (`officialUnlocked`).
4. Saúde por ano (Bio/Qui/Fis) no dialog pós-Semana 1 / Biblioteca.

## Estudo diário (Ciclo X)

1. **Domínio** → tap no tópico abre **Sessão** com `subject`/`topic` (Natureza se Bio/Qui/Fis).
2. **Fila** ordem: lacunas → due (SRS leve 1/3/7…) → meta do dia → Domínio.
3. Sessão/today honram deep-link: `/sessao?examBoard=UEMA_PAES&subject=…&topic=…`.
4. Medicina: **5–10 drafts do dia** (Natureza-first). Reclassificar: Biblioteca/API `classify-pending`.

## Curadoria Natureza (Ciclo Y)

1. **Medicina** / `/health` / `GET /api/curation/inventory`: oficiais, `realCount` / % reais, `crossDomainCount` — números da base, sem inventar.
2. **Reclassificar Natureza** (Medicina ou `POST /api/ingest/classify-pending`): corrige subject/topic e tópicos cross-domain (ex. Literatura sob Física).
3. Fila professor: só Natureza **template|draft**. **batch-fill ≠ resolvido** — gera draft 4 eixos.
4. **Aceitar** (ou **Floor real** / `POST /api/curation/promote-natureza-real`): grava `resolutionQuality=real`.
5. Domínio ordena curated primeiro; badge **curado / sujo / natureza / pendente**.

## Rotina diária (Ciclo C)

1. **Hoje**: linha de coach (`dailyRoutine.line`) + **Começar sessão** no tópico do dia (Natureza se curado).
2. Checklist do dia: sessão (~15+ min) · cards due · lacunas/revisões.
3. Fim de sessão: **Remediar lacuna** ou **Ir à fila** (sem 5 botões).
4. Lembrete de backup em Ajustes se >7 dias sem backup verificado.
5. Empacotar: feche o app antes — `empacotar_windows.bat` tenta encerrar `paes_med_ai.exe` e falha cedo se `dist\` estiver travado.

## Dia a dia estável (Ciclo D)

1. **Ajustes / Seus dados**: linha **Natureza estável** (floor real + cross-domain) — números da base.
2. `GET /api/curation/health`: gate anti-regressão (`naturezaFloorOk`).
3. **batch-fill não reduz** `realCount`; pula itens já `real`.
4. **Floor outras áreas** (`POST /api/curation/promote-other-real`) não mexe em Natureza; Domínio prioriza curated Natureza.
5. **Fila** usa `dailyRoutine.sessionPath` do coach do dia.

## Entrega semanal (Ciclo E)

1. **Hoje**: barra da **semana** (meta 300 min / 5 dias — local, não oficial UEMA).
2. Checklist: sessão · cards · lacunas · **Encerrar dia** (`POST /api/study/day-close`).
3. Fim de sessão / simulado: CTAs curtos (fila, remediar, Hoje).
4. `GET /api/curation/axles` + **Floor completo** no Domínio (Natureza → outras).
5. Smoke inclui `ciclo_e_*`.

## Contagem + prontidão (Ciclo F)

1. **Ajustes** → data da prova grava local e sincroniza (`POST /api/study/exam-date`).
2. **Hoje**: contagem regressiva no hero; fases long/mid/sprint/final só mudam o tom do coach.
3. **Prontidão** (0–100): pulso local (acerto, minutos, streak, lacunas, cards, base real) — **não** é probabilidade de aprovação.
4. **Calendário 28 dias**: ● estudou · ✓ encerrou o dia.
5. **Encerrar semana** (`POST /api/study/week-close`) quando a meta da semana faz sentido.
6. Smoke: `ciclo_f_*`.

## Loop diário fechado (Ciclo G)

1. Erro em sessão **agenda lacunas** (`schedule-gaps`) + mastery com Remediar · Fila · Encerrar dia.
2. Pós-erro padrão: **Treino adaptativo** do tópico; sessão longa é secundária.
3. **Cards** abrem only-due; toggle “Ver todos”.
4. Adaptive: fim de fila com resumo + atalho 1–5/Enter; **sem stubs** (`nGenerated=0`).
5. **Modo foco** permite Cards, Fila, Revisões, Adaptativo — só ejetam Banco/Aulas/etc. avançados.

## Honestidade (Ciclo H)

1. Domínio/questão: **score de prioridade local** — não “% de incidência UEMA” nem de aprovação.
2. Simulado sério **nunca** inclui questões `generated` (stubs).
3. Resolução **real** exige eixos (comando/conceito/gabarito/distrator).
4. Pulso do Hoje = indicador local, não ranking de aprovação.

## Acervo operacional (Ciclo I)

1. Biblioteca com **ordem fixa** 0-oficiais: Portal → Pastas → Atualizar 2024–26 → Estudar.
2. Pós Semana 1: **reclassificar** Natureza automático 1x.
3. Parse-gate + health com contagens; floor Natureza no health.
4. Histórico 2017–23: drop PDF + commit (sem prometer ano sem arquivo).

## Tutor offline + ship (Ciclo J)

1. Tutor **sem key**: trechos de resolução do tópico do dia + hot + sessionPath.
2. Empty tutor: chips Meta / Macete / Sessão.
3. Simulado **por disciplina** de verdade (Biologia/Química/Física…).
4. Redação offline rotulada como rascunho por tamanho — não nota de banca.
5. Plano: bloco “Hoje” com **Fazer agora** → `sessionPath`.

## Classificar oficiais (Ciclo K)

1. `POST /api/ingest/classify-pending`: reclassifica oficiais + corrige cross-domain Natureza×Humanas.
2. Relatório: `updated`, `crossDomainFixed`, `residualCrossDomain`, `residualSample`, `bySubject`, `bankProfile`.
3. Domínio **Avançado** → **Reclassificar assuntos** (toast com residual); fila **Labels suspeitas** via `GET /api/curation/dirty-labels`.
4. Meta: residual cross-domain ≤2; sem Física+Literatura no sample.
5. Contagens de banca (`bank-profile` / `perfil_banca`) só após classify — números da base, sem inventar incidência.
6. Smoke: `ciclo_k_*`.

## Resoluções reais (Ciclo L)

1. Distinção: **rascunho/template** ≠ **ok (real)**; floor = “didático estruturado 4 eixos”, não texto da banca.
2. Fila professor: Natureza non-real, **cap 5**/dia; **Ok/Aceitar** grava `resolutionQuality=real`.
3. `POST /api/curation/promote-natureza-real` e floor completo em Domínio Avançado.
4. `promote-other-real` leve; health `naturezaFloorOk` anti-regressão.
5. batch-fill continua **draft** — nunca marca resolvido sozinho.
6. Smoke: `ciclo_l_*`.

## Histórico 2017–23 (Ciclo M)

1. Biblioteca → **Anos antigos**: empty honest (“Falta o PDF…”) — sem prometer cobertura.
2. Drop `paes_YYYY.pdf` + `gabarito_YYYY.pdf` → **Gravar** / `POST /api/acervo/commit-on-disk`.
3. Pós-commit: classify 1x + parse-gate; `yearsUsed` só anos presentes.
4. Smoke: `ciclo_m_*` (dryRun / board shape sem exigir PDF ausente).

## Eixos + edital + ship (Ciclo N)

1. Ranking Domínio: Natureza curated primeiro; labels sujas (ex. Histórica mal-rotulada) não roubam topo.
2. Floor leve outras áreas; inventário `data/inventory/README_INVENTARIO.md` com 2024–26.
3. Edital: se `edital_*.pdf` → sync syllabus; se só MD → resumo + CTA (sem fingir PDF oficial).
4. Smoke full + `ciclo_k_*`…`ciclo_n_*`; `flutter build windows --release` + `empacotar_windows.bat`.
5. Princípios K–N: sem inventar incidência/% aprovação; stubs fora de sim sério.

## Banco no fio (Ciclo AA)

1. `dailyRoutine.sessionPath`: par subject/topic **coerente** (nunca misturar); rejeita cross-domain; Natureza curated first.
2. Path com `year=` (último ano oficial do tópico) + `preferOfficial=1` quando acervo destravado.
3. Fila: bloco **Oficial do dia**; Domínio abre sessão no tópico com contagem local `N na base`.
4. `/api/today` com `examBoard`/`year`/`subject`/`topic` prioriza oficiais (`generated=0` no pack).
5. Smoke: `ciclo_aa_*`.

## Resolução na resposta (Ciclo AB)

1. Questão serializada: `resolutionQuality`, `resolutionAxes` (comando/conceito/gabarito/distrator), `studentResolutionLabel` (`ok`|`rascunho`|`template`).
2. Sessão: após revelar, debrief em 4 eixos se `real`; senão badge rascunho + texto honesto.
3. Aceitar drafts continua só no Domínio Avançado.
4. Smoke: `ciclo_ab_*`.

## Plano = inventário (Ciclo AC)

1. `build_study_plan`: só tópicos com material na base (oficial se basis=oficial); reason com “N oficiais nos anos Y”.
2. Coach do dia alinhado a `pick_coach_focus` (mesmo par).
3. Smoke: `ciclo_ac_*`.

## Reta quieta (Ciclo AD)

1. Hoje/Fila/Sessão/Sim: próximo passo; curadoria em Avançado.
2. Dia de prova: preflight honesto (sem treino disfarçado se oficiais ≥10).
3. Backup zip: DB + provas/gabaritos/edital.
4. Smoke `ciclo_aa_*`…`ciclo_ad_*` + pack Windows.

## Sessão cheia (Ciclo AE)

1. Top-off Natureza: se pack &lt;10 e pool Natureza ≥10, completa com oficiais UEMA (sem stubs).
2. `year=` estreito (&lt;5) → multi-ano do mesmo tópico com `warning` honesto.
3. Resposta: `toppedOff`, `targetPackMin=10`, `officialInPack`, `yearWidened`.
4. Smoke: `ciclo_ae_*`.

## Debrief paridade (Ciclo AF)

1. Widget compartilhado `ResolutionDebrief` (sessão, treino adaptativo, ficha da questão).
2. Mesmo contrato AB: 4 eixos se real; senão rascunho.
3. Adaptive items trazem `resolutionQuality` / `resolutionAxes` via serialização.
4. Smoke: `ciclo_af_*`.

## Retenção (Ciclo AG)

1. Pós-debrief: **Treinar este tópico** → adaptativo; **Criar card** a partir dos eixos.
2. `POST /api/flashcards/from-question` prioriza pares Comando↔Gabarito / Conceito↔Distrator se real.
3. `schedule_gaps` / fila de lacunas intactos.
4. Smoke: `ciclo_ag_*`.

## Ship canônico (Ciclo AH)

1. `empacotar_windows.bat`: kill + rmdir; se lock, renomeia para `_stale_*` e recria `dist\PAES_MED_AI_Windows`.
2. Atalho Desktop só após gates (dll, app.so, main.py).
3. `COMO` AE–AH; smoke `ciclo_ah_*` (forma do dist se presente).

## Fim de sessão (Ciclo AI)

1. Após o último bloco da sessão guiada: painel **Bloco encerrado** (acertos, oficiais no pack, toppedOff).
2. CTAs: **Fila** (primário) · Treinar tópico fraco · Cards due · Encerrar dia.
3. **Recomeçar** limpa checkpoint e mantém a meta/path do coach.
4. Smoke: `ciclo_ai_*`.

## Dia de prova / sim debrief (Ciclo AJ)

1. Pós-simulado: erros com `ResolutionDebrief` (fetch `/api/questions/{id}` se o pack não trouxer eixos).
2. CTAs no erro: Remediar · Fila · Sessão Natureza.
3. Preflight Dia de prova: com ≥10 oficiais, copy de base oficial (sem treino disfarçado); banner se pack misto/`generated`.
4. Smoke: `ciclo_aj_*`.

## Cards no loop (Ciclo AK)

1. `GET /api/flashcards` serializa `source` / `fromAxes`; filtro `axesOnly`.
2. `/api/today` e dashboard: `flashcardsDueCount`, `axisCardsDue`, `axisCardsCreatedToday` (contagem local).
3. Fila: linha **Cards do debrief** → `/flashcards?due=1`; Cards com badge **eixos**.
4. Smoke: `ciclo_ak_*`.

## Dist canônico + higiene (Ciclo AL)

1. Atalho Desktop só no canônico `dist\PAES_MED_AI_Windows` (gates OK).
2. Se lock no pack: abort + listagem de PIDs; **não** cria `_AEAH` por default.
3. Com app fechado, pastas `dist\*_stale_*` e packs legados (`_KN` / `_AAAD` / `_AEAH`) podem ser apagadas.
4. Smoke: `ciclo_al_*` + suite completa.

## Fecho da semana (Ciclo AM)

1. Widget `WeekClosePanel` lê `weekClose` (hint, due, gaps, ctas, canClose, closedThisWeek).
2. Hoje (Dashboard) e Fila renderizam o bloco; **Encerrar semana** → `POST /api/study/week-close`.
3. Smoke: `ciclo_am_*`.

## Backup verify na UI (Ciclo AN)

1. Ajustes → Dados: feedback de verify ao salvar; linha **Último backup verificado** via `GET /api/backup/last`.
2. Hoje: lembrete se sem backup ou >7 dias → Ajustes.
3. Smoke: `ciclo_an_*`.

## Dia de prova em foco (Ciclo AO)

1. Simulados: **Dia de prova** como caminho principal; demais modos em “Outros modos”.
2. Pós-resultado: CTAs Fila / Natureza / **Redação**.
3. Redação: copy offline sem “nota de banca”.
4. Smoke: `ciclo_ao_*`.

## Material local (Ciclo AP)

1. `GET /api/library/materials?subject=&topic=` lista só o que existe no disco.
2. `POST /api/library/open-path` abre arquivo dentro de `data/`.
3. Fila: **Ler teoria** nas lacunas; empty honesto se vazio.
4. Smoke: `ciclo_ap_*` + suite completa. `COMO` AM–AP.

## Ship + Biblioteca Z4 (Ciclo AQ)

1. Pack canônico: app fechado → `empacotar_windows.bat` → `dist\PAES_MED_AI_Windows` (dll + backend/main.py).
2. Biblioteca: primeiro viewport **2024–26** + Atualizar / Estudar agora; 2017–23 colapsado; curadoria/pastas em **Avançado**.
3. Smoke: `ciclo_aq_*` (dist shape ou skip honesto).

## Materiais por tópico (Ciclo AR)

1. `GET /api/library/materials?subject=&topic=` filtra edital/aulas + `theory_snippets`; sem PDF inventado.
2. Fila **Ler teoria**: abre path, mostra snippet, ou snack + CTA Biblioteca.
3. Smoke: `ciclo_ar_*`.

## Tutor com fonte (Ciclo AS)

1. `POST /api/chat`: offline grounded com `citations` ou `uncited` + “sem base local”.
2. Online exige ids reais de questão; senão recusa.
3. UI Tutor: banner se `uncited`; chips → `/questoes/{id}`.
4. Smoke: `ciclo_as_*`.

## Progresso de redação (Ciclo AT)

1. `GET /api/essays/progress`: médias 5 eixos, count, lastScores, disclaimer treino local.
2. Redação: barras dos eixos + “treino local · não banca”.
3. Smoke: `ciclo_at_*` + suite completa. `COMO` AQ–AT.

## Leitura + “li” (Ciclo AU)

1. Fila **Ler teoria** abre sheet com materials/snippets.
2. `POST /api/study/mark-read` + `GET /api/study/reads` (local).
3. Smoke: `ciclo_au_*`.

## PDF por ano (Ciclo AV)

1. `GET /api/library/year-pdf?year=` resolve arquivo em `data/provas`.
2. Questão serializa `sourcePdf`; ficha e Biblioteca (botão PDF) abrem se existir.
3. Smoke: `ciclo_av_*`.

## Busca no acervo (Ciclo AW)

1. `GET /api/library/search?q=` oficiais + estudo local.
2. Biblioteca: campo busca → ficha ou open-path.
3. Smoke: `ciclo_aw_*`.

## Missão de redação (Ciclo AX)

1. `essays/progress` inclui `nextMission` / `weakestAxis`.
2. Redação + Fila: CTA missão → `/redacao`.
3. Smoke: `ciclo_ax_*` + suite. Pack canônico. `COMO` AU–AX.

## Vídeos de reforço (Ciclo AY)

1. Catálogo: `data/media/videos_catalog.json`.
2. `GET /api/media/videos?subject=&topic=` + `POST /api/media/open` (YouTube whitelist).
3. Fila: card **Reforço em vídeo** (não é edital UEMA).
4. Smoke: `ciclo_ay_*`.

## YouTube opcional (Ciclo AZ)

1. `YOUTUBE_API_KEY` no `.env` enriquece resultados; senão só catálogo.
2. Cache `video_cache` 48h; toggle `suggestVideos` em Ajustes → Avançado.
3. Health: `youtube_configured`.
4. Smoke: `ciclo_az_*`.

## Personas de redação (Ciclo BA)

1. `GET /api/essays/personas`; `POST /api/essay/grade` com `persona` / `focusAxis`.
2. UI Redação: chips de persona; feedback carrega persona.
3. Smoke: `ciclo_ba_*`.

## Streak de redação (Ciclo BB)

1. `essays/progress.streakDays` + `lastEssayAt`.
2. Dashboard CTA missão se count≥1.
3. Smoke: `ciclo_bb_*` + suite. Pack + `COMO` AY–BB.

## Artigos locais (Ciclo BC)

1. Catálogo: `data/media/articles_catalog.json`.
2. `GET /api/media/articles?subject=&topic=` (basis catalogo_local).
3. Smoke: `ciclo_bc_*`.

## Abrir leitura + Fila (Ciclo BD)

1. `POST /api/media/open` com `kind=article` (Wikipedia/SciELO/gov/edu) ou video (YouTube).
2. Fila: **Leitura de reforço**; sheet teoria lista leituras.
3. Smoke: `ciclo_bd_*`.

## Prefs + Serper (Ciclo BE)

1. `media_prefs.suggestArticles` (Ajustes → Avançado).
2. `SERPER_API_KEY` opcional; cache 48h; health `serper_configured`.
3. Smoke: `ciclo_be_*`.

## Sessão + ship (Ciclo BF)

1. Sessão fase teoria: CTA **Leitura de reforço**.
2. Pack inclui `articles_catalog.json`.
3. Smoke: `ciclo_bf_*` + suite. `COMO` BC–BF.

## Reforço unificado (Ciclo BG)

1. Widget `media_reinforcement.dart` (vídeo + leitura) na Fila e Sessão.
2. Endpoints separados mantidos.
3. Smoke: `ciclo_bg_*` + push GitHub.

## Histórico e “li” mídia (Ciclo BH)

1. `media_opens` no open; `GET /api/media/opens`.
2. `POST /api/media/mark-read` + `GET /api/media/reads`.
3. Sheet teoria e Ajustes → Avançado (últimas aberturas).
4. Smoke: `ciclo_bh_*` + push.

## Catálogo Natureza (Ciclo BI)

1. Expansão `articles_catalog` / `videos_catalog` (Evolução, Bioenergética, Termoquímica, Ondulatória…).
2. Smoke: `ciclo_bi_*` + push.

## Redação radar + docs (Ciclo BJ)

1. Radar de eixos em Redação (`averages`).
2. `ROADMAP_FUTURO.md` alinhado (F1–F6 feitos via AQ…BF).
3. Smoke `ciclo_bj_*` + suite + pack + push.

## Timeline de redação (Ciclo BK)

1. Histórico abre texto + feedback; **Reescrever**.
2. Missão: botão preenche editor com última redação.
3. Smoke: `ciclo_bk_*` + push.

## Busca Biblioteca (Ciclo BL)

1. Histórico `library_search_history` + `GET /api/library/search-history`.
2. Chips recentes + filtro oficial|estudo|todos.
3. Smoke: `ciclo_bl_*` + push.

## Hoje Z3 (Ciclo BM)

1. Checklist + **Agora** na dobra; **Mais do dia** collapsible.
2. Smoke: `ciclo_bm_*` + push.

## Cards · export · sim (Ciclo BN)

1. Cards: toggle **Só eixos** (`axesOnly`).
2. `POST /api/study/export-day` → `data/exports`.
3. Sim debrief: MediaReinforcement compact na 1ª lacuna.
4. Smoke `ciclo_bn_*` + suite + pack + push.

## Export de plano (Ciclo BO)

1. Plano semana/mês → `POST /api/study/export-day` (arquivo em `data/exports`).
2. Smoke: `ciclo_bo_*` + push.

## Checkpoint de simulado (Ciclo BP)

1. `GET/POST/DELETE /api/sim/checkpoint` · Continuar / Descartar.
2. Smoke: `ciclo_bp_*` + push.

## Ficha + Cards teclado (Ciclo BQ)

1. Ficha: MediaReinforcement pós-revelar.
2. Cards: Space / L / E.
3. Smoke: `ciclo_bq_*` + push.

## Domínio Z3 + Sobre (Ciclo BR)

1. Rascunhos/labels em Avançado; Sobre em Ajustes.
2. Rail com Tooltip/Semantics.
3. Smoke `ciclo_br_*` + suite + pack + push.

## Teclado no simulado (Ciclo BS)

1. Simulados em sessão: teclado `1–5` / numpad escolhe opção; Enter avança/finaliza; Space avança foco.
2. Preflight e relatório sem teclas conflitantes; Dia de prova sem gabarito antecipado.
3. Smoke: `ciclo_bs_*` + push.

## Relatório semanal (Ciclo BT)

1. `POST /api/study/export-week` grava MD em `data/exports` com weekKey e disclaimer local.
2. Hoje → Fecho da semana → **Exportar semana** (abre pasta).
3. Smoke: `ciclo_bt_*` + push.

## Calendário 28d (Ciclo BU)

1. Dashboard → 28 dias: Tooltip + tap (sheet) com data e estudou/encerrou.
2. Dia sem estudo: “sem estudo registrado” (não inventa atividade).
3. Smoke: `ciclo_bu_*` + push.

## Tutor ficha + banca + a11y (Ciclo BV)

1. Ficha → **Perguntar ao tutor** com subject/topic/q; Tutor preenche seed se vazio.
2. Banca co-ocorrência com play → adaptativo; EmptyState/QuietEmpty com Semantics.
3. Smoke `ciclo_bv_*` + suite + pack + push.

## Sessão numpad (Ciclo BW)

1. Sessão: `numpad1–5` e `numpadEnter` na fase de questões; Escape sem fingir ação.
2. Smoke: `ciclo_bw_*` + push.

## Export relatório sim (Ciclo BX)

1. Sim pós-grade → **Exportar** MD via `export-day` (acerto/tempo/lacunas + disclaimer local).
2. Smoke: `ciclo_bx_*` + push.

## Calendário + lacunas (Ciclo BY)

1. Sheet 28d (hoje): CTAs Sessão e Encerrar dia (se ainda aberto).
2. Fecho: lacunas quentes → adaptativo.
3. Smoke: `ciclo_by_*` + push.

## Empties + rótulos (Ciclo BZ)

1. Domínio vazio → Sessão; erro com Tentar; redação histórico → Escrever agora.
2. Plano: **Exportar plano (semana/mês)** ≠ export semana do fecho.
3. Smoke `ciclo_bz_*` + suite + pack + push.

## Teclado de estudo (Ciclo CA)

1. Adaptive/ficha: Enter/numpad pós-revelar; adaptive numpadEnter confirma.
2. Cards: numpad1/2 = L/E; sessão fase revisão: Space/L/E + error-pick 1–5.
3. Smoke: `ciclo_ca_*` + push.

## Empties com CTA (Ciclo CB)

1. Adaptive sem opções / erro; ficha load; banca freq; aulas; biblioteca boards; aprovação limpa.
2. Labels: **Exportar pacote do dia** · **Exportar relatório**.
3. Smoke: `ciclo_cb_*` + push.

## Foco honesto (Ciclo CC)

1. `/redacao` permitida no modo foco; Plano/Domínio/Aulas/… Hostis mantidos.
2. Fila esconde Plano/Domínio em foco.
3. Smoke: `ciclo_cc_*` + push.

## Lacunas recuperadas (Ciclo CD)

1. Fila / Revisões / Adaptive fim / week-close: **Marcar recuperada** → `POST /api/gaps/recover`.
2. Smoke `ciclo_cd_*` + suite + pack + push.

## Versão + pack visível (Ciclo CE)

1. App **1.0.0+3** (pubspec + Ajustes → Sobre).
2. `empacotar_windows.bat` grava `dist\PAES_MED_AI_Windows\VERSION.txt`.
3. Smoke: `ciclo_ce_*` + push.

## Theory CTA + foco-safe (Ciclo CF)

1. Sessão teoria vazia → Biblioteca; Enter avança teoria; revisões empty com botão.
2. Tutor lesson sem `/aulas`; Settings Domínio desabilitado em foco; library pipeline focus-aware.
3. Smoke: `ciclo_cf_*` + push.

## Checkpoint legível (Ciclo CG)

1. Banner sessão / Hoje / Fila: fase · item (questões) · salvamento.
2. Smoke: `ciclo_cg_*` + push.

## Exam hydrate (Ciclo CH)

1. Prefs vazia → `GET /api/study/exam-date` preenche (local wins se já tiver).
2. Ajustes: eco countdown sob a data.
3. Smoke `ciclo_ch_*` + suite + pack + push.

## Teclado revisão+questões (Ciclo CI)

1. Sessão: fase revisions com `revisionUsingQuestions` usa 1–5 / Enter / error-pick.
2. Cards puras: Space/L/E intactos.
3. Smoke: `ciclo_ci_*` + push.

## Erros humanos (Ciclo CJ)

1. `humanApiError` em busca, treino, ficha, encerrar dia/semana.
2. Smoke: `ciclo_cj_*` + push.

## First-run (Ciclo CK)

1. Onboarding → **Ir ao Hoje** (primário) + Biblioteca; pasta sem exception.
2. Aprovar desabilitado sob foco (como Domínio).
3. Smoke: `ciclo_ck_*` + push.

## Ajustes Avançado (Ciclo CL)

1. Grupos Mídia · Oficina · Índices · Paths; Recalcular base; versão **1.0.0+4**.
2. Smoke `ciclo_cl_*` + suite + pack + push.

## Erros humanos onda 2 (Ciclo CM)

1. `humanApiError` em Fila, sessão export/card, sim export/lacunas, redação grade, week-close.
2. Smoke: `ciclo_cm_*` + push.

## Teclado sim completo (Ciclo CN)

1. Sim em run: ←/Backspace volta · →/Space avança · 1–5 opção ou tipo de erro se já respondeu · Enter grade no fim.
2. Smoke: `ciclo_cn_*` + push.

## Adaptive + redação teclas (Ciclo CO)

1. Adaptativo: pós-miss 1–5 tipo de erro · Enter registra (`pendingErrorPick`).
2. Redação: Ctrl+Enter / Cmd+Enter corrige.
3. Smoke: `ciclo_co_*` + push.

## Hoje path + ship (Ciclo CP)

1. Continuar/Começar usam `sessionPath` com board/natureza.
2. Cards checklist aguarda dados antes de “em dia”.
3. Versão **1.0.0+5** · smoke `ciclo_cp_*` + suite + pack + push.

## Erros humanos onda 3 (Ciclo CQ)

1. `humanApiError` em mídia, revisões, aprovação, load sessão, Biblioteca e Domínio thin.
2. Smoke: `ciclo_cq_*` + push.

## Ficha error-pick teclado (Ciclo CR)

1. `pendingErrorPick`: 1–5 tipo · Enter salva; N/Enter saem só após gravar.
2. Smoke: `ciclo_cr_*` + push.

## Cards foco + sim Enter (Ciclo CS)

1. Flashcards re-focus após rate/flip.
2. Sim preflight Enter inicia · report Enter → Hoje.
3. Smoke: `ciclo_cs_*` + push.

## First-run + ship (Ciclo CT)

1. Coach limpo se `officialN > 0`; Plano/Banca human errors; **1.0.0+6**.
2. Smoke `ciclo_ct_*` + suite + pack + push.

## Erros humanos onda 4 (Ciclo CU)

1. `humanApiError` em Health (Ajustes), Aulas, ingest review, Cards (criar/revisar/apagar), Biblioteca commits/fetch e Tutor IA.
2. Versão **1.0.0+7** · smoke `ciclo_cu_*` + suite + pack + push.

## Aulas Ctrl+Enter (Ciclo CV)

1. Legenda ≥80 chars: **Ctrl+Enter** / Cmd+Enter estrutura a aula (como redação).
2. Smoke: `ciclo_cv_*` + push.

## Ingest review teclado (Ciclo CW)

1. Revisão PAES: **←/J** anterior · **→/K** próxima · **1–5** gabarito (respeita filtro duvidosas).
2. Smoke: `ciclo_cw_*` + push.

## Health offline legível (Ciclo CX)

1. Ajustes → Seus dados: offline mostra mensagem `humanApiError` (não stack).
2. Smoke: `ciclo_cx_*` + push.

## Questões teclado (Ciclo CY)

1. Lista: **↑/↓** ou **J/K** seleciona · **Enter** abre ficha · **[/]** ou **P/N** páginas.
2. Smoke: `ciclo_cy_*` + push.

## Tutor Ctrl+Enter (Ciclo CZ)

1. Tutor IA: **Ctrl+Enter** envia (Enter sozinho quebra linha no campo).
2. Smoke: `ciclo_cz_*` + push.

## Onboarding teclado (Ciclo DA)

1. **←** volta · **→** ou **Enter** avança (ignora quando cursor no campo de data).
2. Smoke: `ciclo_da_*` + push.

## Roadmap futuro (não é ciclo atual)

Pedidos agendados com **melhor solução por item** (tutor com fonte, acervo UEMA/PDF, vídeos do plano, redação gamificada, artigos): ver **[ROADMAP_FUTURO.md](ROADMAP_FUTURO.md)**.  
Ordem: FA acervo/leitura → FB tutor → FC vídeos → FD redação-game → FE artigos.  
Implementar **só** quando o fio de sessão/sim/cards/pack estiver estável; não inventa oficial nem % de aprovação.

## Dia de prova (Ciclo U)

1. Simulados → **Dia de prova**: preflight (base/qtd/tempo) → cronômetro → sem resolução até finalizar.
2. Debrief: CTAs Natureza / Fila / Redação.
3. Redação: 5 eixos (gramática, coesão, coerência, argumentação, intervenção) + fortes/melhorias.
4. Ajustes → Backup com verify + restore confirm + último OK.
5. Banca: CTAs sessão / simulado / tutor.

## Soft landing (Ciclo V)

1. Onboarding → **Ir para Semana 1** (Biblioteca) + coach no Dashboard.
2. Empty states com 1 CTA (Retry / Sessão / Biblioteca).
3. Atalhos: `F` foco; sessão `1–5` opção, `Enter` confirma, `N` próxima.
4. Ajustes: Estudo / Health / IA / Dados / Avançado.
5. Crash UI amigável; **Continuar** sessão salva no Hoje.

## Fluxo do dia

1. Onboarding: data da prova (opcional). **Modo foco** ON.
2. Semana 1 real ou commit → Estudar agora (`preferNatureza=1`).
3. Fecho da semana no Dashboard/Fila; recupere lacunas abertas.
4. Reseed de treino **preserva** oficiais. Estimativas ≠ garantia.

## Python / venv

O launcher usa, nesta ordem: `dist\...\backend\.venv`, depois `PAES_MED_AI\backend\.venv`, depois `python` do PATH.  
Na primeira vez no projeto: `cd backend && python -m venv .venv && .venv\Scripts\pip install -r requirements.txt`.

## Aparência (Ciclo Z — UI)

1. Tema: **Ajustes → Aparência**, rail ou **Ctrl+T** (claro / escuro / sistema).
2. **Z3 informação**: Hoje, Fila, Domínio e Sessão mostram só o próximo passo; curadoria e paths ficam em **Avançado**.
3. Planos: [`PLAN_UI_VISUAL.md`](PLAN_UI_VISUAL.md) · [`PLAN_UI_Z3.md`](PLAN_UI_Z3.md).

## Health

http://127.0.0.1:8000/health

Se a API estiver morta, feche o app e reabra o atalho **PAES MED AI** (ele sobe API + exe).

## Smoke test

```bat
cd backend
.venv\Scripts\python.exe smoke_test.py
```
