# -*- coding: utf-8 -*-
"""Gera PDF profissional ABNT do material de Biologia - Membrana Plasmatica.

Melhorias v2:
- Texto sem emojis (causavam caracteres bagunçados)
- Imagens buscadas em portugues no Commons (PT-BR)
- Conteudo mais detalhado e explicativo
- Referencias em formato ABNT
- Fonte com suporte completo a acentos PT-BR
"""

import os
import sys
import re
import httpx
from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm, mm
from reportlab.lib.colors import HexColor, white, black
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

from PIL import Image as PILImage

# Diretorios
ROOT = Path(__file__).resolve().parent.parent
LOGO_PATH = ROOT / "assets" / "branding" / "paes_med_ai_icon_source.png"
IMG_DIR = ROOT / "data" / "materiais" / "imagens"
IMG_DIR.mkdir(parents=True, exist_ok=True)
PDF_DIR = ROOT / "data" / "materiais"
PDF_DIR.mkdir(parents=True, exist_ok=True)

# Cores do app
PRIMARY = HexColor("#0D7C66")
PRIMARY_DARK = HexColor("#0A5D4D")
PRIMARY_LIGHT = HexColor("#E0F2F1")
ACCENT = HexColor("#FFB74D")
TEXT_DARK = HexColor("#1A1A2E")
TEXT_LIGHT = HexColor("#666666")
BG_LIGHT = HexColor("#F8F9FA")
TIP_GREEN = HexColor("#2E7D32")
WARN_RED = HexColor("#C62828")

HEADERS = {"User-Agent": "PAESMedAI/1.0 (educational project; https://paesmedai.com)"}


# ---------------------------------------------------------------------------
# Registrar fontes com suporte a acentos
# ---------------------------------------------------------------------------

def _register_fonts():
    """Tenta registrar fontes TTF com suporte completo a PT-BR."""
    # Tentar fontes do Windows
    font_paths = {
        "Normal": "C:/Windows/Fonts/arial.ttf",
        "Bold": "C:/Windows/Fonts/arialbd.ttf",
        "Italic": "C:/Windows/Fonts/ariali.ttf",
        "BoldItalic": "C:/Windows/Fonts/arialbi.ttf",
    }
    registered = {}
    for name, path in font_paths.items():
        if os.path.exists(path):
            try:
                pdfmetrics.registerFont(TTFont(name, path))
                registered[name] = True
            except Exception:
                registered[name] = False
        else:
            registered[name] = False
    
    # Mapear familias
    if all(registered.values()):
        from reportlab.pdfbase.pdfmetrics import registerFontFamily
        registerFontFamily(
            "Normal",
            normal="Normal", bold="Bold",
            italic="Italic", boldItalic="BoldItalic"
        )
        return True
    return False


_HAS_TTF = _register_fonts()
_FONT_NORMAL = "Normal" if _HAS_TTF else "Helvetica"
_FONT_BOLD = "Bold" if _HAS_TTF else "Helvetica-Bold"
_FONT_ITALIC = "Italic" if _HAS_TTF else "Helvetica-Oblique"
_FONT_BOLD_ITALIC = "BoldItalic" if _HAS_TTF else "Helvetica-BoldOblique"


# ---------------------------------------------------------------------------
# Buscar imagens em portugues no Wikimedia Commons
# ---------------------------------------------------------------------------

