"""Regera todos os 92 PDFs com as novas capas da Wikipedia."""

import io
import runpy
import sys
import traceback

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

GENERATORS = [
    # Biologia
    "generate_pdf_intro_biologia.py",
    "generate_pdf_citoplasma.py",
    "generate_pdf_organelas.py",
    "generate_pdf_nucleo.py",
    "generate_pdf_membrana.py" if False else "generate_pdf_ciclo.py",
    "generate_pdf_metabolismo.py",
    "generate_pdf_gametogenese.py",
    "generate_pdf_anomalias.py",
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
    "generate_pdf_principios_elementares.py",
    # Quimica
    "generate_quimica_batch1.py",
    "generate_quimica_batch2.py",
    "generate_quimica_batch3.py",
    # Fisica
    "generate_fisica_batch1.py",
    "generate_fisica_batch2.py",
    "generate_fisica_batch3.py",
    # Matematica
    "generate_matematica_batch1.py",
    "generate_matematica_batch2.py",
    # Portugues
    "generate_portugues_batch1.py",
    "generate_portugues_batch2.py",
    # Ingles
    "generate_ingles_batch.py",
    # Espanhol
    "generate_espanhol_batch.py",
    # Historia
    "generate_historia_batch1.py",
    "generate_historia_batch2.py",
    # Geografia
    "generate_geografia_batch.py",
    # Filosofia
    "generate_filosofia_batch1.py",
    "generate_filosofia_batch2.py",
    # Sociologia
    "generate_sociologia_batch1.py",
    "generate_sociologia_batch2.py",
    "generate_sociologia_batch3.py",
]

def main():
    ok = 0
    fail = 0
    failed = []
    for gen in GENERATORS:
        print(f"\n{'='*60}", flush=True)
        print(f"Executando: {gen}", flush=True)
        print(f"{'='*60}", flush=True)
        try:
            runpy.run_path(gen, run_name="__main__")
            ok += 1
        except SystemExit:
            ok += 1
        except Exception:
            traceback.print_exc()
            fail += 1
            failed.append(gen)
    print(f"\n{'='*60}", flush=True)
    print(f"Concluido: {ok} OK, {fail} falhas", flush=True)
    if failed:
        print(f"Falharam: {failed}", flush=True)

if __name__ == "__main__":
    main()
