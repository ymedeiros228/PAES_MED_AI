"""Baixa imagens reais da Wikipédia (Português do Brasil) para topicos de Geografia."""

from __future__ import annotations

import asyncio
import re
from pathlib import Path

import httpx
from PIL import Image as PILImage

IMG_DIR = Path(__file__).resolve().parent.parent / "data" / "materiais" / "imagens"
IMG_DIR.mkdir(parents=True, exist_ok=True)

HEADERS = {
    "User-Agent": "PAESMedAI/1.0 (educational project; https://paesmedai.com)"
}

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


def is_useful(filename: str) -> bool:
    fn = filename.lower()
    if any(bad in fn for bad in BAD_PATTERNS):
        return False
    return True


async def search_article(client: httpx.AsyncClient, query: str) -> str | None:
    params = {
        "action": "query", "list": "search", "srsearch": query,
        "srlimit": "1", "srprop": "", "format": "json",
    }
    try:
        resp = await client.get(
            "https://pt.wikipedia.org/w/api.php", params=params)
        resp.raise_for_status()
        results = resp.json().get("query", {}).get("search", [])
        return results[0]["title"] if results else None
    except Exception:
        return None


async def get_page_images(client: httpx.AsyncClient, title: str, max_imgs: int = 10) -> list[dict]:
    params = {
        "action": "query", "titles": title,
        "prop": "images", "imlimit": str(max_imgs), "format": "json",
    }
    images = []
    try:
        resp = await client.get(
            "https://pt.wikipedia.org/w/api.php", params=params)
        resp.raise_for_status()
        data = resp.json()
        pages = data.get("query", {}).get("pages", {})
        for _page_id, page_data in pages.items():
            imgs = page_data.get("images", [])
            for img_info in imgs:
                filename = img_info.get("title", "")
                if not is_useful(filename):
                    continue
                images.append({"filename": filename})
    except Exception:
        pass
    return images


async def get_image_url(client: httpx.AsyncClient, filename: str) -> dict | None:
    params = {
        "action": "query", "titles": filename,
        "prop": "imageinfo", "iiprop": "url|size|mime",
        "iiurlwidth": "800", "format": "json",
    }
    try:
        resp = await client.get(
            "https://pt.wikipedia.org/w/api.php", params=params)
        resp.raise_for_status()
        data = resp.json()
        pages = data.get("query", {}).get("pages", {})
        for _page_id, page_data in pages.items():
            info_list = page_data.get("imageinfo", [])
            if info_list:
                info = info_list[0]
                return {
                    "url": info.get("url", ""),
                    "thumburl": info.get("thumburl", ""),
                    "mime": info.get("mime", ""),
                }
    except Exception:
        pass
    return None


async def download_image(client: httpx.AsyncClient, url: str, filepath: Path) -> bool:
    try:
        resp = await client.get(url, follow_redirects=True)
        if resp.status_code != 200:
            return False
        filepath.write_bytes(resp.content)
        try:
            img = PILImage.open(filepath)
            img.verify()
            return True
        except Exception:
            return False
    except Exception:
        return False


async def fetch_topic(client, query, prefix, max_imgs=2):
    print(f"  Buscando: {query}")
    title = await search_article(client, query)
    if not title:
        print("    Nao encontrado")
        return []
    print(f"    Artigo: {title}")
    page_images = await get_page_images(client, title, max_imgs=max_imgs * 5)
    if not page_images:
        print("    Sem imagens")
        return []
    print(f"    {len(page_images)} candidatas")
    result = []
    for img_info in page_images:
        if len(result) >= max_imgs:
            break
        filename = img_info["filename"]
        if filename.lower().endswith(".svg"):
            continue
        info = await get_image_url(client, filename)
        if not info or not info.get("url"):
            continue
        download_url = info.get("thumburl") or info["url"]
        ext = ".jpg"
        for e in IMAGE_EXTS:
            if e in info["url"].lower():
                ext = e
                break
        out_name = f"{prefix}_real{len(result)+1}{ext}"
        filepath = IMG_DIR / out_name
        ok = await download_image(client, download_url, filepath)
        if ok:
            size_kb = filepath.stat().st_size / 1024
            print(f"    OK: {out_name} ({size_kb:.0f} KB)")
            clean = filename.replace("Ficheiro:", "").replace("File:", "")
            clean = re.sub(r'\.(jpg|jpeg|png|gif|webp|svg)$', '', clean, flags=re.I)
            clean = clean.replace('_', ' ')[:100]
            result.append({
                "file": out_name, "caption": clean,
                "source": "Wikipédia (Português do Brasil)", "source_url": info["url"],
            })
    return result


TOPICS = [
    ("geo_fisica", "Estrutura interna da Terra", "geo_fisica"),
    ("geo_humana", "Urbanizacao", "geo_humana"),
    ("geo_maranhao", "Sao Luis Maranhao", "geo_ma"),
    ("geo_contemporaneos", "Desenvolvimento sustentavel", "geo_contemp"),
]


async def main():
    print("Baixando imagens reais da Wikipedia para Geografia...\n")
    all_results = {}
    async with httpx.AsyncClient(timeout=30, headers=HEADERS) as client:
        for pdf_key, query, prefix in TOPICS:
            imgs = await fetch_topic(client, query, prefix, max_imgs=2)
            all_results[pdf_key] = imgs
            print()
    meta_path = Path(__file__).resolve().parent / "geografia_real_images.py"
    with open(meta_path, "w", encoding="utf-8") as f:
        f.write("# -*- coding: utf-8 -*-\n")
        f.write("\"\"\"Imagens reais da Wikipédia (Português do Brasil) para Geografia.\"\"\"\n\n")
        f.write("REAL_IMAGES = {\n")
        for key, imgs in all_results.items():
            f.write(f'    "{key}": [\n')
            for img in imgs:
                cap = img["caption"].replace('"', "'")
                url = img["source_url"].replace('"', "'")
                f.write(f'        {{"file": "{img["file"]}", '
                        f'"caption": "{cap}", '
                        f'"source": "{img["source"]}", '
                        f'"source_url": "{url}"}},\n')
            f.write("    ],\n")
        f.write("}\n")
    print(f"Metadados: {meta_path}")
    total = sum(len(v) for v in all_results.values())
    print(f"Total: {total} imagens")


if __name__ == "__main__":
    asyncio.run(main())
