"""Baixa imagens de capa relevantes da Wikipédia (Português do Brasil) para todos os topicos.

Busca imagens educacionais reais (diagramas, ilustracoes cientificas,
fotos de laboratorio, microscopias) para usar como capa na primeira
pagina de cada PDF. Evita fotos de pessoas aleatorias.
"""

from __future__ import annotations

import asyncio
import re
from pathlib import Path

import httpx
from PIL import Image as PILImage

IMG_DIR = Path(__file__).resolve().parent.parent / "data" / "materiais" / "imagens"
IMG_DIR.mkdir(parents=True, exist_ok=True)

HEADERS = {"User-Agent": "PAESMedAI/1.0 (educational project; https://paesmedai.com)"}

BAD_PATTERNS = (
    "commons-logo", "wiki-letter", "semi-protect", "edit-clear",
    "crystal_clear", "question_book", "disambig", "ambox", "red_pog",
    "wiktionary", "wikiquote", "wikisource", "wikibooks", "portal",
    "stub", "editor", "nuvola", "gnome", "fairytale", "book-2",
    "write", "pencil", "merge", "delete", "featured", "good_article",
    "sound-icon", "video", "speaker", "circle", "star", "tick",
    "cross", "check", "yes", "no", "stop", "hand", "arrow",
    "portal-puzzle", "fleur-de-lis", "coa", "coat_of_arms",
    "flag_of", "seal_of", "commons_", "wiki_", "incubator",
    "pictogram", "icon", "logo", "symbol", "emblem",
    "portrait", "bust_", "statue_", "tombstone", "grave",
    "person_", "people_", "man_", "woman_", "boy_", "girl_",
    "selfie", "face", "headshot",
)

IMAGE_EXTS = (".jpg", ".jpeg", ".png", ".gif", ".webp")

def is_useful(fn):
    fn = fn.lower()
    if any(bad in fn for bad in BAD_PATTERNS):
        return False
    return True

async def search_article(client, query):
    params = {"action": "query", "list": "search", "srsearch": query,
              "srlimit": "1", "srprop": "", "format": "json"}
    try:
        r = await client.get("https://pt.wikipedia.org/w/api.php", params=params)
        r.raise_for_status()
        res = r.json().get("query", {}).get("search", [])
        return res[0]["title"] if res else None
    except Exception:
        return None

async def get_page_images(client, title, max_imgs=15):
    params = {"action": "query", "titles": title, "prop": "images",
              "imlimit": str(max_imgs), "format": "json"}
    imgs = []
    try:
        r = await client.get("https://pt.wikipedia.org/w/api.php", params=params)
        r.raise_for_status()
        pages = r.json().get("query", {}).get("pages", {})
        for _, pd in pages.items():
            for ii in pd.get("images", []):
                fn = ii.get("title", "")
                if is_useful(fn):
                    imgs.append({"filename": fn})
    except Exception:
        pass
    return imgs

async def get_image_url(client, filename):
    params = {"action": "query", "titles": filename, "prop": "imageinfo",
              "iiprop": "url|size|mime", "iiurlwidth": "1000", "format": "json"}
    try:
        r = await client.get("https://pt.wikipedia.org/w/api.php", params=params)
        r.raise_for_status()
        pages = r.json().get("query", {}).get("pages", {})
        for _, pd in pages.items():
            il = pd.get("imageinfo", [])
            if il:
                i = il[0]
                return {"url": i.get("url", ""), "thumburl": i.get("thumburl", ""),
                        "width": i.get("thumbwidth", 0), "height": i.get("thumbheight", 0)}
    except Exception:
        pass
    return None

async def download_image(client, url, filepath):
    try:
        r = await client.get(url, follow_redirects=True)
        if r.status_code != 200:
            return False
        filepath.write_bytes(r.content)
        try:
            PILImage.open(filepath).verify()
            return True
        except Exception:
            return False
    except Exception:
        return False

