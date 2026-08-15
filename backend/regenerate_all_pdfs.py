# -*- coding: utf-8 -*-
"""Regenera todos os PDFs antigos (Biologia + outros geradores custom)
com o patch de normalizacao Unicode.

Uso:
    python backend/regenerate_all_pdfs.py
"""

import os
import sys
import runpy
import time
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent
ROOT = BACKEND_DIR.parent
DATA_DIR = ROOT / "data" / "materiais"

sys.path.insert(0, str(BACKEND_DIR))

# Carrega o patch ANTES de qualquer gerador
import patch_reportlab  # noqa: E402

# Geradores que nao usam pdf_base.py (precisam do patch)
SCRIPTS = [
    "generate_pdf_intro_biologia.py",
    "generate_pdf_citoplasma.py",
    "generate_pdf_organelas.py",
    "generate_pdf_nucleo.py",
    "generate_pdf_ciclo.py",
    "generate_pdf_gametogenese.py",
    "generate_pdf_anomalias.py",
    "generate_pdf_metabolismo.py",
    "generate_pdf_reproducao.py",
    "generate_pdf_histologia.py",
    "generate_pdf_ecologia.py",
    "generate_pdf_classificacao.py",
    "generate_pdf_microbiologia.py",
    "generate_pdf_botanica.py",
    "generate_pdf_zoologia.py",
    "generate_pdf_genetica.py",
    "generate_pdf_evolucao.py",
    "generate_pdf_saude_doencas.py",
    "generate_pdf_material.py",
    "generate_pdf_principios_elementares.py",
]


def main():
    os.chdir(BACKEND_DIR)
    errors = []
    for script in SCRIPTS:
        path = BACKEND_DIR / script
        if not path.exists():
            print(f"IGNORANDO (nao existe): {script}")
            continue
        start = time.time()
        print(f"\n[INICIANDO] {script}")
        try:
            runpy.run_path(str(path), run_name="__main__")
            elapsed = time.time() - start
            print(f"[OK] {script} em {elapsed:.1f}s")
        except Exception as e:
            print(f"[ERRO] {script}: {e}")
            errors.append((script, str(e)))

    print("\n" + "=" * 60)
    print(f"Regenerados: {len(SCRIPTS) - len(errors)}/{len(SCRIPTS)}")
    if errors:
        print("\nErros:")
        for s, e in errors:
            print(f"  - {s}: {e}")
    else:
        print("Nenhum erro!")

    # Conta PDFs finais
    pdfs = sorted(DATA_DIR.glob("*.pdf"))
    bi = [p for p in pdfs if p.name.startswith("BI_")]
    qu = [p for p in pdfs if p.name.startswith("QU_")]
    print(f"\nPDFs no data/materiais: {len(pdfs)}")
    print(f"  Biologia: {len(bi)}")
    print(f"  Quimica:  {len(qu)}")


if __name__ == "__main__":
    main()
