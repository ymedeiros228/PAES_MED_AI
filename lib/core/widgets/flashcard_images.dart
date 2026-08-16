/// Mapeia assunto/matéria do flashcard para uma imagem de capa.
/// Retorna null se não houver imagem correspondente.
library;

/// Mapeia o nome da matéria para o prefixo das imagens.
String? _subjectToPrefix(String subject) {
  final s = subject.toLowerCase().trim();
  if (s.contains('biolog')) return 'bi';
  if (s.contains('química') || s.contains('quimica')) return 'qu';
  if (s.contains('física') || s.contains('fisica')) return 'fi';
  if (s.contains('matemá') || s.contains('matema')) return 'mt';
  if (s.contains('geograf')) return 'geo';
  if (s.contains('histó') || s.contains('histor')) return 'his';
  if (s.contains('portugu') || s.contains('língua portug') || s.contains('lingua portug')) return 'pt';
  if (s.contains('inglês') || s.contains('ingles') || s.contains('língua ingl') || s.contains('lingua ingl')) return 'ing';
  if (s.contains('espanhol')) return 'esp';
  if (s.contains('filosof')) return 'filo';
  if (s.contains('sociolog')) return 'soc';
  return null;
}

/// Mapeia o tópico para o sufixo da imagem (dentro do prefixo da matéria).
String? _topicToSuffix(String prefix, String topic) {
  final t = topic.toLowerCase().trim();
  final map = <String, Map<String, String>>{
    'bi': {
      'gené': 'bi_gene_capa.jpg',
      'gene': 'bi_gene_capa.jpg',
      'cito': 'bi_cito_capa.png',
      'celula': 'bi_cito_capa.png',
      'célula': 'bi_cito_capa.png',
      'botâ': 'bi_bota_capa.png',
      'bota': 'bi_bota_capa.png',
      'eco': 'bi_eco_capa.jpg',
      'embr': 'bi_embrio_capa.png',
      'evo': 'bi_evo_capa.png',
      'histo': 'bi_histo_capa.jpg',
      'intro': 'bi_intro_capa.jpg',
      'metab': 'bi_metab_capa.png',
      'micro': 'bi_micro_capa.jpg',
      'saú': 'bi_saude_capa.jpg',
      'sau': 'bi_saude_capa.jpg',
      'taxo': 'bi_taxo_capa.jpg',
      'zoo': 'bi_zoo_capa.jpg',
    },
    'qu': {
      'amb': 'qu_amb_capa.jpg',
      'átom': 'qu_atomo_capa.jpg',
      'atomo': 'qu_atomo_capa.jpg',
      'cál': 'qu_calc_capa.png',
      'cal': 'qu_calc_capa.png',
      'eletro': 'qu_eletro_capa.jpg',
      'equil': 'qu_equil_capa.png',
      'inorg': 'qu_inorg_capa.png',
      'liga': 'qu_ligacoes_capa.gif',
      'model': 'qu_modelos_capa.png',
      'org': 'qu_org_capa.png',
      'rea': 'qu_reacoes_capa.jpg',
      'solu': 'qu_soluc_capa.png',
      'tabel': 'qu_tabela_capa.jpg',
      'termo': 'qu_termo_capa.png',
    },
    'fi': {
      'cinem': 'fi_cinem_capa.gif',
      'dynam': 'fi_dinam_capa_v2.jpg',
      'dinam': 'fi_dinam_capa_v2.jpg',
      'eletrodin': 'fi_eletrodin_capa.jpg',
      'eletromag': 'fi_eletromag_capa.jpg',
      'eletrost': 'fi_eletrost_capa.png',
      'grand': 'fi_grand_capa.jpg',
      'grandez': 'fi_grand_capa.jpg',
      'hidro': 'fi_hidro_capa.png',
      'moderna': 'fi_moderna_capa.jpg',
      'onda': 'fi_onda_capa.gif',
      'ópt': 'fi_optica_capa.png',
      'opt': 'fi_optica_capa.png',
      'termo': 'fi_termo_capa_v2.png',
    },
    'mt': {
      'arit': 'mt_arit_capa.png',
      'comb': 'mt_comb_capa.png',
      'conj': 'mt_conj_capa.png',
      'func': 'mt_func_capa.png',
      'geoanal': 'mt_geoanal_capa.jpg',
      'geoesp': 'mt_geoesp_capa.gif',
      'geoplan': 'mt_geoplan_capa.jpg',
      'matriz': 'mt_matriz_capa.png',
      'stat': 'mt_stat_capa.gif',
      'trigo': 'mt_trigo_capa.jpg',
    },
    'geo': {
      'cont': 'geo_cont_capa.jpg',
      'fis': 'geo_fis_capa.jpg',
      'hum': 'geo_hum_capa.gif',
      'ma': 'geo_ma_capa_v2.jpg',
    },
    'his': {
      'antig': 'his_antigo_capa.png',
      'brasil': 'his_brasil_capa.jpg',
      'contemp': 'his_contemp_capa.jpg',
      'ma': 'his_ma_capa.jpg',
      'medieval': 'his_medieval_capa.png',
      'moderna': 'his_moderna_capa.jpg',
    },
    'pt': {
      'com': 'pt_com_capa.jpg',
      'lit': 'pt_lit_capa.jpg',
      'morfo': 'pt_morfo_capa.png',
      'obras': 'pt_obras_capa.png',
      'sem': 'pt_sem_capa.png',
      'sint': 'pt_sint_capa.jpg',
      'text': 'pt_text_capa.jpeg',
    },
    'ing': {
      'gram': 'ing_gram_capa_v2.png',
      'leit': 'ing_leit_capa.jpg',
      'lex': 'ing_lex_capa.png',
    },
    'esp': {
      'comp': 'esp_comp_capa.jpg',
      'gram': 'esp_gram_capa.jpg',
      'sem': 'esp_sem_capa_v2.jpg',
    },
    'filo': {
      'con': 'filo_con_capa.jpg',
      'cult': 'filo_cult_capa.png',
      'est': 'filo_est_capa.jpg',
      'et': 'filo_et_capa.jpg',
      'filos': 'filo_filos_capa.jpg',
      'log': 'filo_log_capa.jpg',
      'pol': 'filo_pol_capa.jpg',
    },
    'soc': {
      'class': 'soc_class_capa.jpg',
      'conc': 'soc_conc_capa.jpg',
      'cont': 'soc_cont_capa.jpg',
      'cult': 'soc_cult_capa.jpg',
      'est': 'soc_est_capa.jpg',
      'mud': 'soc_mud_capa.jpg',
      'surg': 'soc_surg_capa.jpg',
      'trab': 'soc_trab_capa.jpg',
      'viol': 'soc_viol_capa.jpg',
    },
  };
  final subjMap = map[prefix];
  if (subjMap == null) return null;
  for (final key in subjMap.keys) {
    if (t.contains(key)) return subjMap[key];
  }
  // Fallback: primeira imagem da matéria
  return subjMap.values.first;
}