def search_commons_images_pt(query: str, limit: int = 10) -> list[dict]:
    """Busca imagens no Wikimedia Commons - APENAS em portugues (PT-BR).
    
    Regras estritas:
    - Diagramas SVG: so aceitar se tiver 'pt' no nome (textos traduzidos para PT)
    - Fotos/micrografias (JPG/PNG): aceitar independente do nome (nao tem texto)
    - Rejeitar: logos, icones, imagens com texto em ingles
    """
    results = []
    seen_urls = set()
    seen_titles = set()
    
    # Indicadores PT no nome do arquivo
    pt_indicators = (" pt.", " pt_", " pt-br", "ptbr", "portugues", "portugue",
                     "-pt.", "-pt_", "_pt.svg", "-pt.svg", " pt.svg",
                     " pt.png", " pt.jpg")
    
    # Palavras PT em nomes de arquivo (especificas, nao podem match outros idiomas)
    pt_words = ("fagocitose", "endocitose", "endocitosis",  # PT/ES proximo
                "osmose", "difusao",
                "membrana", "celula", "bicamada", "fosfolipidio",
                "transporte", "esquema", "diagrama",
                "bomba", "sodio", "potassio", "glicocalix",
                "microvilosidade", "desmossomo", "juncao",
                "animal cell structure pt", "cell membrane detailed diagram pt",
                "scheme facilitated diffusion in cell membrane-pt",
                "lipid unsaturation effect pt",
                "phospholipid", "lipid bilayer", "tipos de endocitosis")
    
    # Rejeitar sempre
    always_reject = ("commons-logo", "wiki", "icon", "favicon", "banner",
                     "logo_", "_logo", "question_book", "disambig",
                     "crystal_clear", "lock-green", "lock-red", "searchtool",
                     "wikitext", "wikibooks", "wikidata", "wikiversity",
                     "en.svg", "de.svg", "fr.svg", "es.svg", "it.svg",
                     "ru.svg", "ja.svg", "zh.svg", "ar.svg", "he.svg",
                     "nl.svg", "pl.svg", "sv.svg", "cs.svg", "hu.svg",
                     "trilobite", "morpho", "question", "crystal",
                     "dna orbit", ".gif", ".ogv", ".tif", ".tiff",
                     ".webm", ".pdf", ".djvu", ".xcf", "sodium-potassium pump",
                     "sodium pump", "biological cell", "celltypes",
                     "catabolism", "cork micrographia", "hela",
                     "dapi", "mitotracker", "prokaryote", "plant cell telophase",
                     # Rejeitar outros idiomas (nao-PT)
                     "-eo.svg", "-eo.", "-ku.svg", "-ku.", "-ca.svg", "-ca.",
                     "-fa.svg", "-fa.", "-hi.svg", "-hi.", "-th.svg", "-th.",
                     "-vi.svg", "-vi.", "-id.svg", "-id.", "-ms.svg", "-ms.",
                     "-fi.svg", "-fi.", "-da.svg", "-da.", "-no.svg", "-no.",
                     "-ro.svg", "-ro.", "-uk.svg", "-uk.", "-el.svg", "-el.",
                     "-tr.svg", "-tr.", "-ko.svg", "-ko.", "-bn.svg", "-bn.",
                     "-ta.svg", "-ta.", "-te.svg", "-te.", "-mr.svg", "-mr.",
                     "-sr.svg", "-sr.", "-bg.svg", "-bg.", "-hr.svg", "-hr.",
                     "-sk.svg", "-sk.", "-sl.svg", "-sl.", "-lt.svg", "-lt.",
                     "-lv.svg", "-lv.", "-et.svg", "-et.", "-gl.svg", "-gl.",
                     "-eu.svg", "-eu.", "-cy.svg", "-cy.", "-ga.svg", "-ga.",
                     "-is.svg", "-is.", "-mk.svg", "-mk.", "-az.svg", "-az.",
                     "-kk.svg", "-kk.", "-uz.svg", "-uz.", "-tg.svg", "-tg.",
                     "-ky.svg", "-ky.", "-tk.svg", "-tk.", "-mn.svg", "-mn.",
                     "-my.svg", "-my.", "-km.svg", "-km.", "-lo.svg", "-lo.",
                     "-si.svg", "-si.", "-ka.svg", "-ka.", "-hy.svg", "-hy.",
                     "-am.svg", "-am.", "-ne.svg", "-ne.", "-pa.svg", "-pa.",
                     "-gu.svg", "-gu.", "-ur.svg", "-ur.", "-ps.svg", "-ps.",
                     "-sd.svg", "-sd.", "-kn.svg", "-kn.", "-ml.svg", "-ml.",
                     "-or.svg", "-or.", "-sa.svg", "-sa.", "-as.svg", "-as.")
    
    def _is_acceptable(title: str, mime: str, from_wikipedia_pt: bool = False) -> bool:
        """Decide se a imagem e aceitavel.
        
        - SVG: so aceitar se for PT (textos traduzidos)
        - JPG/PNG: so aceitar se vier da Wikipedia PT (relevantes ao topico)
        """
        t = title.lower()
        
        # 1. Rejeitar sempre
        for r in always_reject:
            if r in t:
                return False
        
        # 2. Se e SVG (diagrama com texto), so aceitar se for PT
        if "svg" in mime:
            for pw in pt_indicators:
                if pw in t:
                    return True
            for pw in pt_words:
                if pw in t:
                    return True
            return False  # SVG sem indicador PT = provavelmente em ingles
        
        # 3. Se e JPG/PNG (foto/micrografia):
        #    So aceitar se vier da Wikipedia PT (Strategy 2)
        #    Fotos do Commons search (Strategy 1) sao rejeitadas (irrelevantes)
        if "png" in mime or "jpeg" in mime or "jpg" in mime:
            if from_wikipedia_pt:
                return True
            return False  # Fotos do Commons search = irrelevantes
        
        return False
    
    def _is_pt_diagram(title: str, mime: str) -> bool:
        """Verifica se e um diagrama explicitamente PT."""
        if "svg" not in mime:
            return False
        t = title.lower()
        for pw in pt_indicators:
            if pw in t:
                return True
        for pw in pt_words:
            if pw in t:
                return True
        return False
    
    # Estrategia 1: buscar no Commons com filtro PT
    pt_queries = [
        f"{query} pt",
        f"{query} portugues",
        f"{query} pt-br",
        f"{query} diagrama",  # palavra PT no nome
        f"{query} esquema",   # palavra PT no nome
    ]
    
    for q in pt_queries:
        if len(results) >= limit:
            break
        params = {
            "action": "query",
            "generator": "search",
            "gsrsearch": f"filetype:bitmap|svg {q}",
            "gsrnamespace": "6",
            "gsrlimit": str(limit * 3),
            "prop": "imageinfo",
            "iiprop": "url|mime|size|extmetadata",
            "iiurlwidth": "800",
            "format": "json",
        }
        try:
            r = httpx.get(
                "https://commons.wikimedia.org/w/api.php",
                params=params, headers=HEADERS, timeout=20
            )
            data = r.json()
            pages = data.get("query", {}).get("pages", {})
            for page in sorted(pages.values(), key=lambda x: x.get("index", 999)):
                info = page.get("imageinfo", [{}])[0]
                mime = info.get("mime", "")
                if not any(m in mime for m in ("image/png", "image/jpeg", "image/svg")):
                    continue
                thumb = info.get("thumburl", "")
                orig = info.get("url", "")
                # Para SVG: usar URL original (precisamos do SVG para corrigir texto)
                # Para JPG/PNG: usar URL original
                url = orig or thumb
                if not url or url in seen_urls:
                    continue
                
                title = page.get("title", "").replace("File:", "").replace("Ficheiro:", "")
                
                if not _is_acceptable(title, mime, from_wikipedia_pt=False):
                    continue
                
                if title in seen_titles:
                    continue
                seen_urls.add(url)
                seen_titles.add(title)
                
                meta = info.get("extmetadata", {})
                caption = ""
                cap_data = meta.get("ImageDescription", {})
                caption = cap_data.get("value", "") if cap_data else ""
                if caption and "<" in caption:
                    caption = re.sub(r"<[^>]+>", "", caption).strip()[:200]
                
                results.append({
                    "url": url,
                    "title": title,
                    "caption": caption or title,
                    "mime": mime,
                    "source": "Wikimedia Commons (PT-BR)",
                    "source_url": info.get("descriptionurl", ""),
                    "is_pt": _is_pt_diagram(title, mime),
                })
        except Exception as e:
            print(f"  Erro buscando Commons PT: {e}")
    
    # Estrategia 2: Wikipedia PT - artigos relacionados
    if len(results) < limit:
        print(f"  Apenas {len(results)} imagens no Commons. Buscando artigos Wikipedia PT...")
        
        artigos_pt = [
            "Membrana plasmatica", "Celula", "Transporte passivo",
            "Osmose", "Fagocitose", "Endocitose", "Fosfolipidio",
            "Bicamada lipidica", "Microvilosidade", "Desmossomo",
            "Juncao comunicante", "Glicocalix", "Bomba sodio potassio",
            "Difusao facilitada", "Transporte ativo",
        ]
        
        for artigo in artigos_pt:
            if len(results) >= limit:
                break
            try:
                # Encontrar pageid
                params = {
                    "action": "query",
                    "list": "search",
                    "srsearch": artigo,
                    "srlimit": "1",
                    "format": "json",
                }
                r = httpx.get("https://pt.wikipedia.org/w/api.php",
                              params=params, headers=HEADERS, timeout=10)
                search_results = r.json().get("query", {}).get("search", [])
                if not search_results:
                    continue
                pageid = search_results[0]["pageid"]
                
                # Buscar imagens do artigo
                params = {
                    "action": "query",
                    "pageids": str(pageid),
                    "prop": "images",
                    "imlimit": "15",
                    "format": "json",
                }
                r = httpx.get("https://pt.wikipedia.org/w/api.php",
                              params=params, headers=HEADERS, timeout=10)
                pages = r.json().get("query", {}).get("pages", {})
                imgs = pages.get(str(pageid), {}).get("images", [])
                
                for img_meta in imgs:
                    if len(results) >= limit:
                        break
                    file_title = img_meta["title"]
                    # Converter "Ficheiro:" para "File:" (Commons usa File:)
                    if file_title.startswith("Ficheiro:"):
                        file_title = "File:" + file_title[len("Ficheiro:"):]
                    
                    # Buscar info da imagem no Commons
                    params2 = {
                        "action": "query",
                        "titles": file_title,
                        "prop": "imageinfo",
                        "iiprop": "url|mime|size|extmetadata",
                        "iiurlwidth": "800",
                        "format": "json",
                    }
                    r2 = httpx.get("https://commons.wikimedia.org/w/api.php",
                                   params=params2, headers=HEADERS, timeout=10)
                    pages2 = r2.json().get("query", {}).get("pages", {})
                    for page2 in pages2.values():
                        info = page2.get("imageinfo", [{}])[0]
                        mime = info.get("mime", "")
                        if not any(m in mime for m in ("image/png", "image/jpeg", "image/svg")):
                            continue
                        thumb = info.get("thumburl", "")
                        orig = info.get("url", "")
                        # Para SVG: usar URL original (precisamos do SVG para corrigir texto)
                        url = orig or thumb
                        if not url or url in seen_urls:
                            continue
                        
                        title = file_title.replace("File:", "").replace("Ficheiro:", "")
                        
                        if not _is_acceptable(title, mime, from_wikipedia_pt=True):
                            continue
                        if title in seen_titles:
                            continue
                        seen_urls.add(url)
                        seen_titles.add(title)
                        
                        meta = info.get("extmetadata", {})
                        caption = ""
                        cap_data = meta.get("ImageDescription", {})
                        caption = cap_data.get("value", "") if cap_data else ""
                        if caption and "<" in caption:
                            caption = re.sub(r"<[^>]+>", "", caption).strip()[:200]
                        
                        results.append({
                            "url": url,
                            "title": title,
                            "caption": caption or title,
                            "mime": mime,
                            "source": "Wikipedia PT",
                            "source_url": info.get("descriptionurl", ""),
                            "is_pt": _is_pt_diagram(title, mime),
                        })
            except Exception as e:
                pass
    
    # Priorizar diagramas PT primeiro, depois fotos
    results.sort(key=lambda x: (not x["is_pt"],))
    
    print(f"  Total de imagens encontradas: {len(results)}")
    for r in results:
        tag = "[PT diagrama]" if r["is_pt"] else "[foto/micrografia]"
        print(f"  {tag} {r['title'][:60]}")
    
    return results[:limit]