async def fetch_cover(client, query, prefix, max_attempts=5):
    """Busca uma imagem de capa relevante. Evita fotos de pessoas."""
    print(f"  Buscando capa: {query}")
    title = await search_article(client, query)
    if not title:
        print("    Artigo nao encontrado")
        return None
    print(f"    Artigo: {title}")
    pimgs = await get_page_images(client, title, max_imgs=max_attempts*4)
    if not pimgs:
        print("    Sem imagens")
        return None
    print(f"    {len(pimgs)} candidatas")

    for ii in pimgs[:max_attempts]:
        fn = ii["filename"]
        if fn.lower().endswith(".svg"):
            continue
        info = await get_image_url(client, fn)
        if not info or not info.get("url"):
            continue
        # Prefere imagens maiores (mais provavel ser relevante)
        w = info.get("width", 0)
        h = info.get("height", 0)
        if w < 300 or h < 200:
            continue
        dl = info.get("thumburl") or info["url"]
        ext = ".jpg"
        for e in IMAGE_EXTS:
            if e in info["url"].lower():
                ext = e
                break
        out = f"{prefix}_capa{ext}"
        fp = IMG_DIR / out
        ok = await download_image(client, dl, fp)
        if ok:
            sz = fp.stat().st_size / 1024
            print(f"    OK: {out} ({sz:.0f} KB, {w}x{h})")
            clean = fn.replace("Ficheiro:", "").replace("File:", "")
            clean = re.sub(r'\.(jpg|jpeg|png|gif|webp|svg)$', '', clean, flags=re.I)
            clean = clean.replace('_', ' ')[:100]
            return {"file": out, "caption": clean,
                    "source": "Wikipédia (Português do Brasil)", "source_url": info["url"]}
    print("    Nenhuma imagem adequada")
    return None

