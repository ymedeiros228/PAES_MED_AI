# Ciclo Z — UI com alma (planejamento)

> Eixo visual **paralelo** à curadoria (Y). UI startup: minimal, teal/navy, light+dark.

## Status

| Item | Estado |
|------|--------|
| Tema claro / escuro / sistema | Done |
| Shell sidebar minimal + Ctrl+T | Done |
| `ui_kit` (PageHeader, PlaylistTile, SurfacePanel, PhaseProgress, StatsStrip) | Done |
| **Fila** playlist | Done |
| **Plano** modo visual (progress + semana/completo + play) | Done |
| **Sessão** phase bar + painel de questão | Done |
| **Domínio/Medicina** playlist + rascunhos horizontais | Done |
| **Hoje** stats strip + seções | Done (parcial hero) |
| Biblioteca / Simulados / Tutor / Onboarding | **Feito (Z4)** |

## Z2 aceite

- Fila e Domínio legíveis sem “card farm”.
- Plano (`/cronograma`): barra de progresso, filtro semana, play no tópico.
- Sessão: barra de fases + surface da questão.
- Tema claro/escuro em todas as âncoras.

## Próximo (Z3)

1. Biblioteca board 2024–26 em tiles.
2. Simulados preflight mode-card.
3. Tutor chat bubbles + input sticky.

## Como testar

1. Desktop icon **ou** `flutter run -d windows`.
2. **Ctrl+T** / rail / Ajustes → tema.
3. Navegar: Hoje → Fila → Sessão → Plano → Domínio.

## Empacotar

Feche o app antes de `empacotar_windows.bat` (precisa de `app\data\flutter_assets`).
