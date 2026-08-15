# -*- coding: utf-8 -*-
"""Patch do Paragraph do ReportLab para normalizar Unicode globalmente.

Carregue este modulo ANTES de qualquer gerador de PDF, ex:
    import backend.patch_reportlab
    exec(open("backend/generate_pdf_X.py").read())

Isso faz com que todo texto passado a Paragraph seja limpo de
subscritos, sobrescritos, setas e simbolos nao suportados.
"""

from __future__ import annotations

import reportlab.platypus
from reportlab.platypus import Paragraph as _OriginalParagraph

from text_utils import _normalize_text


class _NormalizedParagraph(_OriginalParagraph):
    def __init__(self, text, *args, **kwargs):
        if isinstance(text, str):
            text = _normalize_text(text)
        super().__init__(text, *args, **kwargs)


# Substitui a classe no modulo original
reportlab.platypus.Paragraph = _NormalizedParagraph