# Mapeia cada PDF ao seu termo de busca na Wikipedia
# Foco em topicos cientificos/educacionais, nao pessoas
COVERS = [
    # Biologia (19) - topicos biologicos
    ("BI_INTRODUCAO_BIOLOGIA", "Biologia", "bi_intro"),
    ("BI_CITOLOGIA", "Celula", "bi_cito"),
    ("BI_METABOLISMO_CELULAR", "Metabolismo", "bi_metab"),
    ("BI_REPRODUCAO_EMBRIOLOGIA", "Embriologia", "bi_embrio"),
    ("BI_HISTOLOGIA", "Tecido biologico", "bi_histo"),
    ("BI_ECOLOGIA", "Ecologia", "bi_eco"),
    ("BI_CLASSIFICACAO_SISTEMATICA", "Taxonomia biologia", "bi_taxo"),
    ("BI_MICROBIOLOGIA", "Microbiologia", "bi_micro"),
    ("BI_BOTANICA", "Botanica", "bi_bota"),
    ("BI_ZOOLOGIA", "Zoologia", "bi_zoo"),
    ("BI_GENETICA", "Genetica", "bi_gene"),
    ("BI_EVOLUCAO", "Evolucao biologia", "bi_evo"),
    ("BI_SAUDE_DOENCAS", "Doenca infecciosa", "bi_saude"),
    # Quimica (13)
    ("QU_ATOMOS_E_LEIS_PONDERAIS", "Atomo", "qu_atomo"),
    ("QU_MODELOS_ATOMICOS", "Modelo atomico", "qu_modelos"),
    ("QU_TABELA_PERIODICA", "Tabela periodica", "qu_tabela"),
    ("QU_LIGACOES_QUIMICAS", "Ligacao quimica", "qu_ligacoes"),
    ("QU_FUNCOES_INORGANICAS", "Compostos inorganicos", "qu_inorg"),
    ("QU_REACOES_QUIMICAS", "Reacao quimica", "qu_reacoes"),
    ("QU_CALCULOS_QUIMICOS", "Estequiometria", "qu_calc"),
    ("QU_SOLUCOES", "Solucao quimica", "qu_soluc"),
    ("QU_CINETICA_E_EQUILIBRIO", "Equilibrio quimico", "qu_equil"),
    ("QU_ELETROQUIMICA", "Eletroquimica", "qu_eletro"),
    ("QU_TERMOQUIMICA", "Termodinamica quimica", "qu_termo"),
    ("QU_QUIMICA_ORGANICA", "Quimica organica", "qu_org"),
    ("QU_QUIMICA_AMBIENTAL", "Quimica ambiental", "qu_amb"),
    # Fisica (11)
    ("FI_GRANDEZAS_E_MEDIDAS", "Grandezas fisicas", "fi_grand"),
    ("FI_CINEMATICA", "Cinematica", "fi_cinem"),
    ("FI_DINAMICA", "Dinamica fisica", "fi_dinam"),
    ("FI_HIDROSTATICA", "Hidrostatica", "fi_hidro"),
    ("FI_TERMOLOGIA", "Termodinamica", "fi_termo"),
    ("FI_OPTICA_GEOMETRICA", "Optica", "fi_optica"),
    ("FI_ONDULATORIA", "Onda fisica", "fi_onda"),
    ("FI_ELETROSTATICA", "Eletrostatica", "fi_eletrost"),
    ("FI_ELETRODINAMICA", "Eletrodinamica", "fi_eletrodin"),
    ("FI_ELETROMAGNETISMO", "Eletromagnetismo", "fi_eletromag"),
    ("FI_FISICA_MODERNA", "Fisica moderna", "fi_moderna"),
    # Matematica (10)
    ("MT_ARITMETICA", "Aritmetica", "mt_arit"),
    ("MT_CONJUNTOS", "Teoria dos conjuntos", "mt_conj"),
    ("MT_FUNCOES", "Funcao matematica", "mt_func"),
    ("MT_GEOMETRIA_PLANA", "Geometria plana", "mt_geoplan"),
    ("MT_GEOMETRIA_ESPACIAL", "Geometria espacial", "mt_geoesp"),
    ("MT_MATRIZES", "Matriz matematica", "mt_matriz"),
    ("MT_TRIGONOMETRIA", "Trigonometria", "mt_trigo"),
    ("MT_COMBINATORIA", "Combinatoria", "mt_comb"),
    ("MT_ESTATISTICA", "Estatistica", "mt_stat"),
    ("MT_GEOMETRIA_ANALITICA", "Geometria analitica", "mt_geoanal"),
    # Portugues (7)
    ("PT_COMUNICACAO", "Comunicacao", "pt_com"),
    ("PT_SEMANTICA", "Semantica", "pt_sem"),
    ("PT_TEXTUALIDADE", "Texto dissertativo", "pt_text"),
    ("PT_MORFOSSINTAXE", "Sintaxe", "pt_morfo"),
    ("PT_SINTAXE_PERIODO", "Periodo composto", "pt_sint"),
    ("PT_LITERATURA", "Literatura brasileira", "pt_lit"),
    ("PT_OBRAS_LITERARIAS", "Literatura", "pt_obras"),
    # Ingles (3)
    ("ING_LEITURA_INTERPRETACAO", "Reading comprehension", "ing_leit"),
    ("ING_LEXICO", "English vocabulary", "ing_lex"),
    ("ING_GRAMATICA", "English grammar", "ing_gram"),
    # Espanhol (3)
    ("ESP_COMPRENSION_TEXTOS", "Comprension lectora", "esp_comp"),
    ("ESP_SEMANTICA_LEXICO", "Lexico espanol", "esp_sem"),
    ("ESP_GRAMATICA", "Gramatica espanola", "esp_gram"),
    # Historia (6) - ja tem imagens reais, mas vamos melhorar a capa
    ("HIS_MUNDO_ANTIGO", "Piramide do Egito", "his_antigo"),
    ("HIS_MUNDO_MEDIEVAL", "Castelo medieval", "his_medieval"),
    ("HIS_IDADE_MODERNA", "Caravela portuguesa", "his_moderna"),
    ("HIS_IDADE_CONTEMPORANEA", "Revolucao Francesa", "his_contemp"),
    ("HIS_BRASIL_CONTEMPORANEO", "Revolucao de 1930 Brasil", "his_brasil"),
    ("HIS_MARANHAO", "Centro historico Sao Luis", "his_ma"),
    # Geografia (4)
    ("GEO_FISICA", "Estrutura interna da Terra", "geo_fis"),
    ("GEO_HUMANA", "Urbanizacao", "geo_hum"),
    ("GEO_MARANHAO", "Sao Luis Maranhao centro historico", "geo_ma"),
    ("GEO_TEMAS_CONTEMPORANEOS", "Desenvolvimento sustentavel", "geo_cont"),
    # Filosofia (7) - focar em conceitos, nao filosofos
    ("FIL_CULTURA", "Cultura simbolo", "filo_cult"),
    ("FIL_CONHECIMENTO", "Metodo cientifico", "filo_con"),
    ("FIL_A_FILOSOFIA", "Acrópole Atenas", "filo_filos"),
    ("FIL_LOGICA", "Silogismo logica", "filo_log"),
    ("FIL_ESTETICA", "Arte renascentista", "filo_est"),
    ("FIL_POLITICA", "Democracia atenas", "filo_pol"),
    ("FIL_ETICA", "Direitos humanos", "filo_et"),
    # Sociologia (9) - focar em conceitos sociais
    ("SOC_SURGIMENTO", "Revolucao Industrial", "soc_surg"),
    ("SOC_PERSPECTIVAS_CLASSICAS", "Sociologia", "soc_class"),
    ("SOC_CONCEITOS_BASICOS", "Socializacao", "soc_conc"),
    ("SOC_MUDANCA_SOCIAL", "Desigualdade social", "soc_mud"),
    ("SOC_VIOLENCIA", "Violencia urbana", "soc_viol"),
    ("SOC_CULTURA_IDEOLOGIA", "Cultura de massa", "soc_cult"),
    ("SOC_TRABALHO_SOCIEDADE", "Linha de montagem", "soc_trab"),
    ("SOC_ESTADO_PODER", "Estado governo", "soc_est"),
    ("SOC_TEMAS_CONTEMPORANEOS", "Globalizacao", "soc_cont"),
]


