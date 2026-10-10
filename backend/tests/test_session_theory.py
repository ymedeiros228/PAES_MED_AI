"""Sessão guiada: teoria do TÓPICO (sem Markdown cru/duplicação) e questões focadas."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

import services_edital  # noqa: E402
from db import db  # noqa: E402
from main import app  # noqa: E402
from services_edital import (  # noqa: E402
    clean_markdown,
    rank_by_topic_relevance,
    theory_sections_for,
    theory_snippets_for,
    topic_relevance_scorer,
)


@pytest.fixture(scope="module")
def client() -> TestClient:
    with TestClient(app) as c:
        yield c


def _has_material(subject: str, topic: str) -> bool:
    return services_edital.find_topic_material(subject, topic) is not None


def test_clean_markdown_remove_titulos_bullets_e_enfase() -> None:
    raw = "## Natureza\n- Biologia: **Genética**, Mendel\n\n\n\n* item"
    out = clean_markdown(raw)
    assert "##" not in out
    assert "**" not in out
    assert out.splitlines()[0] == "Natureza"
    assert "• Biologia: Genética, Mendel" in out
    assert "\n\n\n" not in out


def test_teoria_de_genetica_vem_do_material_sem_markdown_nem_repeticao() -> None:
    if not _has_material("Biologia", "Genética"):
        pytest.skip("sem material de Genética no banco de teste")
    sections = theory_sections_for("Biologia", "Genética", limit=10)
    assert sections, "esperado teoria do material"
    assert sections[0]["source"].startswith("material:")
    bodies = [s["body"] for s in sections]
    assert len(bodies) == len(set(bodies)), "blocos repetidos"
    for body in bodies:
        assert not body.lstrip().startswith(("#", "- ")), body[:60]
    blob = " ".join(bodies).lower()
    assert "mendel" in blob
    # Antes: a lista genérica do edital ("Química: ...", "Física: ...") aparecia
    assert "química: estrutura atômica" not in blob


def test_teoria_material_casa_sem_acento_entre_disciplinas() -> None:
    # Materiais gravam "Quimica"; questões/meta usam "Química".
    if not _has_material("Química", "Estequiometria"):
        pytest.skip("sem material de Estequiometria")
    sections = theory_sections_for("Química", "Estequiometria")
    assert sections and sections[0]["source"].startswith("material:")


def test_teoria_fallback_edital_so_linhas_do_topico(monkeypatch: pytest.MonkeyPatch) -> None:
    # Força o fallback do edital (sem material e sem aulas).
    monkeypatch.setattr(services_edital, "find_topic_material", lambda *_a, **_k: None)
    monkeypatch.setattr(services_edital, "_lesson_sections", lambda *_a, **_k: [])
    sections = theory_sections_for("Biologia", "Genética")
    edital = [s for s in sections if s["source"] == "edital"]
    if not edital:
        pytest.skip("sem edital local no ambiente de teste")
    lines = edital[0]["body"].splitlines()
    assert all("genética" in ln.lower() or "genetica" in ln.lower() for ln in lines), lines
    assert len(lines) == len(set(lines))
    assert not any(ln.startswith(("##", "- ")) for ln in lines)


def test_snippets_compat_lista_de_strings() -> None:
    snips = theory_snippets_for("Biologia", "Genética", limit=6)
    assert isinstance(snips, list)
    assert all(isinstance(s, str) for s in snips)
    assert len(snips) == len(set(snips))


def test_ranking_prioriza_conteudo_do_topico_sobre_rotulo() -> None:
    if not _has_material("Biologia", "Genética"):
        pytest.skip("sem material de Genética")
    qs = [
        {"id": "a", "topic": "Genética", "statement": "Os protozoários causam a doença de Chagas.", "options": []},
        {
            "id": "b",
            "topic": "Citologia",
            "statement": "Cruzamento de heterozigotos Aa x Aa (Mendel): proporção fenotípica e alelos.",
            "options": ["3:1 genótipo", "1:2:1"],
        },
    ]
    ranked = rank_by_topic_relevance(qs, "Biologia", "Genética")
    assert ranked[0]["id"] == "b"
    assert ranked[0]["topicRelevance"] >= 2
    assert ranked[1]["topicRelevance"] == 0


def test_scorer_sem_artefato_de_quebra_de_linha_json() -> None:
    if not _has_material("Biologia", "Genética"):
        pytest.skip("sem material de Genética")
    kw = topic_relevance_scorer("Biologia", "Genética").keywords
    # '\\n' literal do content_json gerava radicais como 'nheran'/'nmutac'
    assert not kw & {"nheran", "nmutac", "ngenet", "nalelo"}, sorted(kw)


def test_session_plan_deeplink_teoria_e_questoes_do_topico(client: TestClient) -> None:
    r = client.get(
        "/api/session/plan",
        params={"subject": "Biologia", "topic": "Genética", "preferNatureza": "true"},
    )
    assert r.status_code == 200, r.text
    data = r.json()
    assert "theorySections" in data and isinstance(data["theorySections"], list)
    assert data["phases"]["theorySections"] == data["theorySections"]
    # "reason" da meta não vira bloco de teoria
    assert not any("Deep-link" in s or "Ciclo X" in s for s in data["theorySnippets"])
    for sec in data["theorySections"]:
        assert set(sec) >= {"title", "body"}
    ids = data["phases"]["questions"]
    if not ids:
        pytest.skip("sem questões de Biologia no banco de teste")
    scorer = topic_relevance_scorer("Biologia", "Genética")
    if not scorer.keywords:
        pytest.skip("sem vocabulário de Genética")
    first = client.get(f"/api/questions/{ids[0]}").json()
    with db() as conn:
        n_rel = sum(
            1
            for row in conn.execute("SELECT statement, options_json FROM questions WHERE subject='Biologia'")
            if scorer({"statement": row["statement"], "options": [row["options_json"] or ""]}) >= 2
        )
    if n_rel:
        assert scorer(first) >= 2, first["statement"][:120]


def test_today_sem_meta_continua_com_contrato(client: TestClient) -> None:
    r = client.get("/api/today")
    assert r.status_code == 200
    data = r.json()
    for key in ("theorySnippets", "theorySections", "sessionPlan", "phases", "statsBasis"):
        assert key in data
