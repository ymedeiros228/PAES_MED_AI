import 'api_client.dart';

/// Chave estável subject|topic para mapa de mark-read local.
String theoryReadKey(String subject, String topic) => '$subject|$topic';

/// Consulta `/api/study/reads/batch` e devolve mapa read por chave.
Future<Map<String, bool>> fetchTheoryReadMap(
  Iterable<(String subject, String topic)> pairs,
) async {
  final unique = <String, (String, String)>{};
  for (final p in pairs) {
    final s = p.$1.trim();
    final t = p.$2.trim();
    if (s.isEmpty || t.isEmpty) continue;
    unique[theoryReadKey(s, t)] = (s, t);
  }
  if (unique.isEmpty) return {};
  try {
    final data = await apiClient.post('/api/study/reads/batch', {
      'items': unique.values.map((p) => {'subject': p.$1, 'topic': p.$2}).toList(),
    });
    final map = Map<String, dynamic>.from(data as Map);
    final out = <String, bool>{};
    for (final raw in map['items'] as List? ?? const []) {
      final it = Map<String, dynamic>.from(raw as Map);
      final s = it['subject']?.toString() ?? '';
      final t = it['topic']?.toString() ?? '';
      if (s.isNotEmpty && t.isNotEmpty) {
        out[theoryReadKey(s, t)] = it['read'] == true;
      }
    }
    return out;
  } catch (_) {
    return {};
  }
}