/// Retorna o caminho do asset para a imagem do flashcard, ou null.
String? flashcardImageFor(String subject, String topic) {
  final prefix = _subjectToPrefix(subject);
  if (prefix == null) return null;
  final filename = _topicToSuffix(prefix, topic);
  if (filename == null) return null;
  return 'data/materiais/imagens/$filename';
}

/// Retorna uma cor de destaque para a matéria.
int subjectColorSeed(String subject) {
  final s = subject.toLowerCase().trim();
  if (s.contains('biolog')) return 0xFF2E7D32; // verde
  if (s.contains('química') || s.contains('quimica')) return 0xFFE65100; // laranja
  if (s.contains('física') || s.contains('fisica')) return 0xFF1565C0; // azul
  if (s.contains('matemá') || s.contains('matema')) return 0xFF6A1B9A; // roxo
  if (s.contains('geograf')) return 0xFF2E7D32; // verde
  if (s.contains('histó') || s.contains('histor')) return 0xFF8D6E63; // marrom
  if (s.contains('portugu')) return 0xFFC62828; // vermelho
  if (s.contains('inglês') || s.contains('ingles')) return 0xFF0277BD; // azul claro
  if (s.contains('espanhol')) return 0xFFF9A825; // amarelo
  if (s.contains('filosof')) return 0xFF455A64; // cinza escuro
  if (s.contains('sociolog')) return 0xFF5D4037; // marrom escuro
  return 0xFF424242; // cinza padrão
}
