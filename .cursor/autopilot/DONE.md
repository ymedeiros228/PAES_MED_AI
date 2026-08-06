# Auto-Pilot — DONE

## GR–GU (2026-08-05/06)

- **GR**: pack Desktop canônico (bat + ico + exe + VERSION) + atalho.
- **GS**: MinGit host, land em `main`, smoke 708.
- **GT**: `openTheoryReadSheet` + CTA **Ler teoria** (Fila + ficha).
- **GU**: smoke `ciclo_gu_pack_*`, versão **1.0.0+9**, push; fix compile Windows release.

## Nota

Autopilot micro-ciclos GN–GQ (e anteriores) estavam **certos**.  
GR–GU = ship de residual real (pack/git/F2), não substituir toda a missão do Auto-Pilot.

**Pack rule:** nunca deixar dist só com `app\` sem launcher/ico.


---
## Nova sessão 2026-08-06T15:28:36.767Z



---
## Nova sessão 2026-08-06T15:43:46.242Z



---
## Nova sessão 2026-08-06T15:58:32.217Z

- [x] **Sessão/Fila empty+erro (modo A):** copy em PT sem jargão (misses/due/spaced/syllabus/API); CTAs primários únicos (Tentar de novo, Abrir fila, Carregar questões/revisões); erro de lacunas e card review com ação; fila vazia aponta para Começar sessão. **Polish UI:** divisor no painel fim de sessão. Smoke strings atualizadas (cf/fb/fz/ga).
- [x] **Ficha/Fila li teoria → treino (modo A):** `theory_read_sheet` com passos 1/2, default `/adaptativo`, CTA **Treinar agora** pós-leitura; ficha pós-erro prioriza Ler teoria; fila lacunas passa `trainPath` adaptativo. **Polish UI:** ícone no empty da fila. Smoke `ciclo_gv_theory_li_treino_path`.
- [x] **Soft landing onboarding + Semana 1 (modo A):** gap reproduzido — coach só no Hoje; Biblioteca sem guia pós-onboarding; CTA renomeado pós-+9. Fix: banner Semana 1 na Biblioteca + coach Hoje alinhado; onboarding **Semana 1 (Biblioteca)** primário; playbook Semana 1 com **Abrir provas** primário. Smoke `ciclo_gw_first_run_semana1`.
- [x] **Fila lacunas sem material (P2 thin):** API `hasLocalMaterial` por lacuna (audit Física/tópicos cross-domain); tile **sem teoria** + ícone Biblioteca; QuietEmpty seção com CTA Biblioteca; theory sheet empty reforçado. Smoke `ciclo_gx_fila_gap_no_material` (709/711).
- [x] **open-path / PDF ano (P2 regressão GQ):** `humanOpenPathError`; `year_pdf_info` verifica `path.exists()`; Biblioteca busca/PDF/theory/ficha com msg “sumiu do disco”; API 404 explícita; **Polish:** QuietEmpty + **Abrir provas** na Biblioteca. Smoke `ciclo_gy_open_path_honest` (710/712).
- [x] **mark-read / Ler teoria ficha+fila (P2):** smoke `ciclo_gz_mark_read_ficha_fila` (API Física/Ondulatória + wiring UI); Fila `_readRefreshTick` atualiza ícone após fechar sheet; regress GT+FX corrigidas; **Polish:** badge check “Marcado como lido” no theory sheet. Smoke **713/713**.
