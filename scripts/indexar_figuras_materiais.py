"""Gera data/materiais/figuras_por_pdf.json a partir dos geradores de PDF.

Cada backend/generate_*.py lista as figuras que entraram no PDF (arquivo,
legenda, fonte). O leitor de materiais do app usa este índice para mostrar as
mesmas figuras no meio do texto, com legenda e crédito.

    python scripts/indexar_figuras_materiais.py
"""

from __future__ import annotations

import ast
import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
BACKEND = RAIZ / "backend"
IMG_DIR = RAIZ / "data" / "materiais" / "imagens"
PDF_DIR = RAIZ / "data" / "materiais"
SAIDA = RAIZ / "data" / "materiais" / "figuras_por_pdf.json"


def _texto(no: ast.AST) -> str | None:
    return no.value if isinstance(no, ast.Constant) and isinstance(no.value, str) else None


def _figuras(no: ast.AST) -> list[dict[str, str]]:
    """Listas de dicts com "file" (ou "arquivo") e "caption" dentro do nó."""
    achadas: list[dict[str, str]] = []
    for sub in ast.walk(no):
        if not isinstance(sub, ast.Dict):
            continue
        chaves = [_texto(k) if k is not None else None for k in sub.keys]
        if "file" not in chaves and "arquivo" not in chaves:
            continue
        item: dict[str, str] = {}
        for k, v in zip(chaves, sub.values):
            t = _texto(v)
            if k and t:
                item[k] = t
        arquivo = item.get("file") or item.get("arquivo")
        if arquivo and (IMG_DIR / arquivo).exists():
            achadas.append(
                {
                    "file": arquivo,
                    "caption": item.get("caption") or item.get("legenda") or "",
                    "source": item.get("source") or item.get("fonte") or "",
                    "sourceUrl": item.get("source_url") or "",
                }
            )
    return achadas


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    pdfs_existentes = {p.name for p in PDF_DIR.glob("*.pdf")}
    indice: dict[str, list[dict[str, str]]] = {}
    for script in sorted(BACKEND.glob("generate_*.py")):
        arvore = ast.parse(script.read_text(encoding="utf-8"))
        for fn in [n for n in ast.walk(arvore) if isinstance(n, ast.FunctionDef)]:
            nomes = {
                t for t in (_texto(s) for s in ast.walk(fn)) if t and t.endswith(".pdf") and t in pdfs_existentes
            }
            if len(nomes) != 1:
                continue
            figs = _figuras(fn)
            if figs:
                pdf = nomes.pop()
                vistos = {f["file"] for f in indice.get(pdf, [])}
                indice.setdefault(pdf, []).extend(f for f in figs if f["file"] not in vistos)
    SAIDA.write_text(json.dumps(indice, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    total = sum(len(v) for v in indice.values())
    print(f"{len(indice)} PDFs com figuras · {total} figuras → {SAIDA.relative_to(RAIZ)}")
    sem = sorted(pdfs_existentes - set(indice))
    print(f"PDFs sem figura no índice ({len(sem)}): {', '.join(sem)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
