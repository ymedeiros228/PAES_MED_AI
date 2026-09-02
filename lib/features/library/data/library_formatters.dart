// Textos derivados de respostas do acervo (health lines, pacote Natureza, etc.).

String libraryHealthLine(Map<String, dynamic> map, {Object? inserted}) {
  final health = Map<String, dynamic>.from(map['yearHealth'] as Map? ?? {});
  if (health.isEmpty && map['years'] is List) {
    var bio = 0, qui = 0, fis = 0, total = 0;
    for (final raw in (map['years'] as List)) {
      final y = Map<String, dynamic>.from(raw as Map);
      final h = Map<String, dynamic>.from(y['yearHealth'] as Map? ?? {});
      final nat = Map<String, dynamic>.from(h['natureza'] as Map? ?? {});
      bio += (nat['Biologia'] as int?) ?? 0;
      qui += (nat['Química'] as int?) ?? 0;
      fis += (nat['Física'] as int?) ?? 0;
      total += (h['total'] as int?) ?? (y['inserted'] as int?) ?? 0;
    }
    if (total == 0 && inserted != null) total = int.tryParse('$inserted') ?? 0;
    return total > 0 ? ' · lote: $total questões · Bio $bio/Qui $qui/Fis $fis' : '';
  }
  final nat = Map<String, dynamic>.from(health['natureza'] as Map? ?? {});
  if (health.isEmpty) return '';
  return ' · lote: ${health['total'] ?? inserted ?? '—'} questões · gabarito ${health['gabaritoPct'] ?? '—'}%'
      ' · Bio ${nat['Biologia'] ?? 0}/Qui ${nat['Química'] ?? 0}/Fis ${nat['Física'] ?? 0}';
}

String librarySemana1HealthBody(Map<String, dynamic> map) {
  final buf = StringBuffer();
  buf.writeln(map['message']?.toString() ?? '');
  final years = map['years'] as List? ?? const [];
  for (final raw in years) {
    final y = Map<String, dynamic>.from(raw as Map);
    final h = Map<String, dynamic>.from(y['yearHealth'] as Map? ?? {});
    final nat = Map<String, dynamic>.from(h['natureza'] as Map? ?? {});
    buf.writeln(
      '· ${y['year']}: +${y['inserted'] ?? 0}'
      '${y['skipped'] == true ? ' (já commitado)' : ''}'
      '${h.isNotEmpty ? ' · Bio ${nat['Biologia'] ?? 0}/Qui ${nat['Química'] ?? 0}/Fis ${nat['Física'] ?? 0}' : ''}',
    );
  }
  buf.write(libraryNaturezaPackLine(
    map['naturezaPack'] is Map ? Map<String, dynamic>.from(map['naturezaPack'] as Map) : null,
  ));
  return buf.toString().trim();
}

String libraryNaturezaPackLine(Map<String, dynamic>? pack) {
  if (pack == null) return '';
  final n = pack['cardsCreated'] as int? ?? 0;
  final d = pack['drafts'] as int? ?? 0;
  if (n <= 0 && d <= 0) return '';
  return '\nPacote Natureza: $n cartões para revisar amanhã'
      '${d > 0 ? ' · $d com rascunho professor' : ''}.';
}
