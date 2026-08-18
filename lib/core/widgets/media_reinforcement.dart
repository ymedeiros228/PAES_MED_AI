import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_client.dart';
import '../data/api_error.dart';
import 'ui_kit.dart';

/// Reforço unificado vídeo + leitura (BG) — não é edital/banca UEMA.
class MediaReinforcement extends StatefulWidget {
  const MediaReinforcement({
    required this.subject,
    required this.topic,
    this.compact = false,
    this.heading = 'Reforço (vídeo · leitura)',
    super.key,
  });

  final String subject;
  final String topic;
  final bool compact;
  final String heading;

  @override
  State<MediaReinforcement> createState() => _MediaReinforcementState();
}

class _MediaReinforcementState extends State<MediaReinforcement> {
  int _reloadGen = 0;

  Future<Map<String, dynamic>> _loadBoth() async {
    final results = await Future.wait([
      apiClient.get('/api/media/videos', {'subject': widget.subject, 'topic': widget.topic}),
      apiClient.get('/api/media/articles', {'subject': widget.subject, 'topic': widget.topic}),
      apiClient.get('/api/media/reads', {'subject': widget.subject, 'topic': widget.topic}),
    ]);
    return {
      'videos': results[0] is Map ? Map<String, dynamic>.from(results[0] as Map) : <String, dynamic>{},
      'articles': results[1] is Map ? Map<String, dynamic>.from(results[1] as Map) : <String, dynamic>{},
      'reads': results[2] is Map ? Map<String, dynamic>.from(results[2] as Map) : <String, dynamic>{},
    };
  }

