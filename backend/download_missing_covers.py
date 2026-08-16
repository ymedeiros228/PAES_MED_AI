# -*- coding: utf-8 -*-
"""Baixa as 13 capas que faltam - versao sincrona com httpx.get."""

from __future__ import annotations
import re, json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
from pathlib import Path
import httpx
from PIL import Image as PILImage

IMG_DIR = Path(__file__).resolve().parent.parent / "data" / "materiais" / "imagens"
HEADERS = {"User-Agent": "PAESMedAI/1.0 (educational project; https://paesmedai.com)"}
BAD = ("logo","icon","symbol","commons-","wiki-","ambox","stub","portal","flag","seal","coat","pictogram","portrait","bust","statue","person","selfie","face","headshot","edit-clear","semi-protect","question_book","disambig","crystal","nuvola","gnome","fairy","book-2","pencil","merge","delete","featured","good_article","sound","video","speaker","star","tick","cross","check","arrow","hand","stop","puzzle","fleur","emblem","incubator","wiktionary","wikiquote","wikisource","wikibooks")

def is_useful(fn):
    fn = fn.lower()
    return not any(b in fn for b in BAD)

def search_article(query):
    try:
        params = {"action":"query","list":"search","srsearch":query,"srlimit":"1","srprop":"","format":"json"}
        r = httpx.get("https://pt.wikipedia.org/w/api.php", params=params, timeout=30, headers=HEADERS)
        r.raise_for_status()
        res = r.json().get("query",{}).get("search",[])
        return res[0]["title"] if res else None
    except Exception as e:
        print(f"    Erro search: {e}", flush=True)
        return None

def get_page_images(title, n=30):
    try:
        params = {"action":"query","titles":title,"prop":"images","imlimit":str(n),"format":"json"}
        r = httpx.get("https://pt.wikipedia.org/w/api.php", params=params, timeout=30, headers=HEADERS)
        r.raise_for_status()
        pages = r.json().get("query",{}).get("pages",{})
        imgs = []
        for _,pd in pages.items():
            for ii in pd.get("images",[]):
                fn = ii.get("title","")
                if is_useful(fn) and not fn.lower().endswith(".svg"):
                    imgs.append(fn)
        return imgs
    except Exception as e:
        print(f"    Erro images: {e}", flush=True)
        return []

def get_image_url(filename):
    try:
        params = {"action":"query","titles":filename,"prop":"imageinfo","iiprop":"url|size|mime","iiurlwidth":"1000","format":"json"}
        r = httpx.get("https://pt.wikipedia.org/w/api.php", params=params, timeout=30, headers=HEADERS)
        r.raise_for_status()
        pages = r.json().get("query",{}).get("pages",{})
        for _,pd in pages.items():
            il = pd.get("imageinfo",[])
            if il:
                i = il[0]
                return {"url":i.get("url",""),"thumburl":i.get("thumburl",""),"width":i.get("thumbwidth",0),"height":i.get("thumbheight",0)}
    except Exception as e:
        print(f"    Erro imageinfo: {e}", flush=True)
    return None

def download(url, fp):
    try:
        r = httpx.get(url, follow_redirects=True, timeout=60, headers=HEADERS)
        if r.status_code != 200: return False
        fp.write_bytes(r.content)
        PILImage.open(fp).verify()
        return True
    except Exception as e:
        print(f"    Erro download: {e}", flush=True)
        return False

def fetch_cover(query, prefix):
    print(f"  {query} -> {prefix}", flush=True)
    title = search_article(query)
    if not title:
        print(f"    Artigo nao encontrado", flush=True)
        return None
    print(f"    Artigo: {title}", flush=True)
    imgs = get_page_images(title, 30)
    if not imgs:
        print(f"    Sem imagens", flush=True)
        return None
    print(f"    {len(imgs)} candidatas", flush=True)
    for fn in imgs[:8]:
        info = get_image_url(fn)
        if not info or not info.get("url"): continue
        w,h = info.get("width",0), info.get("height",0)
        if w < 300 or h < 200: continue
        dl = info.get("thumburl") or info["url"]
        ext = ".jpg"
        for e in (".jpg",".jpeg",".png",".gif",".webp"):
            if e in info["url"].lower(): ext = e; break
        out = f"{prefix}_capa{ext}"
        fp = IMG_DIR / out
        ok = download(dl, fp)
        if ok:
            sz = fp.stat().st_size/1024
            print(f"    OK: {out} ({sz:.0f} KB)", flush=True)
            clean = fn.replace("Ficheiro:","").replace("File:","")
            clean = re.sub(r'\.(jpg|jpeg|png|gif|webp|svg)$','',clean,flags=re.I).replace('_',' ')[:100]
            return {"file":out,"caption":clean,"source":"Wikipédia (Português do Brasil)","source_url":info["url"]}
    print(f"    Nenhuma adequada", flush=True)
    return None

MISSING = [
    ("Modelo de Bohr", "qu_modelos"),
    ("Diagrama de Venn", "mt_conj"),
    ("Matriz (matematica)", "mt_matriz"),
    ("Analise combinatoria", "mt_comb"),
    ("Estatistica", "mt_stat"),
    ("Dissertacao", "pt_text"),
    ("Sintaxe", "pt_morfo"),
    ("Periodo composto", "pt_sint"),
    ("Vocabulario", "ing_lex"),
    ("Lectura", "esp_comp"),
    ("Semantica", "esp_sem"),
    ("Silogismo", "filo_log"),
    ("Soberania", "soc_est"),
]

def main():
    print(f"Baixando {len(MISSING)} capas que faltam...", flush=True)
    results = {}
    for query, prefix in MISSING:
        cover = fetch_cover(query, prefix)
        if cover: results[prefix] = cover
        print(flush=True)
    meta_path = Path(__file__).resolve().parent / "cover_images_missing.py"
    with open(meta_path, "w", encoding="utf-8") as f:
        f.write("# -*- coding: utf-8 -*-\n")
        f.write("COVER_IMAGES_MISSING = {\n")
        for key, img in results.items():
            cap = img["caption"].replace('"',"'")
            url = img["source_url"].replace('"',"'")
            f.write(f'    "{key}": {{"file": "{img["file"]}", "caption": "{cap}", "source": "{img["source"]}", "source_url": "{url}"}},\n')
        f.write("}\n")
    print(f"Total: {len(results)}/{len(MISSING)}", flush=True)

if __name__ == "__main__":
    main()
