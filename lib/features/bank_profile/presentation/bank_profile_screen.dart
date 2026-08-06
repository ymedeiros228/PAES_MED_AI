import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/data/theory_reads.dart';
import '../../../core/widgets/training_basis_banner.dart';
import '../../../core/widgets/theory_topic_sheet.dart';
import '../../../core/widgets/ui_kit.dart';

class BankProfileScreen extends ConsumerStatefulWidget {
  const BankProfileScreen({super.key});

  @override
  ConsumerState<BankProfileScreen> createState() => _BankProfileScreenState();
}

class _BankProfileScreenState extends ConsumerState<BankProfileScreen> {
  String? exportMsg;
  Map<String, bool> theoryReadByKey = {};
  final Set<(String, String)> _readPairs = {};

  bool _isTheoryRead(String subject, String topic) =>
      theoryReadByKey[theoryReadKey(subject, topic)] == true;

  (String, String)? _parseCoKey(String raw) {
    final parts = raw.split('::');
    if (parts.isEmpty) return null;
    final sub = parts[0].trim();
    final top = parts.length >= 2 ? parts.sublist(1).join('::').trim() : '';
    if (sub.isEmpty || top.isEmpty) return null;
    return (sub, top);
  }

  Future<void> _addReads(Iterable<(String, String)> pairs) async {
    final before = _readPairs.length;
    for (final p in pairs) {
      if (p.$1.isNotEmpty && p.$2.isNotEmpty) _readPairs.add(p);
    }
    if (_readPairs.length == before) return;
    final out = await fetchTheoryReadMap(_readPairs);
    if (mounted) setState(() => theoryReadByKey = out);
  }

  Future<void> _openTheory(String subject, String topic) async {
    await TheoryTopicSheet.show(
      context,
      subject: subject,
      topic: topic,
      onMarkedRead: () {
        if (mounted) setState(() => theoryReadByKey[theoryReadKey(subject, topic)] = true);
      },
    );
  }

  void _onHeatCellTap(String subject, int count) {
    if (count <= 0 || subject.isEmpty) return;
    final freqItems = ref.read(frequencyProvider).valueOrNull ?? [];
    var topic = '';
    for (final raw in freqItems) {
      final m = Map<String, dynamic>.from(raw as Map);
      if (m['subject']?.toString() == subject) {
        topic = m['topic']?.toString() ?? '';
        break;
      }
    }
    if (topic.isNotEmpty) {
      _openTheory(subject, topic);
    } else {
      context.go(
        '/sessao?examBoard=UEMA_PAES&subject=${Uri.encodeComponent(subject)}',
      );
    }
  }

