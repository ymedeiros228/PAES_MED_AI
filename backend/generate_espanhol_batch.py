# -*- coding: utf-8 -*-
"""Gera PDFs de Lingua Espanhola — topicos 7.1 a 7.3."""

from pdf_base import generate_educational_pdf

# ============================================================
# 7.1 Comprension de Textos
# ============================================================
COMPRENSION = {
    "titulo": "Comprensión de Textos",
    "disciplina": "Lingua Espanhola",
    "topico": "Comprension de Textos",
    "subtopico": "Generos, funciones del lenguaje y elementos de la comunicacion",
    "introducao": (
        "La comprension de textos en espanol exige identificar "
        "el genero, las funciones del lenguaje y los elementos "
        "de la comunicacion. La prova del PAES cobra "
        "principalmente interpretacion."
    ),
    "secoes": [
        {
            "titulo": "1. Generos textuales",
            "conteudo": (
                "GENEROS COMUNES EN LA PRUEBA:\n"
                "- Vineta y tira comica: humor, critica social.\n"
                "- Noticia: hecho real, estructura lead-cuerpo.\n"
                "- Publicidad y anuncio: persuadir, lenguaje "
                "atractivo.\n"
                "- Carta y correo electronico: comunicacion personal "
                "o formal.\n"
                "- Infografia: informacion visual con datos.\n"
                "- Blog y red social: opinion, informalidad.\n\n"
                "ESTRUCTURA DE LA NOTICIA:\n"
                "- Titular: llama la atencion.\n"
                "- Lead (entradilla): responde que, quien, cuando, "
                "donde, por que.\n"
                "- Cuerpo: desarrolla los detalles."
            ),
            "exemplo": (
                "Una vineta puede mostrar un medico hablando con "
                "un paciente y usar humor para criticar el sistema "
                "de salud. La prova puede preguntar cual es la "
                "intencion del autor: en este caso, criticar con "
                "humor. Identificar el genero (vineta) ayuda a "
                "esperar ese tipo de lectura."
            ),
        },
        {
            "titulo": "2. Funciones del lenguaje",
            "conteudo": (
                "FUNCIONES (segun Jakobson):\n"
                "- Referencial: informar, describir hechos.\n"
                "- Expresiva/emotiva: mostrar emociones del emisor.\n"
                "- Apelativa/conativa: influir en el receptor.\n"
                "- Fatica: probar el canal (¿me oyes?).\n"
                "- Metalinguistica: hablar sobre el lenguaje.\n"
                "- Poetica: cuidar la forma del mensaje.\n\n"
                "ELEMENTOS DE LA COMUNICACION:\n"
                "- Emisor: quien produce el mensaje.\n"
                "- Receptor: quien recibe.\n"
                "- Mensaje: contenido.\n"
                "- Codigo: sistema de signos.\n"
                "- Canal: medio de transmision.\n"
                "- Contexto: situacion."
            ),
            "exemplo": (
                "En un anuncio de medicamento, la funcion apelativa "
                "predomina: '¡Compre ahora!'. La funcion referencial "
                "aparece en la informacion sobre el producto. La "
                "funcion poetica puede estar en el eslogan. "
                "Identificar las funciones ayuda a entender la "
                "intencion del texto."
            ),
        },
        {
            "titulo": "3. Expresiones idiomaticas",
            "conteudo": (
                "EXPRESIONES IDIOMATICAS: frases con significado "
                "no literal, propias de la lengua.\n\n"
                "EJEMPLOS:\n"
                "- Estar en las nubes: estar distraido.\n"
                "- Tirar la toalla: rendirse.\n"
                "- Costar un rinon: ser muy caro.\n"
                "- Dar la cara: asumir responsabilidad.\n"
                "- No tener pelos en la lengua: ser directo.\n"
                "- Hacer la vista gorda: ignorar.\n\n"
                "REFRANES:\n"
                "- Mas vale prevenir que curar.\n"
                "- A mal tiempo, buena cara.\n"
                "- Quien no arriesga, no gana.\n\n"
                "FALSOS AMIGOS CON PORTUGUES:\n"
                "- embarazada = gravida (nao 'embaraçada')\n"
                "- exquisito = refinado (nao 'exquisito' no sentido negativo)\n"
                "- largo = extenso (nao 'largo' = wide)\n"
                "- suceso = acontecimento (nao 'sucesso' = exito)\n"
                "- vaso = recipiente (nao 'vaso' = flor)"
            ),
            "exemplo": (
                "Si un texto dice 'El tratamiento costara un rinon', "
                "no significa que el tratamiento cuesta un organo. "
                "La expresion 'costar un rinon' significa que es "
                "muy caro. Conocer expresiones idiomaticas evita "
                "interpretaciones literales equivocadas."
            ),
        },
    ],
    "resumo": (
        "- Generos: vineta, noticia, publicidad, carta, infografia, blog.\n"
        "- Noticia: titular, lead (5W), cuerpo.\n"
        "- Funciones: referencial, expresiva, apelativa, fatica, metalinguistica, poetica.\n"
        "- Elementos: emisor, receptor, mensaje, codigo, canal, contexto.\n"
        "- Expresiones idiomaticas y refranes: significado no literal.\n"
        "- Falsos amigos: embarazada, exquisito, largo, suceso, vaso."
    ),
    "dicas": [
        "Identifica el genero antes de leer: predice la estructura.",
        "En vinetas, observa imagenes y texto juntos.",
        "Las funciones del lenguaje se deducen por la intencion.",
        "Falsos amigos entre portugues y espanol son muy comunes en la prova.",
        "Refranes tienen sentido figurado: no traduzcas literalmente.",
        "El lead de una noticia responde las 5W: que, quien, cuando, donde, por que.",
    ],
    "pegadinhas": [
        "Confundir 'embarazada' (gravida) con 'embaracada'.",
        "Achar que 'suceso' es 'exito': es 'acontecimiento'.",
        "Traducir 'largo' como 'largo' (wide): es 'extenso'.",
        "Interpretar expresiones idiomaticas literalmente.",
        "Confundir funcion apelativa con referencial.",
        "Esquecer que la vineta combina imagen y texto.",
    ],
    "referencias": [
        "MARCUSCHI, L. A. Producao textual, analise de generos e compreensao. Sao Paulo: Parabola, 2008.",
        "JAKOBSON, R. Linguistica e comunicacao. Sao Paulo: Cultrix, 1969.",
        "MILANI, E. M. Gramatica de espanol para brasileiros. Sao Paulo: Saraiva, 2010.",
        "FANJUL, A. G. Espanol para brasileiros. Sao Paulo: Moderna, 2012.",
        "DICIONARIO Panhispanico de Dudas. Real Academia Espanola, 2005.",
        "MARTIN, V. L. Espanol: lengua y cultura. Sao Paulo: Scipione, 2011.",
    ],
}

