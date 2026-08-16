# -*- coding: utf-8 -*-
"""Baixa imagens reais da Wikipédia (Português do Brasil) para Filosofia e Sociologia."""

from __future__ import annotations

import asyncio
import urllib.parse
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
)

IMAGE_EXTS = (".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg")

def is_useful(fn):
    fn = fn.lower()
    return not any(bad in fn for bad in BAD_PATTERNS)

async def search_article(client, query):
    params = {"action": "query", "list": "search", "srsearch": query,
              "srlimit": "1", "srprop": "", "format": "json"}
    try:
        r = await client.get("https://pt.wikipedia.org/w/api.php", params=params)
        r.raise_for_status()
        res = r.json().get("query", {}).get("search", [])
        return res[0]["title"] if res else None
    except:
        return None

async def get_page_images(client, title, max_imgs=10):
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
    except:
        pass
    return imgs

async def get_image_url(client, filename):
    params = {"action": "query", "titles": filename, "prop": "imageinfo",
              "iiprop": "url|size|mime", "iiurlwidth": "800", "format": "json"}
    try:
        r = await client.get("https://pt.wikipedia.org/w/api.php", params=params)
        r.raise_for_status()
        pages = r.json().get("query", {}).get("pages", {})
        for _, pd in pages.items():
            il = pd.get("imageinfo", [])
            if il:
                i = il[0]
                return {"url": i.get("url", ""), "thumburl": i.get("thumburl", "")}
    except:
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
        except:
            return False
    except:
        return False

async def fetch_topic(client, query, prefix, max_imgs=2):
    print(f"  Buscando: {query}")
    title = await search_article(client, query)
    if not title:
        print(f"    Nao encontrado")
        return []
    print(f"    Artigo: {title}")
    pimgs = await get_page_images(client, title, max_imgs=max_imgs*5)
    if not pimgs:
        print(f"    Sem imagens")
        return []
    print(f"    {len(pimgs)} candidatas")
    result = []
    for ii in pimgs:
        if len(result) >= max_imgs:
            break
        fn = ii["filename"]
        if fn.lower().endswith(".svg"):
            continue
        info = await get_image_url(client, fn)
        if not info or not info.get("url"):
            continue
        dl = info.get("thumburl") or info["url"]
        ext = ".jpg"
        for e in IMAGE_EXTS:
            if e in info["url"].lower():
                ext = e
                break
        out = f"{prefix}_real{len(result)+1}{ext}"
        fp = IMG_DIR / out
        ok = await download_image(client, dl, fp)
        if ok:
            sz = fp.stat().st_size / 1024
            print(f"    OK: {out} ({sz:.0f} KB)")
            clean = fn.replace("Ficheiro:", "").replace("File:", "")
            clean = re.sub(r'\.(jpg|jpeg|png|gif|webp|svg)$', '', clean, flags=re.I)
            clean = clean.replace('_', ' ')[:100]
            result.append({"file": out, "caption": clean,
                          "source": "Wikipédia (Português do Brasil)", "source_url": info["url"]})
    return result

# Filosofia: 7 topicos
FILO_TOPICS = [
    ("filo_cultura", "Cultura", "filo_cultura"),
    ("filo_conhecimento", "Epistemologia", "filo_conhec"),
    ("filo_filosofia", "Filosofia", "filo_filos"),
    ("filo_logica", "Logica", "filo_logica"),
    ("filo_estetica", "Estetica", "filo_estetica"),
    ("filo_politica", "Filosofia politica", "filo_politica"),
    ("filo_etica", "Etica", "filo_etica"),
]

# Sociologia: 9 topicos
SOCIO_TOPICS = [
    ("socio_surgimento", "Sociologia", "socio_surg"),
    ("socio_classicas", "Karl Marx", "socio_class"),
    ("socio_conceitos", "Socializacao", "socio_conc"),
    ("socio_mudanca", "Mobilidade social", "socio_mud"),
    ("socio_violencia", "Violencia", "socio_viol"),
    ("socio_cultura", "Industria cultural", "socio_cult"),
    ("socio_trabalho", "Taylorismo fordismo", "socio_trab"),
    ("socio_estado", "Estado governo", "socio_estado"),
    ("socio_contemporaneos", "Globalizacao", "socio_contemp"),
]

async def main():
    print("=== FILOSOFIA ===")
    filo_results = {}
    async with httpx.AsyncClient(timeout=30, headers=HEADERS) as client:
        for key, q, pref in FILO_TOPICS:
            imgs = await fetch_topic(client, q, pref, max_imgs=2)
            filo_results[key] = imgs
            print()

    print("=== SOCIOLOGIA ===")
    socio_results = {}
    async with httpx.AsyncClient(timeout=30, headers=HEADERS) as client:
        for key, q, pref in SOCIO_TOPICS:
            imgs = await fetch_topic(client, q, pref, max_imgs=2)
            socio_results[key] = imgs
            print()

    # Salva Filosofia
    mp = Path(__file__).resolve().parent / "filosofia_real_images.py"
    with open(mp, "w", encoding="utf-8") as f:
        f.write("# -*- coding: utf-8 -*-\n\"\"\"Imagens reais da Wikipédia (Português do Brasil) para Filosofia.\"\"\"\n\nREAL_IMAGES = {\n")
        for key, imgs in filo_results.items():
            f.write(f'    "{key}": [\n')
            for img in imgs:
                cap = img["caption"].replace('"', "'")
                url = img["source_url"].replace('"', "'")
                f.write(f'        {{"file": "{img["file"]}", "caption": "{cap}", "source": "{img["source"]}", "source_url": "{url}"}},\n')
            f.write("    ],\n")
        f.write("}\n")
    print(f"Filosofia: {mp}")

    # Salva Sociologia
    mp = Path(__file__).resolve().parent / "sociologia_real_images.py"
    with open(mp, "w", encoding="utf-8") as f:
        f.write("# -*- coding: utf-8 -*-\n\"\"\"Imagens reais da Wikipédia (Português do Brasil) para Sociologia.\"\"\"\n\nREAL_IMAGES = {\n")
        for key, imgs in socio_results.items():
            f.write(f'    "{key}": [\n')
            for img in imgs:
                cap = img["caption"].replace('"', "'")
                url = img["source_url"].replace('"', "'")
                f.write(f'        {{"file": "{img["file"]}", "caption": "{cap}", "source": "{img["source"]}", "source_url": "{url}"}},\n')
            f.write("    ],\n")
        f.write("}\n")
    print(f"Sociologia: {mp}")

    t1 = sum(len(v) for v in filo_results.values())
    t2 = sum(len(v) for v in socio_results.values())
    print(f"\nTotal Filosofia: {t1} | Sociologia: {t2}")

if __name__ == "__main__":
    asyncio.run(main())