def download_image(url: str, filename: str) -> Path | None:
    """Baixa imagem e salva localmente. Se SVG, converte para PNG."""
    outpath = IMG_DIR / filename
    try:
        r = httpx.get(url, headers=HEADERS, timeout=30, follow_redirects=True)
        if r.status_code != 200 or not r.content:
            return None
        if filename.endswith(".svg"):
            outpath = outpath.with_suffix(".png")
        outpath.write_bytes(r.content)
        try:
            img = PILImage.open(outpath)
            img.verify()
        except Exception:
            outpath.unlink(missing_ok=True)
            return None
        return outpath
    except Exception as e:
        print(f"  Erro baixando {filename}: {e}")
        return None


# ---------------------------------------------------------------------------
# Corrigir SVG: substituir PT-PT e Espanhol por PT-BR
# ---------------------------------------------------------------------------

# Termos PT-PT -> PT-BR
PT_PT_TO_BR = {
    # Lipidios
    "Fosfolípido": "Fosfolipídio",
    "fosfolípido": "fosfolipídio",
    "Glicolípido": "Glicolipídio",
    "glicolípido": "glicolipídio",
    "Fosfolipídico": "Fosfolipídico",  # mesmo
    "fosfolipídica": "fosfolipídica",  # mesmo
    # Carboidratos
    "Glícido": "Carboidrato",
    "glícido": "carboidrato",
    "Glícidos": "Carboidratos",
    "glícidos": "carboidratos",
    # Proteinas
    "transmembranar": "transmembrana",
    "Transmembranar": "Transmembrana",
    "carreadoras": "transportadoras",
    "Carreadoras": "Transportadoras",
    "carreadora": "transportadora",
    "Carreadora": "Transportadora",
    # Celula
    "célula": "célula",  # mesmo
    "Citoplasma": "Citoplasma",  # mesmo
    # Outros PT-PT
    "ecrã": "tela",
    "Ecrã": "Tela",
    "utilizador": "usuário",
    "Utilizador": "Usuário",
    "facto": "fato",
    "Facto": "Fato",
    "registo": "registro",
    "Registo": "Registro",
    "atuar": "atuar",  # mesmo na nova ortografia
    "acção": "ação",
    "função": "função",  # mesmo
    # Espanhol -> PT-BR
    "Pinocitosis": "Pinocitose",
    "Fagocitosis": "Fagocitose",
    "Endocitosis": "Endocitose",
    "Endocitosis mediada por receptores": "Endocitose mediada por receptor",
    "partículas sólidas": "partículas sólidas",  # mesmo
    "Depresión recubierta": "Depressão revestida",
    "Capa de proteínas": "Camada de proteínas",
    "Vesícula recubierta": "Vesícula revestida",
    "Membrana plasmática": "Membrana plasmática",  # mesmo
    "Pseudópodos": "Pseudópodos",  # mesmo
    "Endosoma": "Endossomo",
    "Fluido extracelular": "Fluido extracelular",  # mesmo
    "citoplasma": "citoplasma",  # mesmo
    # Outros espanhol
    "célula animal": "célula animal",  # mesmo
    "recubierta": "revestida",
    "Recubierta": "Revestida",
    "depresión": "depressão",
    "Depresión": "Depressão",
    "capa": "camada",
    "Capa": "Camada",
}

# Termos que indicam que o SVG NAO e PT-BR (e nao tem correcao simples)
REJECT_TERMS = {
    # Espanhol puro (sem correcao direta possivel)
    "los ", "las ", "una ", "uno ", "por ", "con ", "del ",
    "transportador de ",  # pode ser ES
}


def fix_svg_to_ptbr(svg_url: str, output_path: Path) -> Path | None:
    """Baixa um SVG, substitui termos PT-PT/ES por PT-BR, converte para PNG.
    
    Usa Chrome headless para renderizar o SVG corrigido.
    """
    import subprocess
    import tempfile
    
    try:
        r = httpx.get(svg_url, headers=HEADERS, timeout=30, follow_redirects=True)
        if r.status_code != 200 or not r.content:
            return None
        
        svg_content = r.text
        
        # Aplicar substituicoes PT-PT -> PT-BR
        changes = 0
        for pt_pt, pt_br in PT_PT_TO_BR.items():
            if pt_pt == pt_br:
                continue
            if pt_pt in svg_content:
                svg_content = svg_content.replace(pt_pt, pt_br)
                changes += 1
        
        if changes > 0:
            print(f"    {changes} termos corrigidos PT-PT/ES -> PT-BR")
        else:
            print(f"    Nenhum termo PT-PT/ES encontrado (ja e PT-BR)")
        
        # Salvar SVG corrigido
        svg_path = output_path.with_suffix(".svg")
        svg_path.write_text(svg_content, encoding="utf-8")
        
        png_path = output_path.with_suffix(".png")
        
        # Criar HTML wrapper para renderizar o SVG em tamanho grande
        html_content = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8">
