"""Baixa imagens da Wikipedia PT para o tópico de Membrana Plasmática e salva localmente."""

import asyncio
import os
import sys
import httpx
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from wiki_images import fetch_images_for_topic

OUT_DIR = Path(__file__).parent.parent / "data" / "materiais" / "imagens"
OUT_DIR.mkdir(parents=True, exist_ok=True)


async def download_image(url: str, filename: str) -> str | None:
    """Baixa imagem e salva localmente."""
    outpath = OUT_DIR / filename
    try:
        async with httpx.AsyncClient(
            timeout=30, follow_redirects=True,
            headers={"User-Agent": "PAESMedAI/1.0 (educational project; https://paesmedai.com)"}
        ) as client:
            resp = await client.get(url)
            if resp.status_code == 200 and resp.content:
                outpath.write_bytes(resp.content)
                print(f"  OK: {filename} ({len(resp.content)} bytes)")
                return str(outpath)
            print(f"  SKIP: {filename} (status {resp.status_code})")
            return None
    except Exception as e:
        print(f"  ERRO: {filename}: {e}")
        return None


async def main():
    print("Buscando imagens na Wikipedia PT para 'Membrana plasmática'...")
    data = await fetch_images_for_topic("Membrana plasmática", "Biologia", max_images=8)
    
    print(f"\nArtigo: {data.get('article_title')}")
    print(f"URL: {data.get('article_url')}")
    print(f"Resumo: {(data.get('summary') or '')[:200]}...")
    print(f"\nImagens encontradas: {len(data.get('images', []))}")
    
    downloaded = []
    for i, img in enumerate(data.get("images", [])):
        url = img.get("url") or img.get("thumb")
        if not url:
            continue
        ext = ".png"
        if ".jpg" in url.lower() or ".jpeg" in url.lower():
            ext = ".jpg"
        elif ".svg" in url.lower():
            ext = ".svg"
        elif ".gif" in url.lower():
            ext = ".gif"
        filename = f"membrana_plasmatica_{i+1}{ext}"
        path = await download_image(url, filename)
        if path:
            downloaded.append({
                "path": path,
                "caption": img.get("caption", ""),
                "source": img.get("source", "wikipedia-pt"),
                "url": url,
            })
    
    print(f"\n{len(downloaded)} imagens baixadas em {OUT_DIR}")
    
    # Também busca imagens de "Célula" para complementar
    print("\nBuscando imagens complementares de 'Célula'...")
    data2 = await fetch_images_for_topic("Célula", "Biologia", max_images=5)
    for i, img in enumerate(data2.get("images", [])):
        url = img.get("url") or img.get("thumb")
        if not url:
            continue
        ext = ".png"
        if ".jpg" in url.lower() or ".jpeg" in url.lower():
            ext = ".jpg"
        elif ".svg" in url.lower():
            ext = ".svg"
        filename = f"celula_geral_{i+1}{ext}"
        path = await download_image(url, filename)
        if path:
            downloaded.append({
                "path": path,
                "caption": img.get("caption", ""),
                "source": img.get("source", "wikipedia-pt"),
                "url": url,
            })
    
    print(f"\nTotal: {len(downloaded)} imagens baixadas")
    return downloaded


if __name__ == "__main__":
    result = asyncio.run(main())
