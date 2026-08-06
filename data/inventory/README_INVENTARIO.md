# Inventário de materiais oficiais — PAES/UEMA

Coloque os PDFs nas pastas indicadas. Marque o que já tem.
Atualizado GV–GW (F1 deep): resumo também no Hoje (`acervoSummary`); 2024–26 é o núcleo no disco;
2017–23 só entram após drop manual — sem arquivo = sem cobertura prometida (smoke `ciclo_gw_*`).

## Edital

- [ ] Edital vigente PDF (`edital_*.pdf`) → `data/edital/`
- [x] Resumo MD local → `data/edital/conteudo_programatico_resumo.md` (não substitui o PDF oficial)

## Provas e gabaritos

| Ano | Prova em `data/provas/` | Gabarito em `data/gabaritos/` | Notas |
|-----|-------------------------|-------------------------------|--------|
| 2017 | [ ] | [ ] | Histórico manual |
| 2018 | [ ] | [ ] | Histórico manual |
| 2019 | [ ] | [ ] | Histórico manual |
| 2020 | [ ] | [ ] | Histórico manual |
| 2021 | [ ] | [ ] | Histórico manual |
| 2022 | [ ] | [ ] | Histórico manual |
| 2023 | [ ] | [ ] | Histórico manual |
| 2024 | [x] | [x] | Semana 1 / oficiais no disco (quando `paes_2024` + `gabarito_2024` presentes) |
| 2025 | [x] | [x] | idem |
| 2026 | [x] | [x] | idem |

## Fluxo (Ciclos K–N)

1. Drop/commit PDFs → `classify-pending` (labels) → floor Natureza / Aceitar (real) → inventário.
2. Histórico 2017–23: Biblioteca → Anos antigos → Gravar só se prova+gabarito no disco.
3. Edital: se houver PDF, `POST /api/edital/sync-syllabus`; senão só MD + CTA Biblioteca.

## Observação

A base do app já vem com questões de **treino** no padrão do edital para estudar imediatamente.
Estatísticas de frequência no seed usam anos atribuídos às questões de treino para validar o motor.
Quando provas oficiais forem importadas e revisadas, reprocesse a base (`POST /api/seed?force=true` só reseed de treino; oficiais entram por ingestão revisada).

Nunca inventar frequência nem % de aprovação: só contar o que está no SQLite.