  Future<void> _open(
    BuildContext context, {
    required String url,
    required String kind,
    String? title,
  }) async {
    if (url.isEmpty) return;
    try {
      await apiClient.post('/api/media/open', {
        'url': url,
        'kind': kind,
        'subject': widget.subject,
        'topic': widget.topic,
        if (title != null && title.isNotEmpty) 'title': title,
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para abrir o material.'))),
      );
    }
  }

  Future<void> _markRead(
    BuildContext context, {
    required String url,
    String? title,
  }) async {
    if (url.isEmpty) return;
    try {
      await apiClient.post('/api/media/mark-read', {
        'url': url,
        'subject': widget.subject,
        'topic': widget.topic,
        if (title != null && title.isNotEmpty) 'title': title,
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marcado como lido (local · não banca).')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para marcar como lido.'))),
      );
    }
  }

  Set<String> _readUrls(Map<String, dynamic> readsMap) {
    final items = (readsMap['items'] as List? ?? []).whereType<Map>();
    return {
      for (final e in items)
        if ((e['url']?.toString() ?? '').isNotEmpty) e['url'].toString(),
    };
  }

  Future<void> _showMore(
    BuildContext context, {
    required String kind,
    required List<Map> items,
    required String? disclaimer,
    required Set<String> readUrls,
  }) async {
    final isVideo = kind == 'video';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isVideo ? 'Mais vídeos · ${widget.subject} · ${widget.topic}' : 'Mais leituras · ${widget.subject} · ${widget.topic}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.onSurface),
          ),
          if (disclaimer != null && disclaimer.isNotEmpty)
            SelectableText(disclaimer, style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurface)),
          for (final raw in items.take(5))
            ListTile(
              title: Text(raw['title']?.toString() ?? (isVideo ? 'Vídeo' : 'Leitura'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.onSurface)),
              subtitle: Text(
                [
                  raw['channel']?.toString() ?? raw['source']?.toString() ?? '',
                  if (readUrls.contains(raw['url']?.toString() ?? '')) 'li',
                ].where((s) => s.isNotEmpty).join(' · '),
                style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.72)),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isVideo)
                    IconButton(
                      tooltip: 'Marquei como lido',
                      icon: Icon(
                        readUrls.contains(raw['url']?.toString() ?? '')
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                      ),
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        await _markRead(
                          context,
                          url: raw['url']?.toString() ?? '',
                          title: raw['title']?.toString(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  const Icon(Icons.open_in_new_rounded),
                ],
              ),
              onTap: () async {
                HapticFeedback.selectionClick();
                final u = raw['url']?.toString() ?? '';
                if (u.isEmpty) return;
                await _open(
                  context,
                  url: u,
                  kind: kind,
                  title: raw['title']?.toString(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  Widget _lane({
    required BuildContext context,
    required String kind,
    required Map<String, dynamic> map,
    required Set<String> readUrls,
  }) {
    final items = (map['items'] as List? ?? []).whereType<Map>().toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final first = Map<String, dynamic>.from(items.first);
    final title = first['title']?.toString() ?? (kind == 'video' ? 'Vídeo' : 'Leitura');
    final url = first['url']?.toString() ?? '';
    final isVideo = kind == 'video';
    final isRead = readUrls.contains(url);
    final source = first['channel']?.toString() ?? first['source']?.toString() ?? '';
    final subtitle = [
      source,
      map['basis']?.toString() ?? 'local',
      if (isRead) 'li',
      'não é banca',
    ].where((s) => s.isNotEmpty).join(' · ');

    if (widget.compact) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: url.isEmpty
              ? null
              : () => _open(context, url: url, kind: kind, title: title),
          icon: Icon(isVideo ? Icons.ondemand_video_outlined : Icons.article_outlined),
          label: Text(
            isVideo
                ? 'Vídeo de reforço · $title (não é banca)'
                : 'Leitura de reforço · $title (não é banca)',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          isVideo ? 'Reforço em vídeo' : 'Leitura de reforço',
          hint: map['disclaimer']?.toString() ?? 'não é edital UEMA',
        ),
        PlaylistTile(
          title: isRead ? '✓ $title' : title,
          subtitle: subtitle,
          badge: isVideo ? 'vídeo' : 'leitura',
          leadingIcon: isVideo ? Icons.ondemand_video_outlined : Icons.article_outlined,
          onPlay: url.isEmpty
              ? null
              : () => _open(context, url: url, kind: kind, title: title),
          secondary: items.length > 1
              ? TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _showMore(
                    context,
                    kind: kind,
                    items: items,
                    disclaimer: map['disclaimer']?.toString(),
                    readUrls: readUrls,
                  );
                  },
                  child: const Text('Mais'),
                )
              : (!isVideo && url.isNotEmpty
                  ? TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _markRead(context, url: url, title: title);
                      },
                      child: Text(isRead ? 'Li' : 'Marquei como lido'),
                    )
                  : null),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subject.isEmpty || widget.topic.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(_reloadGen),
      future: _loadBoth(),
      builder: (context, snap) {
        if (snap.hasError) {
          return QuietEmpty(
            message: humanApiError(snap.error!, fallback: 'Reforço indisponível agora.'),
            action: TextButton(
              onPressed: () => setState(() => _reloadGen++),
              child: const Text('Tentar'),
            ),
          );
        }
        if (!snap.hasData) return const SizedBox.shrink();
        final data = snap.data!;
        final videos = data['videos'] as Map<String, dynamic>? ?? {};
        final articles = data['articles'] as Map<String, dynamic>? ?? {};
        final reads = data['reads'] as Map<String, dynamic>? ?? {};
        final vItems = (videos['items'] as List? ?? []);
        final aItems = (articles['items'] as List? ?? []);
        if (vItems.isEmpty && aItems.isEmpty) return const SizedBox.shrink();
        final readUrls = _readUrls(reads);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.compact)
              SectionLabel(
                widget.heading,
                hint: 'catálogo local · não é edital UEMA',
              ),
            _lane(context: context, kind: 'video', map: videos, readUrls: readUrls),
            _lane(context: context, kind: 'article', map: articles, readUrls: readUrls),
          ],
        );
      },
    );
  }
}
