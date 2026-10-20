"""Confere uma prova extraída contra o caderno oficial em PDF.

Uso: python verificar_prova.py <ano>
Sai com código 1 se houver erro bloqueante. Avisos não bloqueiam, mas vão para revisão humana.
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path

import pymupdf

RAIZ = Path(__file__).resolve().parents[2]


MARCADOR = re.compile(r"\[\[(?:FIGURA|TABELA) \d+\]\]")


def norm(s: str) -> str:
    s = MARCADOR.sub(" ", s or "")
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", "", s)


def palavras(s: str) -> list[str]:
    s = MARCADOR.sub(" ", s or "")
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode().lower()
    return re.findall(r"[a-z0-9]+", s)


def cobertura(trecho: str, pdf_ngrams: set[tuple[str, ...]], n: int = 5) -> float:
    """Fração das sequências de n palavras do trecho que existem no PDF (tolera ordem de blocos)."""
    p = palavras(trecho)
    grams = [tuple(p[i : i + n]) for i in range(len(p) - n + 1)]
    return sum(g in pdf_ngrams for g in grams) / len(grams) if grams else 1.0


def main(ano: int) -> int:
    dados = json.loads((RAIZ / "data" / "provas_oficiais" / f"paes-{ano}.json").read_text(encoding="utf-8"))
    doc = pymupdf.open(RAIZ / "data" / "provas" / f"paes_{ano}.pdf")
    texto_pdf = " ".join(p.get_text() for p in doc)
    # versão só com o corpo (sem legendas e referências em letra pequena), na ordem de leitura
    corpo_pdf = []
    for p in doc:
        for blk in p.get_text("dict", sort=True)["blocks"]:
            for linha in blk.get("lines", []):
                if linha["spans"] and max(s["size"] for s in linha["spans"]) >= 9.2:
                    corpo_pdf.append("".join(s["text"] for s in linha["spans"]))
    pdf = norm(texto_pdf)
    pdf_ngrams: set[tuple[str, ...]] = set()
    for fonte in (texto_pdf, " ".join(corpo_pdf)):
        pw = palavras(fonte)
        pdf_ngrams |= {tuple(pw[i : i + 5]) for i in range(len(pw) - 4)}

    erros: list[str] = []
    avisos: list[str] = []
    qs = dados["questoes"]

    esperado = {f"{n:02d}" for n in range(1, 61) if not 16 <= n <= 20} | {
        f"{n}-{lg}" for n in range(16, 21) for lg in ("en", "es")
    }
    achado = {q["id"].split(f"paes-{ano}-")[1] for q in qs}
    if achado != esperado:
        erros.append(f"faltam {sorted(esperado - achado)} · sobram {sorted(achado - esperado)}")

    textos = {t["codigo"]: t for t in dados["textos_base"]}
    for t in dados["textos_base"]:
        # poemas e títulos quebram a ordem do texto corrido; vale a cobertura por trechos
        cob = cobertura(t["conteudo"], pdf_ngrams)
        if norm(t["conteudo"]) and cob < 0.9:
            erros.append(f"texto {t['codigo']}: só {cob:.0%} confere com o PDF")

    for q in qs:
        qid = q["id"]
        if len(q["alternativas"]) != 5 or any(not a.strip() for a in q["alternativas"]):
            erros.append(f"{qid}: alternativas incompletas")
        if q["gabarito"] is None and not q["anulada"]:
            erros.append(f"{qid}: sem gabarito oficial")
        revisada = bool(q.get("revisao_manual"))
        for trecho, rotulo in [(q["enunciado"], "enunciado")] + [
            (a, f"alternativa {'ABCDE'[i]}") for i, a in enumerate(q["alternativas"])
        ]:
            if re.search(r"[-]", trecho):
                erros.append(f"{qid}: {rotulo} tem caractere de fonte Symbol não convertido")
            if re.search(r"\(\s\)\s*\d|^\s*\d?\s*\(\s\)", trecho) and not revisada:
                erros.append(f"{qid}: {rotulo} parece fração quebrada: {trecho[-40:]!r}")
            if revisada and rotulo.startswith("alternativa"):
                continue  # transcrita à mão da página do caderno
            trecho = re.sub(r"\\\(.*?\\\)", " ", trecho)  # fórmulas \(...\) conferidas na revisão
            if not norm(trecho):
                continue
            if len(palavras(trecho)) < 5:
                if norm(trecho) not in pdf:
                    erros.append(f"{qid}: {rotulo} não existe no PDF")
                continue
            cob = cobertura(trecho, pdf_ngrams)
            if cob < 0.9 and q.get("conferida_visualmente"):
                avisos.append(f"{qid}: {rotulo} {cob:.0%} confere com o PDF — conferida visualmente na revisão")
            elif cob < 0.9:
                erros.append(f"{qid}: {rotulo} só {cob:.0%} confere com o PDF")
            elif cob < 1:
                avisos.append(f"{qid}: {rotulo} {cob:.0%} confere com o PDF (ordem de blocos?)")
        if len(norm(q["enunciado"])) < 25:
            avisos.append(f"{qid}: enunciado muito curto")
        contexto = " ".join(palavras(q["enunciado"] + " " + (textos.get(q["texto_base"] or "", {}).get("conteudo", ""))))
        cita_imagem = re.search(
            r"\b(figura|grafico|imagem|imagens|charge|cartoon|tirinha|quadrinhos|mapa|tabela|esquema|tela|foto)\b", contexto
        )
        tem_fig = q["figuras"] or (q["texto_base"] and textos[q["texto_base"]]["figuras"])
        if cita_imagem and not tem_fig:
            avisos.append(f"{qid}: cita '{cita_imagem.group(0)}' mas não tem figura")
        if re.search(r"(?:rodape|educacaosuperior|processoseletivodeacesso)", norm(q["alternativas"][4] if q["alternativas"] else "")):
            erros.append(f"{qid}: alternativa E com lixo de rodapé")

    print(f"Prova {ano}: {len(qs)} questões, {len(textos)} textos de apoio")
    print(f"ERROS ({len(erros)}):")
    for e in erros:
        print("  -", e)
    print(f"AVISOS para revisão ({len(avisos)}):")
    for a in avisos:
        print("  -", a)
    return 1 if erros else 0


if __name__ == "__main__":
    sys.exit(main(int(sys.argv[1])))
