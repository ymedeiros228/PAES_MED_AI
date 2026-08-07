import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/api_error.dart';
import 'ui_kit.dart';

/// Seletor de materiais: Banca local · Vídeos · Leituras · Buscar (pack unificado).
class StudyMaterialPack extends StatefulWidget {
  const StudyMaterialPack({
    required this.subject,
    required this.topic,
    this.compact = false,
    super.key,
  });

  final String subject;
  final String topic;
  final bool compact;

  @override
  State<StudyMaterialPack> createState() => _StudyMaterialPackState();
}

class _StudyMaterialPackState extends State<StudyMaterialPack> {
  int _gen = 0;
  String _lane = 'all';
  Future<Map<String, dynamic>>? _future;
  String? _futureKey;

  Future<Map<String, dynamic>> _load() async {
    final raw = await apiClient.get(
      '/api/study/materials-pack',
      {'subject': widget.subject, 'topic': widget.topic},
    );
    final map = Map<String, dynamic>.from(raw as Map);
    final pref = map['preferredLane']?.toString();
    final suggested = map['suggestedLane']?.toString();
    if (_lane == 'all') {
      if (pref != null && pref.isNotEmpty && pref != 'all') {
        _lane = pref;
      } else if (suggested != null && suggested.isNotEmpty && suggested != 'all') {
        _lane = suggested;
      }
    }
    return map;
  }

  Future<Map<String, dynamic>> _ensureFuture() {
    final key = '${widget.subject}::${widget.topic}::$_gen';
    if (_future == null || _futureKey != key) {
      _futureKey = key;
      _future = _load();
    }
    return _future!;
  }

