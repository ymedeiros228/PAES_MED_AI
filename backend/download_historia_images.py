# -*- coding: utf-8 -*-
"""Baixa imagens reais da Wikipedia PT usando a API prop=images."""

from __future__ import annotations

import asyncio
import urllib.parse
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
    # Nao filtra por extensao aqui, vamos pegar todas e filtrar depois
    if any(bad in fn for bad in BAD_PATTERNS):
        return False
    # Preferir JPG/PNG (fotos, pinturas) sobre SVG (diagramas simples)
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
    except Exception as e:
        print(f"    Erro busca: {e}")
        return None


async def get_page_images(client: httpx.AsyncClient, title: str, max_imgs: int = 5) -> list[dict]:
    """Usa prop=images para listar imagens do artigo."""
    params = {
        "action": "query",
        "titles": title,
        "prop": "images",
        "imlimit": str(max_imgs * 3),
        "format": "json",
    }
    images = []
    try:
        resp = await client.get(
            "https://pt.wikipedia.org/w/api.php", params=params)
        resp.raise_for_status()
        data = resp.json()
        pages = data.get("query", {}).get("pages", {})
        for page_id, page_data in pages.items():
            imgs = page_data.get("images", [])
            for img_info in imgs:
                filename = img_info.get("title", "")
                if not is_useful(filename):
                    continue
                images.append({"filename": filename})
    except Exception as e:
        print(f"    Erro prop=images: {e}")
    return images[:max_imgs * 2]


async def get_image_url(client: httpx.AsyncClient, filename: str) -> dict | None:
    """Pega a URL real da imagem via imageinfo."""
    params = {
        "action": "query",
        "titles": filename,
        "prop": "imageinfo",
        "iiprop": "url|size|mime",
        "iiurlwidth": "800",
        "format": "json",
    }
    try:
        resp = await client.get(
            "https://pt.wikipedia.org/w/api.php", params=params)
        resp.raise_for_status()
        data = resp.json()
        pages = data.get("query", {}).get("pages", {})
        for page_id, page_data in pages.items():
            info_list = page_data.get("imageinfo", [])
            if info_list:
                info = info_list[0]
                return {
                    "url": info.get("url", ""),
                    "thumburl": info.get("thumburl", ""),
                    "mime": info.get("mime", ""),
                    "width": info.get("width", 0),
                    "height": info.get("height", 0),
                }
    except Exception as e:
        print(f"    Erro imageinfo: {e}")
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
            # SVG pode falhar no PIL.verify, mas ainda e valido
            if filepath.suffix.lower() == ".svg":
                return filepath.stat().st_size > 500
            return False
    except Exception:
        return False


async def fetch_topic(
    client: httpx.AsyncClient,
    query: str,
    prefix: str,
    max_imgs: int = 2,
) -> list[dict]:
    print(f"  Buscando: {query}")
    title = await search_article(client, query)
    if not title:
        print(f"    Nao encontrado")
        return []
    print(f"    Artigo: {title}")
    page_images = await get_page_images(client, title, max_imgs=max_imgs * 3)
    if not page_images:
        print(f"    Sem imagens no artigo")
        return []
    print(f"    {len(page_images)} imagens candidatas")

    result = []
    for img_info in page_images:
        if len(result) >= max_imgs:
            break
        filename = img_info["filename"]
        # Pula SVGs (geralmente diagramas simples)
        if filename.lower().endswith(".svg"):
            continue
        info = await get_image_url(client, filename)
        if not info or not info.get("url"):
            continue
        # Pega thumbnail se disponivel (menor download)
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
            # Legenda: nome do arquivo limpo
            clean_name = filename.replace("Ficheiro:", "").replace("File:", "")
            clean_name = re.sub(r'\.(jpg|jpeg|png|gif|webp|svg)$', '', clean_name, flags=re.I)
            clean_name = clean_name.replace('_', ' ')
            caption = clean_name[:100]
            result.append({
                "file": out_name,
                "caption": caption,
                "source": "Wikipedia PT",
                "source_url": info["url"],
            })
        else:
            print(f"    Falha: {out_name}")
    return result


# Termos de busca em portugues
TOPICS = [
    ("hist_mundo_antigo", "Antigo Egito", "hist_antigo"),
    ("hist_medieval", "Feudalismo", "hist_medieval_real"),
    ("hist_moderna", "Era dos Descobrimentos", "hist_moderna_real"),
    ("hist_contemporanea", "Revolucao Francesa", "hist_contemp_real"),
    ("hist_brasil_contemporaneo", "Era Vargas", "hist_brasil_real"),
    ("hist_maranhao", "Sao Luis Maranhao", "hist_ma_real"),
]


async def main():
    print("Baixando imagens reais da Wikipedia para Historia...\n")
    all_results = {}
    async with httpx.AsyncClient(timeout=30, headers=HEADERS) as client:
        for pdf_key, query, prefix in TOPICS:
            imgs = await fetch_topic(client, query, prefix, max_imgs=2)
            all_results[pdf_key] = imgs
            print()
    # Salva metadados
    meta_path = Path(__file__).resolve().parent / "historia_real_images.py"
    with open(meta_path, "w", encoding="utf-8") as f:
        f.write("# -*- coding: utf-8 -*-\n")
        f.write("\"\"\"Imagens reais da Wikipedia PT para Historia.\"\"\"\n\n")
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
    print(f"Metadados salvos: {meta_path}")
    total = sum(len(v) for v in all_results.values())
    print(f"Total: {total} imagens")


if __name__ == "__main__":
    asyncio.run(main())
