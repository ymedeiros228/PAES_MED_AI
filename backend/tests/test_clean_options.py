"""Testes do limpador de alternativas poluídas por rodapé/cabeçalho de PDF."""

from __future__ import annotations

from clean_options import clean_option


def test_clean_option_cuts_paes_2014_footer():
    raw = (
        "100% Processo Seletivo de Acesso à Educação Superior – PAES 2014 "
        "DOCV/PROG/UEMA 1ª ETAPA 03/11/2013 das 13h às 18h 2 | P á g i n a"
    )
    cleaned, kind, removed = clean_option(raw)
    assert cleaned == "100%"
    assert kind == "cabecalho_pdf"
    assert removed is not None
    assert "Processo Seletivo" in removed


def test_clean_option_cuts_next_subject_block():
    raw = "paixão. FÍSICA. Questões de 17 a 24"
    cleaned, kind, _ = clean_option(raw)
    assert cleaned == "paixão"
    assert kind in {"materia_proxima_pagina", "proxima_secao"}


def test_clean_option_leaves_clean_percent_alone():
    cleaned, kind, removed = clean_option("75%")
    assert cleaned == "75%"
    assert kind is None
    assert removed is None
