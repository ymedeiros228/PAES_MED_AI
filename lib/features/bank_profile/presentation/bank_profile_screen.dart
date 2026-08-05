import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/training_basis_banner.dart';
import '../../../core/widgets/ui_kit.dart';

class BankProfileScreen extends ConsumerStatefulWidget {
  const BankProfileScreen({super.key});

  @override
  ConsumerState<BankProfileScreen> createState() => _BankProfileScreenState();
}

class _BankProfileScreenState extends ConsumerState<BankProfileScreen> {
  String? exportMsg;

  Future<void> _export() async {
    try {
      final data = await apiClient.post('/api/stats/bank-profile/export', {});
      final map = Map<String, dynamic>.from(data as Map);
      setState(() => exportMsg = 'Arquivo salvo${map['path'] != null ? ': ${map['path']}' : ''}');
    } catch (e) {
      setState(() => exportMsg = e.toString());
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
                        SectionLabel('Disciplina × ano'),
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
                                    ),
                                    for (final y in yearList)
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          color: _heatColor(
                                            Map<String, dynamic>.from(entry.value as Map)[y] as int? ?? 0,
                                          ),
                                          child: Text(
                                            '${Map<String, dynamic>.from(entry.value as Map)[y] ?? 0}',
                                          ),
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
                          PlaylistTile(
                            title: '${(raw as Map)['a']} ↔ ${raw['b']}',
                            subtitle: '${raw['count']} ocorrência(s)',
                            leadingIcon: Icons.link_rounded,
                            onPlay: () {
                              final a = raw['a']?.toString() ?? '';
                              final parts = a.split('::');
                              final sub = parts.isNotEmpty ? parts[0] : '';
                              final top = parts.length >= 2 ? parts.sublist(1).join('::') : '';
                              context.go(
                                '/adaptativo?subject=${Uri.encodeComponent(sub)}'
                                '&topic=${Uri.encodeComponent(top)}',
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
                error: (_, __) => const QuietEmpty(message: 'Frequência indisponível.'),
                data: (items) {
                  if (items.isEmpty) {
                    return const QuietEmpty(message: 'Sem série temporal ainda.');
                  }
                  return Column(
                    children: [
                      for (final raw in items.take(24))
                        PlaylistTile(
                          title: '${(raw as Map)['subject']} · ${raw['topic']}',
                          subtitle:
                              'Anos: ${(raw['years'] as List? ?? []).join(', ')} · ${raw['frequency'] ?? '—'}x'
                              '${raw['forgotten'] == true ? ' · sumiu' : ''}'
                              '${raw['favorite'] == true ? ' · frequente' : ''}',
                          leadingIcon: Icons.timeline_rounded,
                          onPlay: () => context.go(
                            '/adaptativo?subject=${Uri.encodeComponent(raw['subject']?.toString() ?? '')}'
                            '&topic=${Uri.encodeComponent(raw['topic']?.toString() ?? '')}',
                          ),
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