async def main():
    print("Baixando imagens de capa da Wikipedia para todos os PDFs...\n")
    results = {}
    async with httpx.AsyncClient(timeout=30, headers=HEADERS) as client:
        for pdf_key, query, prefix in COVERS:
            cover = await fetch_cover(client, query, prefix, max_attempts=6)
            if cover:
                results[pdf_key] = cover
            print()

    # Salva metadados
    meta_path = Path(__file__).resolve().parent / "cover_images.py"
    with open(meta_path, "w", encoding="utf-8") as f:
        f.write("# -*- coding: utf-8 -*-\n")
        f.write("\"\"\"Imagens de capa da Wikipédia (Português do Brasil) para todos os PDFs.\"\"\"\n\n")
        f.write("COVER_IMAGES = {\n")
        for key, img in results.items():
            cap = img["caption"].replace('"', "'")
            url = img["source_url"].replace('"', "'")
            f.write(f'    "{key}": {{"file": "{img["file"]}", '
                    f'"caption": "{cap}", '
                    f'"source": "{img["source"]}", '
                    f'"source_url": "{url}"}},\n')
        f.write("}\n")
    print(f"\nMetadados: {meta_path}")
    print(f"Total de capas baixadas: {len(results)}/{len(COVERS)}")


if __name__ == "__main__":
    asyncio.run(main())
