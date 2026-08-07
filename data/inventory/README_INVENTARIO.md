# Inventário de materiais oficiais — PAES/UEMA

Coloque os PDFs nas pastas indicadas. Marque o que já tem.
Atualizado: 2026-08-06 — drop Downloads (provas 2014–2025) + 2026 prévio.

## Edital

- [ ] Edital vigente PDF (`edital_*.pdf`) → `data/edital/`
- [x] Resumo MD local → `data/edital/conteudo_programatico_resumo.md` (não substitui o PDF oficial)

## Provas e gabaritos

| Ano | Prova em `data/provas/` | Gabarito em `data/gabaritos/` | Notas |
|-----|-------------------------|-------------------------------|--------|
| 2014 | [x] `paes_2014.pdf` | [ ] | Drop Downloads — **sem gabarito** |
| 2015 | [x] `paes_2015.pdf` | [ ] | sem gabarito |
| 2016 | [x] `paes_2016.pdf` | [ ] | sem gabarito |
| 2017 | [x] `paes_2017.pdf` | [ ] | sem gabarito |
| 2018 | [x] `paes_2018.pdf` (1ª etapa) | [ ] | sem gabarito |
| 2019 | [x] `paes_2019.pdf` (1ª fase) | [ ] | sem gabarito |
| 2020 | [x] `paes_2020.pdf` | [ ] | sem gabarito |
| 2021 | [x] etapa1 + `paes_2021_etapa2.pdf` | [ ] | 2 cadernos; sem gabarito |
| 2022 | [x] `paes_2022.pdf` | [ ] | sem gabarito |
| 2023 | [x] `paes_2023.pdf` | [ ] | sem gabarito |
| 2024 | [x] | [x] `gabarito_2024.pdf` | par completo |
| 2025 | [x] | [x] `gabarito_2025.pdf` | par completo |
| 2026 | [x] | [x] `gabarito_2026.pdf` | par completo |

## Fluxo

1. Drop/commit PDFs → Biblioteca → Importar ano → **Revisar** → Commitar.
2. Anos **sem gabarito**: preview OK, mas **não** confie no `correctIndex` até colar gabarito oficial e reaplicar.
3. 2024–26: Semana 1 / Gravar PDFs do PC.
4. Nunca inventar gabarito nem incidência.

## Observação

Nome canônico: `paes_YYYY.pdf`. Extras no mesmo ano: `paes_YYYY_etapa2.pdf` (import mescla cadernos).

## Próximo passo (prioridade)

**Gabaritos 2014–23** — `data/gabaritos/gabarito_YYYY.pdf`.  
Sem isso o app marca o ano como **parcial** e **não grava oficiais** (evita inventar resposta).

Fluxo com gabarito no disco: Biblioteca → Import seguro / apply gabarito → altas conf. → estudar.
