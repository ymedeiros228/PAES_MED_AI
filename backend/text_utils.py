# -*- coding: utf-8 -*-
"""Utilitarios de normalizacao de texto para PDFs PAES MED AI."""

from __future__ import annotations

from typing import Any


_UNICODE_SUBS = [
    # Subscritos -> digitos normais
    ("₀", "0"), ("₁", "1"), ("₂", "2"), ("₃", "3"), ("₄", "4"),
    ("₅", "5"), ("₆", "6"), ("₇", "7"), ("₈", "8"), ("₉", "9"),
    # Sobrescritos -> digitos e sinais normais
    ("⁰", "0"), ("¹", "1"), ("²", "2"), ("³", "3"), ("⁴", "4"),
    ("⁵", "5"), ("⁶", "6"), ("⁷", "7"), ("⁸", "8"), ("⁹", "9"),
    ("⁻", "-"), ("⁺", "+"), ("⁼", "="), ("⁽", "("), ("⁾", ")"),
    # Frações
    ("½", "1/2"), ("¼", "1/4"), ("¾", "3/4"), ("⅓", "1/3"),
    ("⅔", "2/3"), ("⅕", "1/5"), ("⅗", "3/5"),
    # Setas
    ("→", "->"), ("←", "<-"), ("↔", "<->"), ("⇌", "<=>"),
    ("⇒", "=>"), ("⇐", "<="),
    # Matematica
    ("×", "x"), ("·", "."), ("⋅", "."),
    ("≠", "!="), ("≤", "<="), ("≥", ">="),
    ("≈", "~"), ("≅", "~"), ("∝", "proporcional a"),
    ("±", "+/-"), ("∓", "-/+"), ("≡", "equivale a"),
    # Letras gregas comuns
    ("Δ", "Delta"), ("δ", "delta"), ("α", "alpha"), ("β", "beta"),
    ("γ", "gama"), ("λ", "lambda"), ("π", "pi"), ("μ", "micro"),
    ("Ω", "Ohm"), ("ω", "omega"), ("θ", "teta"), ("Σ", "Soma"),
    # Graus e sinais
    ("°", "o"), ("º", "o"), ("ª", "a"),
    # Tracos/aspas
    ("—", "-"), ("–", "-"), ("−", "-"),
    ("‘", "'"), ("’", "'"), ("‚", "'"),
    ("“", '"'), ("”", '"'), ("„", '"'),
    # Marcadores
    ("•", "-"), ("·", "-"), ("◦", "-"), ("▪", "-"),
    ("□", "[ ]"), ("■", "[*]"),
    # Outros possiveis glifos problematicos
    ("…", "..."), ("†", "+"), ("‡", "++"),
]


def _normalize_text(text: str) -> str:
    """Remove caracteres Unicode problematicos da fonte Arial."""
    if not isinstance(text, str):
        return text
    for old, new in _UNICODE_SUBS:
        text = text.replace(old, new)
    return text


def _deep_normalize(obj: Any) -> Any:
    """Aplica _normalize_text em todas as strings de um dict/list."""
    if isinstance(obj, str):
        return _normalize_text(obj)
    if isinstance(obj, list):
        return [_deep_normalize(v) for v in obj]
    if isinstance(obj, dict):
        return {k: _deep_normalize(v) for k, v in obj.items()}
    return obj