IMG_COMPRENSION = [
    {"file": "esp_comprension.png", "caption": "Generos textuales en espanol", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 7.2 Aspectos Semanticos y Lexicales
# ============================================================
SEMANTICA_ESP = {
    "titulo": "Aspectos Semánticos y Lexicales",
    "disciplina": "Lingua Espanhola",
    "topico": "Aspectos Semanticos y Lexicales",
    "subtopico": "Sinonimia, antonimia, polisemia, homonimia, paronimia, denotacion y connotacion",
    "introducao": (
        "Los aspectos semanticos y lexicales estudian el "
        "significado de las palabras y sus relaciones. Son "
        "fundamentales para interpretar textos y evitar "
        "confusiones con el portugues."
    ),
    "secoes": [
        {
            "titulo": "1. Relaciones semanticas",
            "conteudo": (
                "SINONIMIA: palabras con significado igual o "
                "semejante. Ejemplo: medico/doctor; enfermo/"
                "enfermo.\n\n"
                "ANTONIMIA: palabras con significado opuesto. "
                "Ejemplo: sano/enfermo; vida/muerte.\n\n"
                "HOMONIMIA: palabras con la misma forma pero "
                "distinto significado y origen. Ejemplo: "
                "vaca (animal) / baca (portaequipajes).\n\n"
                "POLISEMIA: una palabra con varios significados "
                "relacionados. Ejemplo: cabeza (parte del cuerpo, "
                "jefe, inicio).\n\n"
                "PARONIMIA: palabras parecidas en la forma, pero "
                "con significados distintos. Ejemplo: "
                "absorber/adsorber; afecto/efecto."
            ),
            "exemplo": (
                "En un texto medico, 'efecto' (resultado) y "
                "'afecto' (emocion) son paronimos. Confundirlos "
                "altera el sentido: 'el efecto del medicamento' "
                "es el resultado, mientras que 'el afecto del "
                "medico' seria la emocion del profesional."
            ),
        },
        {
            "titulo": "2. Heterosemanticos, heterotonicos y heterogenéricos",
            "conteudo": (
                "HETEROSEMANTICOS: palabras que existen en "
                "portugues y espanol, pero con significados "
                "diferentes. Ejemplos:\n"
                "- barato (pt: barato/preco baixo) vs. barato "
                "(es: rented)\n"
                "- brinquedo (pt: juguete) vs. brinco (es: pendiente)\n"
                "- embutido (pt: carne procesada) vs. embutido "
                "(es: insertado)\n\n"
                "HETEROTONICOS: palabras con la misma raiz, pero "
                "con acentuacion diferente. Ejemplos:\n"
                "- musica (pt) / musica (es) - acento igual\n"
                "- lampara (es) / lampada (pt) - tono diferente\n\n"
                "HETEROGENERICOS: palabras con genero diferente "
                "entre las dos lenguas. Ejemplos:\n"
                "- el analisis (es, masc.) / a analise (pt, fem.)\n"
                "- el puente (es, masc.) / a ponte (pt, fem.)\n"
                "- la sangre (es, fem.) / o sangue (pt, masc.)"
            ),
            "exemplo": (
                "Un brasileño puede decir 'la analise' "
                "influenciado por el portugues, pero en espanol "
                "se dice 'el analisis'. Conocer los "
                "heterogenéricos evita errores de concordancia "
                "en la prova."
            ),
        },
        {
            "titulo": "3. Denotacion y connotacion",
            "conteudo": (
                "DENOTACION: significado literal, objetivo, "
                "del diccionario.\n\n"
                "CONNOTACION: significado figurado, subjetivo, "
                "asociativo.\n\n"
                "EJEMPLOS:\n"
                "- Corazon: denotacion = organo; connotacion = "
                "amor, valentia.\n"
                "- Luz: denotacion = radiacion luminosa; "
                "connotacion = esperanza, verdad.\n"
                "- Fuego: denotacion = combustion; connotacion = "
                "pasion, urgencia.\n\n"
                "USO EN LA PRUEBA: textos literarios y "
                "publicitarios usan connotacion; textos "
                "informativos y cientificos usan denotacion."
            ),
            "exemplo": (
                "En un poema, 'tiene un corazon de piedra' usa "
                "connotacion: la persona es fria, insensible. "
                "En un texto medico, 'el corazon late 70 veces "
                "por minuto' usa denotacion: el organo. El "
                "contexto define el sentido."
            ),
        },
    ],
    "resumo": (
        "- Sinonimia: significado igual. Antonimia: opuesto.\n"
        "- Homonimia: misma forma, distinto origen. Polisemia: varios significados relacionados.\n"
        "- Paronimia: palabras parecidas, significados distintos.\n"
        "- Heterosemanticos: misma palabra, significado diferente entre lenguas.\n"
        "- Heterogenéricos: genero diferente (el analisis / a analise).\n"
        "- Denotacion: literal. Connotacion: figurado."
    ),
    "dicas": [
        "Los heterosemanticos son los mayores enemigos del brasileño en espanol.",
        "Memoriza los principales heterogenéricos: analisis, puente, sangre, error.",
        "En textos literarios, busca connotaciones.",
        "Paronimos: cuidado con afecto/efecto, absorber/adsorber.",
        "Sinonimos perfectos son raros; suele haber matices.",
        "El contexto define si el sentido es denotativo o connotativo.",
    ],
    "pegadinhas": [
        "Confundir 'embarazada' (gravida) con 'embarazada' (portugues).",
        "Achar que 'barato' en espanol es 'preco baixo': es 'alquilado'.",
        "Usar el genero del portugues en espanol: 'la analisis' en vez de 'el analisis'.",
        "Interpretar expresiones connotativas como literales.",
        "Confundir paronimos: afecto/efecto, absorber/adsorber.",
        "Esquecer que la polisemia tiene significados relacionados, la homonimia no.",
    ],
    "referencias": [
        "MILANI, E. M. Gramatica de espanol para brasileiros. Sao Paulo: Saraiva, 2010.",
        "FANJUL, A. G. Espanol para brasileiros. Sao Paulo: Moderna, 2012.",
        "DICIONARIO Panhispanico de Dudas. Real Academia Espanola, 2005.",
        "MARTIN, V. L. Espanol: lengua y cultura. Sao Paulo: Scipione, 2011.",
        "GOMEZ, L. E. Espanol para brasileiros. Sao Paulo: Atica, 2009.",
        "SILVA, M. H. Falsos amigos en espanol. Sao Paulo: Saraiva, 2013.",
    ],
}

IMG_SEMANTICA_ESP = [
    {"file": "esp_semantica.png", "caption": "Relaciones semanticas en espanol", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 7.3 Gramatica
# ============================================================
GRAMATICA_ESP = {
    "titulo": "Gramática",
    "disciplina": "Lingua Espanhola",
    "topico": "Gramatica",
    "subtopico": "Articulos, adjetivos, pronombres, adverbios, verbos y conectores",
    "introducao": (
        "La gramatica del espanol tiene semejanzas y diferencias "
        "con el portugues. Conocer los puntos principales evita "
        "errores en la interpretacion y produccion de textos."
    ),
    "secoes": [
        {
            "titulo": "1. Articulos, adjetivos y pronombres",
            "conteudo": (
                "ARTICULOS:\n"
                "- Determinados: el, la, los, las.\n"
                "- Indeterminados: un, una, unos, unas.\n"
                "- Articulo neutro LO: no acompanha sustantivos. "
                "Se usa con adjetivos para formar abstractos: "
                "lo bueno, lo importante.\n\n"
                "ADJETIVOS:\n"
                "- Concordancia con el sustantivo en genero y "
                "numero.\n"
                "- Posicion: generalmente despues del sustantivo "
                "(el medico bueno).\n"
                "- Comparacion: mas... que, menos... que, "
                "tan... como. Superlativo: -isimo (altisimo).\n\n"
                "PRONOMBRES:\n"
                "- Personales: yo, tu, el, ella, nosotros, "
                "vosotros, ellos, ellas.\n"
                "- Posesivos: mi, tu, su, nuestro, vuestro, su.\n"
                "- Demostrativos: este, ese, aquel.\n"
                "- Relativos: que, quien, cuyo, donde.\n"
                "- Complemento: me, te, se, le, nos, os, les."
            ),
            "exemplo": (
                "El articulo neutro LO es una diferencia clave: "
                "'lo importante es la salud' no se refiere a un "
                "sustantivo, sino a la cualidad de importante. "
                "En portugues, se diria 'o importante e a saude'. "
                "El uso del LO es muy cobrado en provas."
            ),
        },
        {
            "titulo": "2. Verbos: modos y tiempos",
            "conteudo": (
                "MODOS VERBALES:\n"
                "- Indicativo: hechos reales. Presente, preterito "
                "perfecto, preterito indefinido, preterito "
                "imperfecto, futuro.\n"
                "- Subjuntivo: deseo, duda, hipotesis. Presente, "
                "imperfecto, perfecto.\n"
                "- Imperativo: orden o ruego.\n\n"
                "VERBOS REGULARES: -ar (hablar), -er (comer), "
                "-ir (vivir). Conjugacion predecible.\n\n"
                "VERBOS IRREGULARES: ser, estar, tener, ir, "
                "poder, hacer, decir, saber. Muy comunes.\n\n"
                "PERIFRASIS VERBALES:\n"
                "- Infinitivo: tener que + infinitivo, ir a + "
                "infinitivo.\n"
                "- Gerundio: estar + gerundio (accion en curso).\n\n"
                "DIFERENCA CON PORTUGUES: el subjuntivo es mas "
                "frecuente en espanol que en portugues."
            ),
            "exemplo": (
                "Espero que el paciente mejore. 'Mejore' esta en "
                "subjuntivo porque expresa deseo. En portugues, "
                "seria 'Espero que o paciente melhore'. La "
                "estructura es similar, pero el uso del subjuntivo "
                "es mas frecuente en espanol."
            ),
        },
        {
            "titulo": "3. Conectores y variacion linguistica",
            "conteudo": (
                "CONECTORES:\n"
                "- Adicion: y, ademas, tambien, aparte.\n"
                "- Contraste: pero, sin embargo, aunque, no "
                "obstante.\n"
                "- Causa: porque, ya que, debido a, puesto que.\n"
                "- Consecuencia: por lo tanto, asi que, entonces.\n"
                "- Condicion: si, con tal de que, siempre que.\n"
                "- Finalidad: para que, a fin de que.\n\n"
                "VARIACION LINGUISTICA:\n"
                "- Espanol peninsular (Espana): vosotros, distincion "
                "c/z, s.\n"
                "- Espanol americano: ustedes (sin vosotros), "
                "seseo (c/s/z suenan igual).\n"
                "- Espanol rioplatense: voseo (vos en vez de tu).\n\n"
                "EXPRESIONES REGIONALES: cada pais tiene sus "
                "modismos. La prova suele usar un espanol neutro."
            ),
            "exemplo": (
                "En Espana, 'vosotros sois medicos' es la forma "
                "informal de segunda persona del plural. En "
                "America, se usa 'ustedes son medicos' para "
                "ambas formas (formal e informal). La prova "
                "puede presentar textos de cualquier region."
            ),
        },
    ],
    "resumo": (
        "- Articulos: el/la/los/las, un/una/unos/unas, LO neutro.\n"
        "- Adjetivos: concordancia, comparacion (mas... que, -isimo).\n"
        "- Pronombres: personales, posesivos, demostrativos, relativos.\n"
        "- Modos: indicativo, subjuntivo, imperativo.\n"
        "- Perifrasis: tener que + infinitivo, estar + gerundio.\n"
        "- Conectores: adicion, contraste, causa, consecuencia, condicion.\n"
        "- Variacion: peninsular (vosotros), americano (ustedes), rioplatense (vos)."
    ),
    "dicas": [
        "El articulo LO neutro se usa con adjetivos: lo bueno, lo malo.",
        "El subjuntivo es muy frecuente en espanol: deseo, duda, orden.",
        "Adjetivos generalmente van despues del sustantivo.",
        "Seseo: en America, c/z/s suenan igual.",
        "Vosotros solo se usa en Espana; en America, ustedes.",
        "Conectores de condicion: si, con tal de que + subjuntivo.",
    ],
    "pegadinhas": [
        "Olvidar el articulo neutro LO: 'lo importante', no 'el importante'.",
        "Usar 'vosotros' en textos americanos: ahi se usa 'ustedes'.",
        "Confundir el subjuntivo con el indicativo en oraciones de deseo.",
        "Aplicar la concordancia del portugues al espanol.",
        "Esquecer que el adjetivo va despues del sustantivo en espanol.",
        "Confundir 'ser' y 'estar': ser = caracteristica; estar = estado.",
    ],
    "referencias": [
        "MILANI, E. M. Gramatica de espanol para brasileiros. Sao Paulo: Saraiva, 2010.",
        "FANJUL, A. G. Espanol para brasileiros. Sao Paulo: Moderna, 2012.",
        "DICIONARIO Panhispanico de Dudas. Real Academia Espanola, 2005.",
        "MARTIN, V. L. Espanol: lengua y cultura. Sao Paulo: Scipione, 2011.",
        "GOMEZ, L. E. Espanol para brasileiros. Sao Paulo: Atica, 2009.",
        "SILVA, M. H. Gramatica practica de espanol. Sao Paulo: Saraiva, 2014.",
    ],
}

IMG_GRAMATICA_ESP = [
    {"file": "esp_gramatica.png", "caption": "Modos verbales en espanol: indicativo, subjuntivo, imperativo", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (COMPRENSION, "ESP_COMPRENSION_TEXTOS.pdf", IMG_COMPRENSION, "Lingua Espanhola — Comprension de Textos"),
        (SEMANTICA_ESP, "ESP_SEMANTICA_LEXICO.pdf", IMG_SEMANTICA_ESP, "Lingua Espanhola — Aspectos Semanticos"),
        (GRAMATICA_ESP, "ESP_GRAMATICA.pdf", IMG_GRAMATICA_ESP, "Lingua Espanhola — Gramatica"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