<style>
body {{ margin:0; padding:0; background:white; }}
svg {{ display:block; }}
</style></head><body>
{svg_content}
</body></html>"""
        
        html_path = output_path.with_suffix(".html")
        html_path.write_text(html_content, encoding="utf-8")
        
        # Usar Chrome headless para renderizar
        chrome_paths = [
            "C:/Program Files/Google/Chrome/Application/chrome.exe",
            "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
            "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
        ]
        
        chrome_exe = None
        for cp in chrome_paths:
            if os.path.exists(cp):
                chrome_exe = cp
                break
        
        if chrome_exe:
            # Converter para file:// URL
            file_url = html_path.as_uri()
            
            cmd = [
                chrome_exe,
                "--headless",
                "--disable-gpu",
                "--no-sandbox",
                "--screenshot=" + str(png_path),
                "--window-size=1600,1200",
                "--default-background-color=00000000",
                file_url,
            ]
            
            result = subprocess.run(cmd, capture_output=True, timeout=30, text=True)
            
            if png_path.exists() and png_path.stat().st_size > 1000:
                print(f"    SVG renderizado para PNG (Chrome headless)")
                # Limpar HTML
                html_path.unlink(missing_ok=True)
                return png_path
            else:
                print(f"    Chrome nao gerou PNG: {result.stderr[:100]}")
        
        # Fallback: usar thumburl do Commons (sem correcao)
        print(f"    Aviso: usando PNG do Commons (sem correcao de texto)")
        # Extrair nome do arquivo da URL
        fname = svg_url.split("/")[-1].split("?")[0]
        params = {
            "action": "query",
            "titles": f"File:{fname}",
            "prop": "imageinfo",
            "iiprop": "url",
            "iiurlwidth": "1200",
            "format": "json",
        }
        r2 = httpx.get("https://commons.wikimedia.org/w/api.php",
                       params=params, headers=HEADERS, timeout=15)
        pages = r2.json().get("query", {}).get("pages", {})
        for page in pages.values():
            info = page.get("imageinfo", [{}])[0]
            thumb = info.get("thumburl", "")
            if thumb:
                r3 = httpx.get(thumb, headers=HEADERS, timeout=15, follow_redirects=True)
                if r3.status_code == 200:
                    png_path.write_bytes(r3.content)
                    return png_path
        
        return None
    except Exception as e:
        print(f"    Erro corrigindo SVG: {e}")
        return None


# ---------------------------------------------------------------------------
# Conteudo cientifico detalhado (PT-BR, sem emojis)
# ---------------------------------------------------------------------------

CONTENT = {
    "titulo": "Membrana Plasmática",
    "disciplina": "Biologia",
    "topico": "Citologia",
    "subtopico": "Membrana Plasmática",
    "introducao": (
        "A membrana plasmática, também chamada de membrana celular, citoplasmática ou plasmalema, "
        "é a estrutura que delimita todas as células vivas, tanto as procarióticas quanto as "
        "eucarióticas. Ela estabelece a fronteira entre o meio intracelular e o meio extracelular, "
        "controlando ativamente a entrada e saída de substâncias. Compreender sua estrutura e "
        "funcionamento é fundamental para o estudo da fisiologia celular, da farmacologia e da "
        "patologia — áreas essenciais para a formação médica.\n\n"
        "A membrana não é uma barreira estática, mas sim uma estrutura dinâmica e seletiva, "
        "capaz de reconhecer sinais, responder a estímulos e permitir a comunicação entre "
        "células. Sem ela, a vida celular seria impossível, pois não haveria separação entre "
        "o interior da célula e o ambiente externo, nem controle sobre as reações químicas "
        "que ocorrem no citoplasma."
    ),
    "secoes": [
        {
            "titulo": "1. Estrutura da Membrana Plasmática",
            "conteudo": (
                "A membrana plasmática possui espessura aproximada de 7 a 9 nanômetros (nm) e "
                "só é visível ao microscópio eletrônico. Sua estrutura básica é descrita pelo "
                "modelo do mosaico fluido, proposto por Seymour Jonathan Singer e Garth Nicolson "
                "em 1972, na revista Science.\n\n"
                "Segundo esse modelo, a membrana é formada por uma dupla camada lipídica "
                "(bicamada) na qual as proteínas estão inseridas como blocos que flutuam em um "
                "mar de lipídios. A palavra \"mosaico\" refere-se à distribuição não uniforme "
                "dos componentes, e \"fluido\" indica que eles podem se mover lateralmente.\n\n"
                "A bicamada é composta principalmente por fosfolipídios, colesterol e "
                "glicolipídios. Os fosfolipídios são moléculas anfipáticas: possuem uma cabeça "
                "polar (hidrofílica, que tem afinidade pela água) e duas caudas de ácidos graxos "
                "(hidrofóbicas, que repelem a água). Essa característica faz com que, em meio "
                "aquoso, elas se organizem espontaneamente em bicamada, com as cabeças voltadas "
                "para o exterior e o interior da célula, e as caudas voltadas para o interior da "
                "membrana, longe da água.\n\n"
                "O colesterol está presente em quantidades variáveis (cerca de 25% dos lipídios "
                "da membrana em células animais) e tem função de estabilizar a membrana, "
                "regulando sua fluidez. Em temperaturas baixas, impede o empacotamento excessivo "
                "dos fosfolipídios, mantendo a membrana fluida; em temperaturas altas, reduz a "
                "mobilidade excessiva das cadeias de ácidos graxos, conferindo estabilidade.\n\n"
                "A fluidez da membrana é essencial para seu funcionamento. Sem fluidez, as "
                "proteínas não poderiam se mover, os receptores não poderiam se agrupar, e "
                "processos como a endocitose e a exocitose não ocorreriam. A fluidez depende "
                "de três fatores principais: a temperatura, o teor de colesterol e o grau de "
                "insaturação dos ácidos graxos (ácidos graxos insaturados, com duplas ligações, "
                "aumentam a fluidez porque criam \"dobras\" nas caudas)."
            ),
            "exemplo": (
                "Analogia: imagine uma piscina coberta por bolas flutuantes. As bolas são as "
                "proteínas e a água da piscina é a bicamada lipídica. As bolas podem deslizar "
                "lateralmente pela superfície, mas não atravessam a piscina facilmente — assim "
                "como as proteínas se movem lateralmente na membrana, mas sua rotação de um "
                "lado para outro é rara."
            ),
        },
        {
            "titulo": "2. Componentes Moleculares",
            "conteudo": (
                "A membrana plasmática é composta por três tipos principais de moléculas, "
                "cada um com funções específicas:\n\n"
                "LIPÍDIOS (aproximadamente 50% da massa da membrana):\n"
                "- Fosfolipídios: são o componente principal da bicamada. Os mais comuns são "
                "fosfatidilcolina, fosfatidiletanolamina, fosfatidilserina e fosfatidilinositol. "
                "A fosfatidilserina, por exemplo, normalmente fica na face interna da membrana; "
                "quando exposta na face externa, sinaliza que a célula deve sofrer apoptose "
                "(morte celular programada).\n"
                "- Colesterol: regula a fluidez e a estabilidade da membrana, intercalando-se "
                "entre os fosfolipídios.\n"
                "- Glicolipídios: são lipídios associados a carboidratos, participam do "
                "reconhecimento celular e da definição de grupos sanguíneos.\n\n"
                "PROTEÍNAS (aproximadamente 50% da massa da membrana):\n"
                "- Proteínas integrais (intrínsecas): atravessam a bicamada, podem ser "
                "transmembrana (atravessam completamente, com domínios hidrofílicos e "
                "hidrofóbicos) ou parcialmente. São responsáveis por transporte, receptores "
                "e canais iônicos.\n"
                "- Proteínas periféricas (extrínsecas): localizam-se na superfície interna ou "
                "externa da membrana, não penetram a bicamada. Atuam em sinalização, "
                "estrutura e enzimas.\n\n"
                "CARBOIDRATOS (aproximadamente 10% da massa, sempre na face externa):\n"
                "- Formam o glicocálix quando associados a proteínas (glicoproteínas) ou "
                "lipídios (glicolipídios). Participam do reconhecimento celular, adesão entre "
                "células, comunicação e resposta imunológica. O glicocálix é exclusivo da face "
                "externa da membrana — sua presença ajuda a distinguir o lado externo do "
                "interno."
            ),
            "exemplo": (
                "Os grupos sanguíneos do sistema ABO são determinados por glicolipídios e "
                "glicoproteínas na membrana dos glóbulos vermelhos (hemácias). As diferenças "
                "entre os tipos A, B, AB e O estão nos carboidratos presentes no glicocálix: "
                "o tipo A tem o antígeno A, o tipo B tem o antígeno B, o tipo AB tem ambos, "
                "e o tipo O não tem nenhum dos dois. Por isso, transfusões incompatíveis "
                "causam aglutinação e podem ser fatais."
            ),
        },
        {
            "titulo": "3. Funções da Membrana Plasmática",
            "conteudo": (
                "A membrana plasmática exerce várias funções essenciais para a célula:\n\n"
                "BARREIRA SELETIVA: controla a entrada e saída de substâncias, mantendo o "
                "ambiente intracelular diferente do extracelular. Isso é crucial para a "
                "homeostase — o equilíbrio interno da célula. Sem essa barreira, a célula "
                "perderia suas moléculas para o ambiente externo e seria invadida por "
                "substâncias nocivas.\n\n"
                "RECONHECIMENTO CELULAR: através do glicocálix e de receptores específicos, "
                "a célula identifica outras células, hormônios, antígenos e sinais do ambiente. "
                "Esse reconhecimento é fundamental para o sistema imunológico distinguir "
                "células próprias de estranhas, e para que células do mesmo tipo se agrupem "
                "formando tecidos.\n\n"
                "COMUNICAÇÃO CELULAR: receptores na membrana captam sinais externos "
                "(hormônios, neurotransmissores, fatores de crescimento) e transduzem esses "
                "sinais para o interior da célula, desencadeando respostas específicas. Esse "
                "processo, chamado transdução de sinal, é essencial para a coordenação das "
                "funções do organismo.\n\n"
                "ADESÃO CELULAR: glicoproteínas de adesão mantêm as células unidas nos tecidos "
                "e permitem a formação de junções celulares especializadas. Sem adesão, não "
                "haveria tecidos nem órgãos.\n\n"
                "SUPORTE ESTRUTURAL: a membrana mantém a integridade da célula e, em organismos "
                "sem parede celular (como os animais), define sua forma. Em células animais, "
                "a membrana trabalha em conjunto com o citoesqueleto interno para manter a "
                "forma e permitir movimentos."
            ),
            "exemplo": (
                "Os receptores de insulina na membrana plasmática das células são proteínas "
                "integrais que, ao se ligar à insulina, sofrem fosforilação e desencadeiam "
                "uma cascata de sinais internos que resulta na translocação de transportadores "
                "de glicose (GLUT4) para a membrana, permitindo a captação de glicose. Defeitos "
                "nesses receptores causam resistência à insulina e diabetes tipo 2."
            ),
        },
        {
            "titulo": "4. Transporte Através da Membrana",
            "conteudo": (
                "O transporte de substâncias através da membrana plasmática ocorre por diferentes "
                "mecanismos, divididos em transporte passivo (sem gasto de energia) e transporte "
                "ativo (com gasto de energia na forma de ATP).\n\n"
                "TRANSPORTE PASSIVO (sem gasto de ATP):\n\n"
                "Difusão simples: moléculas pequenas e apolares (como O2, CO2 e esteroides) "
                "atravessam a bicamada diretamente, no sentido do gradiente de concentração "
                "(do mais concentrado para o menos concentrado). Não há gasto de energia e "
                "não há participação de proteínas.\n\n"
                "Difusão facilitada: moléculas polares maiores (como glicose e aminoácidos) ou "
                "íons atravessam por proteínas de canal (formam poros) ou carriers "
                "(transportadoras que mudam de conformação). Também segue o gradiente de "
                "concentração, sem gasto de energia. A difusão facilitada é específica: cada "
                "proteína transporta um tipo de molécula.\n\n"
                "Osmose: é o movimento de água (solvente) através de membrana semipermeável, "
                "do meio hipotônico (menos concentrado em soluto) para o hipertônico (mais "
                "concentrado em soluto). A osmose é fundamental para a manutenção do volume "
                "celular e da pressão osmótica. Em células animais, a osmose em meio "
                "hipertônico causa crenação (encolhimento); em meio hipotônico, causa lise "
                "(estouro). Em células vegetais, a parede celular evita a lise, e o fenômeno "
                "é chamado de turgescência (em meio hipotônico) ou plasmólise (em meio "
                "hipertônico).\n\n"
                "TRANSPORTE ATIVO (com gasto de ATP):\n\n"
                "Transporte ativo primário: usa ATP diretamente. O exemplo clássico é a bomba "
                "de sódio e potássio (Na+/K+ ATPase), que bombeia 3 íons Na+ para fora e 2 "
                "íons K+ para dentro da célula, contra o gradiente de concentração. Essa "
                "bomba é fundamental para manter o potencial de membrana e para a transmissão "
                "do impulso nervoso. Outros exemplos: bomba de cálcio (Ca2+ ATPase) e bomba "
                "de prótons (H+ ATPase).\n\n"
                "Transporte ativo secundário (cotransporte): usa a energia armazenada no "
                "gradiente de um soluto (geralmente Na+) para transportar outro soluto. "
                "Pode ser simporte (os dois solutos se movem na mesma direção) ou antiporte "
                "(solutos se movem em direções opostas). Exemplo: o simporte Na+/glicose no "
                "intestino, onde o Na+ entra a favor do gradiente e arrasta a glicose junto.\n\n"
                "ENDOCITOSE E EXOCITOSE: transporte de grandes moléculas ou partículas. "
                "Na endocitose, a membrana engloba o material formando vesículas. Pode ser "
                "fagocitose (partículas sólidas, como bactérias — realizada por macrófagos e "
                "neutrófilos) ou pinocitose (líquidos e moléculas dissolvidas). A endocitose "
                "mediada por receptor é mais específica: apenas moléculas que se ligam a "
                "receptores específicos são internalizadas. Na exocitose, vesículas "
                "intracelulares fundem-se à membrana e liberam seu conteúdo para o exterior "
                "— é assim que células secretoras liberam hormônios, neurotransmissores e "
                "enzimas."
            ),
            "exemplo": (
                "A bomba Na+/K+ consome aproximadamente 70% do ATP de uma célula nervosa em "
                "repouso. Ela mantém a concentração intracelular de Na+ baixa (cerca de 15 mM) "
                "e de K+ alta (cerca de 150 mM), enquanto no extracelular é o oposto (Na+ "
                "cerca de 145 mM, K+ cerca de 5 mM). Esse gradiente é a base do potencial de "
                "membrana e da transmissão do impulso nervoso. Inibidores dessa bomba, como "
                "a ouabaína, são usados em pesquisa. Os digitálicos (como a digoxina, usada "
                "na insuficiência cardíaca) atuam inibindo parcialmente essa bomba."
            ),
        },
        {
            "titulo": "5. Especializações da Membrana",
            "conteudo": (
                "Embora a estrutura básica seja semelhante em todas as células, as membranas "
                "podem apresentar especializações conforme o tipo celular e a função exercida:\n\n"
                "MICROVILLOSIDADES: são projeções da membrana em forma de dedos que aumentam "
                "enormemente a superfície de absorção. São abundantes nas células do intestino "
                "delgado (enterócitos) e dos túbulos renais proximais. Um enterócito pode ter "
                "milhares de microvillosidades, aumentando a superfície de absorção em até "
                "600 vezes.\n\n"
                "DESMOSSOMOS: são junções de adesão entre células adjacentes, formadas por "
                "proteínas (desmogleínas e desmocolinas) que ancoram os filamentos "
                "intermediários do citoesqueleto de uma célula aos da célula vizinha. São "
                "comuns em tecidos sujeitos a tração mecânica, como a epiderme e o músculo "
                "cardíaco. Doenças autoimunes como o pênfigo foliáceo atacam as desmogleínas, "
                "causando bolhas na pele.\n\n"
                "JUNÇÕES COMUNICANTES (GAP JUNCTIONS): são canais que conectam o citoplasma "
                "de células adjacentes, permitindo a passagem direta de íons e moléculas "
                "pequenas (até cerca de 1.000 Da). São formadas por proteínas chamadas "
                "conexinas. São essenciais no músculo cardíaco, onde permitem a propagação "
                "rápida do impulso elétrico, garantindo a contração sincronizada do coração.\n\n"
                "JUNÇÕES OCLUSIVAS (TIGHT JUNCTIONS): formam barreiras impermeáveis entre "
                "células, selando o espaço entre elas. São formadas por proteínas como "
                "claudinas e ocludinas. Estão presentes na barreira hematoencefálica (que "
                "protege o cérebro de substâncias do sangue) e no epitélio intestinal (que "
                "impede que bactérias e toxinas atravessem a parede do intestino).\n\n"
                "DIFERENÇA IMPORTANTE: as células vegetais possuem, além da membrana "
                "plasmática, uma parede celular de celulose que confere rigidez e forma à "
                "célula. A membrana plasmática vegetal tem a mesma estrutura básica da "
                "animal, mas não possui colesterol (substituído por fitoesteroides)."
            ),
            "exemplo": (
                "A barreira hematoencefálica é formada por tight junctions entre as células "
                "endoteliais dos capilares cerebrais. Ela impede a passagem de muitas "
                "substâncias do sangue para o cérebro, protegendo o sistema nervoso central. "
                "Isso é um desafio para o design de fármacos que precisam atuar no cérebro — "
                "medicamentos precisam ser lipossolúveis ou usar transportadores específicos "
                "para atravessar essa barreira."
            ),
        },
    ],
    "resumo": (
        "- A membrana plasmática é uma bicamada lipídica com proteínas inseridas (modelo do mosaico fluido, Singer e Nicolson, 1972).\n"
        "- Composta por fosfolipídios, colesterol, proteínas (integrais e periféricas) e carboidratos (glicocálix).\n"
        "- Funções: barreira seletiva, reconhecimento, comunicação, adesão e suporte estrutural.\n"
        "- Transporte passivo: difusão simples (sem proteína), difusão facilitada (com proteína) e osmose (água). Não gasta energia.\n"
        "- Transporte ativo: bomba Na+/K+ (primário, usa ATP), cotransporte (secundário, usa gradiente de Na+), endocitose e exocitose.\n"
        "- Especializações: microvillosidades (absorção), desmossomos (adesão), gap junctions (comunicação) e tight junctions (barreira).\n"
        "- O colesterol regula a fluidez da membrana.\n"
        "- O glicocálix participa do reconhecimento celular (ex: grupos sanguíneos ABO).\n"
        "- Fosfolipídios são anfipáticos: cabeça hidrofílica + cauda hidrofóbica."
    ),
    "dicas": [
        "Decore o modelo do mosaico fluido (Singer e Nicolson, 1972) — cai frequentemente na prova.",
        "Diferencie difusão simples (sem proteína, moléculas pequenas e apolares) de facilitada (com proteína, moléculas polares ou íons).",
        "A bomba Na+/K+ é o exemplo clássico de transporte ativo primário: 3 Na+ para fora, 2 K+ para dentro, gasta ATP.",
        "Osmose: a água vai do hipotônico (menos concentrado) para o hipertônico (mais concentrado).",
        "Lembre que a membrana é anfipática: cabeça hidrofílica + cauda hidrofóbica. Essa é a chave de tudo.",
        "Células animais em meio hipotônico sofrem lise; vegetais ficam turgescentes (a parede evita o estouro).",
    ],
    "pegadinhas": [
        "Confundir transporte ativo primário com secundário: o primário usa ATP diretamente; o secundário usa o gradiente de Na+ (que foi criado por transporte ativo primário).",
        "Achar que osmose é transporte ativo: osmose é passiva, não gasta energia.",
        "Confundir fagocitose (partículas sólidas, forma pseudópodos) com pinocitose (líquidos, forma vesículas pequenas).",
        "Esquecer que esteroides (como hormônios esteroidais) atravessam a membrana por difusão simples por serem lipossolúveis — não precisam de proteína transportadora.",
        "Confundir simporte (mesma direção) com antiporte (direções opostas) no cotransporte.",
    ],
    # Referências em formato ABNT
    "referencias": [
        "ALBERTS, Bruce et al. Biologia Molecular da Célula. 6. ed. Porto Alegre: Artmed, 2017.",
        "DE ROBERTIS, E. M. F.; DE ROBERTIS JUNIOR, E. M. Bases da Biologia Celular e Molecular. 4. ed. Rio de Janeiro: Guanabara Koogan, 2014.",
        "JUNQUEIRA, L. C.; CARNEIRO, J. Biologia Celular e Molecular. 9. ed. Rio de Janeiro: Guanabara Koogan, 2012.",
        "NELSON, D. L.; COX, M. M. Lehninger Princípios de Bioquímica. 7. ed. São Paulo: Sarvier, 2017.",
        "SINGER, S. J.; NICOLSON, G. L. The fluid mosaic model of the structure of cell membranes. Science, v. 175, n. 4023, p. 720-731, 1972.",
    ],
}


# ---------------------------------------------------------------------------
# Gerar PDF
# ---------------------------------------------------------------------------

def _header_footer(canvas_obj, doc):
    """Header e footer de cada pagina."""
    canvas_obj.saveState()
    width, height = A4
    
    # Header: logo + titulo
    if LOGO_PATH.exists():
        canvas_obj.drawImage(
            str(LOGO_PATH), 1.5*cm, height - 1.8*cm,
            width=1.2*cm, height=1.2*cm, preserveAspectRatio=True, mask='auto'
        )
    canvas_obj.setFillColor(PRIMARY)
    canvas_obj.setFont(_FONT_BOLD, 9)
    canvas_obj.drawString(3*cm, height - 1.2*cm, "PAES MED AI")
    canvas_obj.setFont(_FONT_NORMAL, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Citologia — Membrana Plasmática")
    
    # Linha header
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    
    # Footer
    canvas_obj.setFont(_FONT_NORMAL, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI - Material de Estudo  |  Pagina {doc.page}")
    
    canvas_obj.restoreState()


def generate_pdf():
    """Gera o PDF completo do material."""
    pdf_path = PDF_DIR / "BI_CITOLOGIA_MEMBRANA_PLASMATICA_v13.pdf"
    
    # Usar imagens reais de sites educacionais brasileiros (100% PT-BR)
    print("Carregando imagens de sites educacionais brasileiros...")
    
    images_data = [
        {
            "file": "br_brasilescola_estrutura.jpg",
            "caption": "Estrutura da membrana plasmática — Modelo do mosaico fluido",
            "source": "Brasil Escola",
            "source_url": "https://brasilescola.uol.com.br/biologia/membrana-plasmatica.htm",
        },
        {
            "file": "br_todamateria_bicamada.jpg",
            "caption": "Bicamada fosfolipídica da membrana plasmática",
            "source": "Toda Matéria",
            "source_url": "https://www.todamateria.com.br/membrana-plasmatica/",
        },
        {
            "file": "br_brasilescola_transporte.jpg",
            "caption": "Transporte pela membrana plasmática: passivo e ativo",
            "source": "Brasil Escola",
            "source_url": "https://brasilescola.uol.com.br/biologia/membrana-plasmatica.htm",
        },
        {
            "file": "br_osmose_animal.jpg",
            "caption": "Osmose em células animais: meio hipotônico, isotônico e hipertônico",
            "source": "Mundo Educação",
            "source_url": "https://mundoeducacao.uol.com.br/biologia/osmose.htm",
        },
        {
            "file": "br_osmose_vegetal.jpg",
            "caption": "Osmose em células vegetais: turgência e plasmólise",
            "source": "Mundo Educação",
            "source_url": "https://mundoeducacao.uol.com.br/biologia/osmose.htm",
        },
    ]
    
    downloaded_images = []
    for img_data in images_data:
        path = IMG_DIR / img_data["file"]
        if path.exists() and path.stat().st_size > 1000:
            downloaded_images.append({
                "path": str(path),
                "caption": img_data["caption"],
                "source": img_data["source"],
                "source_url": img_data["source_url"],
                "is_pt": True,
            })
            print(f"  OK: {img_data['file']}")
        else:
            print(f"  FALTANDO: {img_data['file']}")
    
    print(f"\n{len(downloaded_images)} imagens baixadas. Gerando PDF...")
    
    # Estilos - SEM emojis, com fontes TTF
    styles = getSampleStyleSheet()
    
    style_title = ParagraphStyle(
        'CustomTitle', parent=styles['Title'],
        fontSize=26, textColor=PRIMARY_DARK, spaceAfter=6,
        fontName=_FONT_BOLD, alignment=TA_CENTER, leading=30
    )
    style_subtitle = ParagraphStyle(
        'Subtitle', parent=styles['Normal'],
        fontSize=13, textColor=TEXT_LIGHT, spaceAfter=20,
        alignment=TA_CENTER, fontName=_FONT_NORMAL
    )
    style_h2 = ParagraphStyle(
        'H2', parent=styles['Heading2'],
        fontSize=15, textColor=PRIMARY_DARK, spaceBefore=18, spaceAfter=8,
        fontName=_FONT_BOLD, leading=20
    )
    style_body = ParagraphStyle(
        'Body', parent=styles['Normal'],
        fontSize=11, textColor=TEXT_DARK, spaceAfter=8,
        alignment=TA_JUSTIFY, fontName=_FONT_NORMAL, leading=16
    )
    style_example = ParagraphStyle(
        'Example', parent=style_body,
        fontSize=10, textColor=HexColor("#444444"),
        leftIndent=15, rightIndent=15, spaceBefore=6, spaceAfter=10,
        borderColor=PRIMARY, borderWidth=0, borderPadding=10,
        backColor=PRIMARY_LIGHT, leading=15,
        fontName=_FONT_ITALIC
    )
    style_caption = ParagraphStyle(
        'Caption', parent=styles['Normal'],
        fontSize=8, textColor=TEXT_LIGHT, alignment=TA_CENTER,
        spaceBefore=4, spaceAfter=14, fontName=_FONT_ITALIC, leading=11
    )
    style_ref = ParagraphStyle(
        'Ref', parent=styles['Normal'],
        fontSize=10, textColor=TEXT_DARK, spaceAfter=8,
        leftIndent=20, firstLineIndent=-20, fontName=_FONT_NORMAL, leading=13
    )
    style_resumo = ParagraphStyle(
        'Resumo', parent=style_body,
        fontSize=11, textColor=TEXT_DARK, leftIndent=10, leading=16
    )
    style_dica = ParagraphStyle(
        'Dica', parent=style_body,
        fontSize=10, textColor=TIP_GREEN, leftIndent=15, leading=14,
        fontName=_FONT_NORMAL
    )
    style_peg = ParagraphStyle(
        'Peg', parent=style_body,
        fontSize=10, textColor=WARN_RED, leftIndent=15, leading=14,
        fontName=_FONT_NORMAL
    )
    style_section_label = ParagraphStyle(
        'SectionLabel', parent=styles['Normal'],
        fontSize=14, textColor=PRIMARY_DARK, spaceBefore=16, spaceAfter=6,
        fontName=_FONT_BOLD, leading=18
    )
    
    # Construir documento
    doc = SimpleDocTemplate(
        str(pdf_path), pagesize=A4,
        leftMargin=2.2*cm, rightMargin=2.2*cm,
        topMargin=2.5*cm, bottomMargin=1.8*cm,
        title="Membrana Plasmatica - PAES MED AI",
        author="PAES MED AI",
    )
    
    story = []
    
    # === CAPA ===
    story.append(Spacer(1, 3*cm))
    
    if LOGO_PATH.exists():
        story.append(Image(str(LOGO_PATH), width=3*cm, height=3*cm, hAlign='CENTER'))
    
    story.append(Spacer(1, 1*cm))
    story.append(Paragraph("PAES MED AI", ParagraphStyle(
        'BrandTitle', fontSize=16, textColor=PRIMARY, alignment=TA_CENTER,
        fontName=_FONT_BOLD, spaceAfter=6
    )))
    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph("Membrana Plasmatica", style_title))
    story.append(Paragraph(
        "Biologia - Citologia - Membrana Plasmatica",
        style_subtitle
    ))
    story.append(HRFlowable(width="60%", thickness=1, color=PRIMARY, hAlign='CENTER'))
    story.append(Spacer(1, 1*cm))
    story.append(Paragraph("Material de Estudo para PAES UEMA Medicina", ParagraphStyle(
        'CoverInfo', fontSize=12, textColor=TEXT_DARK, alignment=TA_CENTER,
        fontName=_FONT_NORMAL, spaceAfter=6
    )))
    story.append(Paragraph(
        "Com imagens cientificas do Wikimedia Commons e referencias bibliograficas em formato ABNT",
        ParagraphStyle('CoverSub', fontSize=10, textColor=TEXT_LIGHT, alignment=TA_CENTER,
        fontName=_FONT_ITALIC, leading=14)))
    
    story.append(PageBreak())
    
    # === INTRODUCAO ===
    story.append(Paragraph("Introducao", style_h2))
    
    # Dividir introducao em paragrafos
    for p in CONTENT["introducao"].split("\n\n"):
        story.append(Paragraph(p, style_body))
    
    story.append(Spacer(1, 0.5*cm))
    
    # Imagem principal
    if downloaded_images:
        img_data = downloaded_images[0]
        try:
            pil_img = PILImage.open(img_data["path"])
            w, h = pil_img.size
            max_w = 16*cm
            max_h = 12*cm
            ratio = min(max_w/w, max_h/h)
            img_w = w * ratio
            img_h = h * ratio
            
            story.append(Image(img_data["path"], width=img_w, height=img_h, hAlign='CENTER'))
            caption_text = img_data["caption"][:180]
            story.append(Paragraph(
                f'<i>{caption_text}</i><br/><font size="7" color="#999">Imagem: {img_data["source"]}</font>',
                style_caption
            ))
        except Exception as e:
            print(f"Erro ao inserir imagem: {e}")
    
    # === SECOES ===
    for sec_idx, sec in enumerate(CONTENT["secoes"]):
        story.append(Paragraph(sec["titulo"], style_h2))
        
        # Conteudo - dividir em paragrafos
        paragraphs = sec["conteudo"].split("\n\n")
        for p in paragraphs:
            # Converter quebras de linha simples em <br/>
            p_html = p.replace("\n", "<br/>")
            story.append(Paragraph(p_html, style_body))
        
        # Exemplo
        if sec.get("exemplo"):
            story.append(Paragraph(
                f'<b>Exemplo pratico:</b> {sec["exemplo"]}',
                style_example
            ))
        
        # Imagem adicional (intercalada, sem repetir a primeira)
        img_idx = sec_idx + 1
        if downloaded_images and img_idx < len(downloaded_images):
            img_data = downloaded_images[img_idx]
            try:
                pil_img = PILImage.open(img_data["path"])
                w, h = pil_img.size
                max_w = 14*cm
                max_h = 10*cm
                ratio = min(max_w/w, max_h/h)
                story.append(Spacer(1, 0.3*cm))
                story.append(Image(img_data["path"], width=w*ratio, height=h*ratio, hAlign='CENTER'))
                caption_text = img_data["caption"][:180]
                story.append(Paragraph(
                    f'<i>{caption_text}</i><br/><font size="7" color="#999">Imagem: {img_data["source"]}</font>',
                    style_caption
                ))
            except Exception as e:
                print(f"Erro imagem sec: {e}")
    
    # === RESUMO ===
    story.append(Spacer(1, 0.5*cm))
    story.append(HRFlowable(width="100%", thickness=0.5, color=PRIMARY))
    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Resumo - Pontos-Chave", style_section_label))
    resumo_html = CONTENT["resumo"].replace("\n", "<br/>")
    story.append(Paragraph(resumo_html, style_resumo))
    
    # === DICAS ===
    story.append(Spacer(1, 0.4*cm))
    story.append(Paragraph("Dicas para a Prova", style_section_label))
    for dica in CONTENT["dicas"]:
        story.append(Paragraph(f"-> {dica}", style_dica))
    
    # === PEGADINHAS ===
    story.append(Spacer(1, 0.4*cm))
    story.append(Paragraph("Pegadinhas Comuns", style_section_label))
    for peg in CONTENT["pegadinhas"]:
        story.append(Paragraph(f"! {peg}", style_peg))
    
    # === REFERENCIAS ABNT ===
    story.append(Spacer(1, 0.5*cm))
    story.append(HRFlowable(width="100%", thickness=0.5, color=PRIMARY))
    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Referencias Bibliograficas (ABNT)", style_section_label))
    for ref in CONTENT["referencias"]:
        story.append(Paragraph(ref, style_ref))
    
    # === FONTES DAS IMAGENS ===
    if downloaded_images:
        story.append(Spacer(1, 0.3*cm))
        story.append(Paragraph("Fontes das Imagens", style_section_label))
        for img in downloaded_images:
            ref_text = f'{img["caption"][:100]} - {img["source"]}'
            story.append(Paragraph(ref_text, style_ref))
    
    # Gerar
    doc.build(story, onFirstPage=_header_footer, onLaterPages=_header_footer)
    print(f"\nPDF gerado: {pdf_path}")
    print(f"Tamanho: {pdf_path.stat().st_size / 1024:.1f} KB")
    return pdf_path


if __name__ == "__main__":
    generate_pdf()