  @override
  void didUpdateWidget(covariant StudyMaterialPack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subject != widget.subject || oldWidget.topic != widget.topic) {
      _gen++;
      _future = null;
      _futureKey = null;
      _lane = 'all';
    }
  }

  Future<void> _setPreferred(String id) async {
    setState(() => _lane = id);
    try {
      await apiClient.post('/api/media/prefs', {'preferredLane': id});
    } catch (_) {
      // preferência local na UI; API é bonus
    }
  }

  Future<void> _openMedia(
    BuildContext context, {
    required String url,
    String? kind,
    String? title,
  }) async {
    if (url.isEmpty) return;
    try {
      await apiClient.post('/api/media/open', {
        'url': url,
        'kind': kind ?? 'auto',
        'subject': widget.subject,
        'topic': widget.topic,
        if (title != null && title.isNotEmpty) 'title': title,
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não abriu o material.'))),
      );
    }
  }

  Future<void> _openPath(BuildContext context, Map item) async {
    final path = item['path']?.toString() ?? '';
    final folder = item['folder']?.toString() ?? 'edital';
    try {
      if (path.isNotEmpty) {
        await apiClient.post('/api/library/open-path', {'path': path});
        if (context.mounted) {
          showOpenPathSnackBar(context, message: 'Abrindo ${item['label'] ?? 'arquivo'}');
        }
        return;
      }
      await apiClient.post('/api/library/open-folder', {'folder': folder});
      if (context.mounted) {
        showOpenPathSnackBar(context, message: 'Pasta $folder');
      }
    } catch (e) {
      if (!context.mounted) return;
      showOpenPathSnackBar(
        context,
        message: humanOpenPathError(e, label: item['label']?.toString() ?? 'Material'),
        isError: true,
      );
    }
  }

  List<Map> _laneMaps(Map pack) {
    final lanes = (pack['lanes'] as List? ?? []).whereType<Map>().toList();
    if (_lane == 'all') return lanes;
    return lanes.where((l) => l['id']?.toString() == _lane).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subject.isEmpty || widget.topic.isEmpty) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(_gen),
      future: _ensureFuture(),
      builder: (context, snap) {
        if (snap.hasError) {
          return QuietEmpty(
            message: humanApiError(snap.error!, fallback: 'Materiais indisponíveis.'),
            action: TextButton(
              onPressed: () => setState(() {
                _gen++;
                _future = null;
                _futureKey = null;
              }),
              child: const Text('Tentar'),
            ),
          );
        }
        if (!snap.hasData) {
          return const SoftLoader(label: 'Carregando materiais…', compact: true);
        }
        final pack = snap.data!;
        final disclaimer = pack['disclaimer']?.toString();
        final lanes = (pack['lanes'] as List? ?? []).whereType<Map>().toList();
        final visible = _laneMaps(pack);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.compact)
              SectionLabel(
                'Materiais de estudo',
                hint: disclaimer ?? 'escolha o tipo · não inventamos banca',
              ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: _lane == 'all',
                  onTap: () => _setPreferred('all'),
                ),
                for (final raw in lanes)
                  _FilterChip(
                    label: () {
                      final id = raw['id']?.toString() ?? '';
                      final n = raw['count'];
                      final base = switch (id) {
                        'bank' => 'Banca',
                        'video' => 'Vídeos',
                        'article' => 'Leituras',
                        'search' => 'Buscar',
                        _ => raw['label']?.toString() ?? id,
                      };
                      return n == null ? base : '$base ($n)';
                    }(),
                    selected: _lane == raw['id']?.toString(),
                    onTap: () => _setPreferred(raw['id']?.toString() ?? 'all'),
                  ),
              ],
            ),
            Builder(
              builder: (_) {
                final actions = (pack['searchActions'] as List? ?? []).whereType<Map>();
                final yt = actions.cast<Map>().where(
                      (a) => (a['kind']?.toString() ?? '').startsWith('youtube'),
                    );
                if (yt.isEmpty) return const SizedBox.shrink();
                final first = Map<String, dynamic>.from(yt.first);
                final url = first['url']?.toString() ?? '';
                if (url.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton.icon(
                    onPressed: () => _openMedia(
                      context,
                      url: url,
                      kind: first['kind']?.toString() ?? 'youtube_search',
                      title: first['title']?.toString(),
                    ),
                    icon: const Icon(Icons.ondemand_video_rounded, size: 18),
                    label: Text(first['label']?.toString() ?? 'Abrir YouTube deste tópico'),
                  ),
                );
              },
            ),
            if (pack['youtubeConfigured'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'YouTube API ativa · vídeos da busca automática',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Vídeos: catálogo local + busca no YouTube (adicione YOUTUBE_API_KEY no .env para lista automática)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                      ),
                ),
              ),
            const SizedBox(height: 10),
            for (final lane in visible) ...[
              _LaneBlock(
                lane: Map<String, dynamic>.from(lane),
                compact: widget.compact,
                onOpenMedia: (url, kind, title) => _openMedia(
                  context,
                  url: url,
                  kind: kind,
                  title: title,
                ),
                onOpenBank: (item) => _openPath(context, item),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _LaneBlock extends StatelessWidget {
  const _LaneBlock({
    required this.lane,
    required this.compact,
    required this.onOpenMedia,
    required this.onOpenBank,
  });

  final Map<String, dynamic> lane;
  final bool compact;
  final void Function(String url, String? kind, String? title) onOpenMedia;
  final void Function(Map item) onOpenBank;

  @override
  Widget build(BuildContext context) {
    final id = lane['id']?.toString() ?? '';
    final label = lane['label']?.toString() ?? id;
    final hint = lane['hint']?.toString();
    final note = lane['note']?.toString();
    final disclaimer = lane['disclaimer']?.toString();
    final items = (lane['items'] as List? ?? []).whereType<Map>().toList();
    final searchActions = (lane['searchActions'] as List? ?? []).whereType<Map>().toList();

    if (items.isEmpty && searchActions.isEmpty) {
      if (note == null || note.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: QuietEmpty(message: note),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact)
            SectionLabel(label, hint: hint ?? disclaimer),
          if (compact)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          if (note != null && note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(note, style: Theme.of(context).textTheme.bodySmall),
            ),
          if (id == 'bank')
            for (final raw in items.take(8))
              Builder(
                builder: (_) {
                  final it = Map<String, dynamic>.from(raw);
                  final path = it['path']?.toString() ?? '';
                  final snip = it['snippet']?.toString() ?? '';
                  final kind = it['kind']?.toString() ?? 'local';
                  final isSnippet = kind == 'theory_snippet' || snip.isNotEmpty && path.isEmpty;
                  return PlaylistTile(
                    title: it['label']?.toString() ?? kind,
                    subtitle: snip.isNotEmpty
                        ? (snip.length > 120 ? '${snip.substring(0, 120)}…' : snip)
                        : (path.isNotEmpty ? path : kind),
                    badge: switch (kind) {
                      'theory_snippet' => 'teoria',
                      'edital_pdf' || 'edital_md' => 'edital',
                      'prova' => 'prova',
                      'estudo' => 'aula',
                      _ => 'local',
                    },
                    leadingIcon: isSnippet
                        ? Icons.menu_book_outlined
                        : Icons.folder_open_rounded,
                    onPlay: path.isNotEmpty || isSnippet
                        ? () {
                            if (path.isNotEmpty) {
                              onOpenBank(it);
                            } else if (snip.isNotEmpty) {
                              showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(it['label']?.toString() ?? 'Trecho'),
                                  content: SingleChildScrollView(child: Text(snip)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Fechar'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        : null,
                  );
                },
              )
          else ...[
            for (final raw in items.take(8))
              Builder(
                builder: (_) {
                  final it = Map<String, dynamic>.from(raw);
                  final url = it['url']?.toString() ?? '';
                  final title = it['title']?.toString() ?? it['label']?.toString() ?? 'Material';
                  final isSearch = (it['kind']?.toString() ?? '').contains('search') ||
                      (it['origin']?.toString() ?? '').contains('search');
                  final isVideo = id == 'video' ||
                      id == 'search' && (it['kind']?.toString() ?? '').startsWith('youtube');
                  return PlaylistTile(
                    title: title,
                    subtitle: [
                      it['channel']?.toString() ?? it['source']?.toString() ?? '',
                      if (isSearch) 'você escolhe',
                      'não banca',
                    ].where((s) => s.isNotEmpty).join(' · '),
                    badge: isSearch
                        ? 'busca'
                        : (isVideo ? 'vídeo' : 'leitura'),
                    leadingIcon: isSearch
                        ? Icons.search_rounded
                        : (isVideo
                            ? Icons.ondemand_video_outlined
                            : Icons.article_outlined),
                    onPlay: url.isEmpty
                        ? null
                        : () => onOpenMedia(
                              url,
                              it['kind']?.toString() ?? (isVideo ? 'video' : 'article'),
                              title,
                            ),
                  );
                },
              ),
            for (final raw in searchActions.take(3))
              Builder(
                builder: (_) {
                  final it = Map<String, dynamic>.from(raw);
                  final url = it['url']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: FilledButton.tonalIcon(
                      onPressed: url.isEmpty
                          ? null
                          : () => onOpenMedia(
                                url,
                                it['kind']?.toString() ?? 'youtube_search',
                                it['title']?.toString(),
                              ),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: Text(it['label']?.toString() ?? 'Buscar'),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