  Future<void> _export() async {
    try {
      final data = await apiClient.post('/api/stats/bank-profile/export', {});
      final map = Map<String, dynamic>.from(data as Map);
      final path = map['path']?.toString() ?? '';
      if (path.isNotEmpty) {
        final sep = path.contains('\\') ? '\\' : '/';
        final i = path.lastIndexOf(sep);
        if (i > 0) {
          try {
            await apiClient.post('/api/library/open-path', {'path': path.substring(0, i)});
          } catch (_) {}
        }
      }
      setState(() => exportMsg = 'Arquivo salvo${path.isNotEmpty ? ': $path' : ''}');
    } catch (e) {
      setState(() => exportMsg = humanApiError(e, fallback: 'Não deu para exportar o perfil de banca.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(bankProfileProvider);
    final freq = ref.watch(frequencyProvider);
    final cs = Theme.of(context).colorScheme;

    return ListView(
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Analisar',
                title: 'Banca',
                subtitle: 'O que a base local sugere — estimativa, não previsão oficial',
                trailing: IconButton(
                  tooltip: 'Atualizar',
                  onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              profile.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TrainingBasisBanner(
                    basis: data['basis']?.toString(),
                    message: data['disclaimer']?.toString() ?? data['message']?.toString(),
                    areaKey: 'banca',
                  ),
                ),
              ),
              profile.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => QuietEmpty(
                  message: 'Perfil da banca indisponível.',
                  action: TextButton(
                    onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                    child: const Text('Tentar'),
                  ),
                ),
                data: (data) {
                  final heat = Map<String, dynamic>.from(data['heatmap'] as Map? ?? {});
                  final years = <String>{};
                  for (final ymap in heat.values) {
                    years.addAll(Map<String, dynamic>.from(ymap as Map).keys);
                  }
                  final yearList = years.toList()..sort();
                  final co = (data['cooccurrence'] as List? ?? data['correlations'] as List? ?? []);
                  final total = data['totalQuestions'];
                  final ctas = data['studyCtas'] as List? ?? [];
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final pairs = <(String, String)>[];
                    for (final raw in co.take(10)) {
                      final m = Map<String, dynamic>.from(raw as Map);
                      final parsed = _parseCoKey(m['a']?.toString() ?? '');
                      if (parsed != null) pairs.add(parsed);
                    }
                    _addReads(pairs);
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SurfacePanel(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: cs.primaryContainer.withOpacity(0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              total != null ? '$total questões na análise' : 'Perfil local',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (data['avgStatementLength'] != null || data['avgStatementLen'] != null)
                              Text(
                                'Enunciado médio: ${data['avgStatementLength'] ?? data['avgStatementLen']} chars',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      if (ctas.isNotEmpty) ...[
                        SectionLabel('Estudar a partir da banca'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final raw in ctas.take(6))
                              Builder(
                                builder: (_) {
                                  final c = Map<String, dynamic>.from(raw as Map);
                                  return FilledButton.tonal(
                                    onPressed: () => context.go(c['path']?.toString() ?? '/sessao'),
                                    child: Text(c['label']?.toString() ?? 'Estudar'),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                      if (yearList.isNotEmpty) ...[
                        SectionLabel('Disciplina × ano', hint: 'toque na célula → teoria'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              const DataColumn(label: Text('Disc.')),
                              for (final y in yearList) DataColumn(label: Text(y)),
                            ],
                            rows: [
                              for (final entry in heat.entries)
                                DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        entry.key.toString().split(' ').first,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      onTap: () {
                                        final subj = entry.key.toString();
                                        final total = Map<String, dynamic>.from(entry.value as Map)
                                            .values
                                            .whereType<int>()
                                            .fold<int>(0, (a, b) => a + b);
                                        _onHeatCellTap(subj, total);
                                      },
                                    ),
                                    for (final y in yearList)
                                      DataCell(
                                        Builder(
                                          builder: (_) {
                                            final n = Map<String, dynamic>.from(entry.value as Map)[y] as int? ?? 0;
                                            return InkWell(
                                              onTap: n > 0
                                                  ? () => _onHeatCellTap(entry.key.toString(), n)
                                                  : null,
                                              child: Tooltip(
                                                message: n > 0
                                                    ? 'Teoria · ${entry.key} · $y'
                                                    : 'Sem questões',
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  color: _heatColor(n),
                                                  child: Text('$n'),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (co.isNotEmpty) ...[
                        SectionLabel('Tópicos que costumam aparecer juntos'),
                        for (final raw in co.take(10))
                          Builder(
                            builder: (_) {
                              final item = Map<String, dynamic>.from(raw as Map);
                              final parsed = _parseCoKey(item['a']?.toString() ?? '');
                              final sub = parsed?.$1 ?? '';
                              final top = parsed?.$2 ?? '';
                              return PlaylistTile(
                                title: '${item['a']} ↔ ${item['b']}',
                                subtitle: '${item['count']} ocorrência(s)',
                                badge: parsed != null && _isTheoryRead(sub, top) ? 'Li' : null,
                                leadingIcon: Icons.link_rounded,
                                onPlay: () {
                                  context.go(
                                    '/adaptativo?subject=${Uri.encodeComponent(sub)}'
                                    '&topic=${Uri.encodeComponent(top)}',
                                  );
                                },
                                secondary: sub.isNotEmpty && top.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Teoria local',
                                        icon: const Icon(Icons.menu_book_outlined),
                                        onPressed: () => _openTheory(sub, top),
                                      )
                                    : const SizedBox.shrink(),
                              );
                            },
                          ),
                      ],
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text('Detalhes e export', style: Theme.of(context).textTheme.titleSmall),
                        children: [
                          if (data['difficultyDistribution'] != null)
                            Text('Dificuldade: ${data['difficultyDistribution']}'),
                          if (data['correctAlternativeBias'] != null)
                            Text('Viés de alternativa: ${data['correctAlternativeBias']}'),
                          const SizedBox(height: 8),
                          Text('Verbos frequentes', style: Theme.of(context).textTheme.titleSmall),
                          Wrap(
                            spacing: 6,
                            children: [
                              for (final v in (data['topVerbs'] as List? ?? []).take(12))
                                Chip(label: Text('${(v as List)[0]} (${v[1]})')),
                            ],
                          ),
                          Text('Palavras', style: Theme.of(context).textTheme.titleSmall),
                          Wrap(
                            spacing: 6,
                            children: [
                              for (final v in (data['topKeywords'] as List? ?? []).take(16))
                                Chip(label: Text('${(v as List)[0]}')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _export,
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Exportar perfil (MD)'),
                          ),
                          if (exportMsg != null)
                            Text(exportMsg!, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  );
                },
              ),
              SectionLabel('Frequência no tempo'),
              freq.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => QuietEmpty(
                  message: 'Frequência indisponível.',
                  action: TextButton(
                    onPressed: () => ref.read(refreshTickProvider.notifier).state++,
                    child: const Text('Tentar'),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return QuietEmpty(
                      message: 'Sem série temporal ainda.',
                      action: TextButton(
                        onPressed: () => context.go('/sessao'),
                        child: const Text('Sessão'),
                      ),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final pairs = <(String, String)>[];
                    for (final raw in items.take(24)) {
                      final item = Map<String, dynamic>.from(raw as Map);
                      final s = item['subject']?.toString() ?? '';
                      final t = item['topic']?.toString() ?? '';
                      if (s.isNotEmpty && t.isNotEmpty) pairs.add((s, t));
                    }
                    _addReads(pairs);
                  });
                  return Column(
                    children: [
                      for (final raw in items.take(24))
                        Builder(
                          builder: (_) {
                            final item = Map<String, dynamic>.from(raw as Map);
                            final sub = item['subject']?.toString() ?? '';
                            final top = item['topic']?.toString() ?? '';
                            return PlaylistTile(
                              title: '$sub · $top',
                              subtitle:
                                  'Anos: ${(item['years'] as List? ?? []).join(', ')} · ${item['frequency'] ?? '—'}x'
                                  '${item['forgotten'] == true ? ' · sumiu' : ''}'
                                  '${item['favorite'] == true ? ' · frequente' : ''}',
                              badge: _isTheoryRead(sub, top)
                                  ? 'Li'
                                  : (item['forgotten'] == true
                                      ? 'sumiu'
                                      : (item['favorite'] == true ? 'frequente' : null)),
                              leadingIcon: Icons.timeline_rounded,
                              onPlay: () => context.go(
                                '/adaptativo?subject=${Uri.encodeComponent(sub)}'
                                '&topic=${Uri.encodeComponent(top)}',
                              ),
                              secondary: sub.isNotEmpty && top.isNotEmpty
                                  ? IconButton(
                                      tooltip: 'Teoria local',
                                      icon: const Icon(Icons.menu_book_outlined),
                                      onPressed: () => _openTheory(sub, top),
                                    )
                                  : null,
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _heatColor(int n) {
    if (n <= 0) return Colors.grey.shade200;
    if (n == 1) return Colors.orange.shade100;
    if (n == 2) return Colors.orange.shade300;
    return Colors.deepOrange.shade400;
  }
}
