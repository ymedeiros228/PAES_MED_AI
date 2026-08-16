import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
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
  List<String> _ctaPaths = const [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _export() async {
    try {
      final data = await apiClient.post('/api/stats/bank-profile/export', {});
      final map = Map<String, dynamic>.from(data as Map);
      final path = map['path']?.toString() ?? '';
      var msg = 'Arquivo salvo${path.isNotEmpty ? ': $path' : ''}';
      if (path.isNotEmpty) {
        final sep = path.contains('\\') ? '\\' : '/';
        final i = path.lastIndexOf(sep);
        if (i > 0) {
          try {
            await apiClient.openPath(path.substring(0, i));
          } catch (e) {
            msg = '$msg · ${humanApiError(e, fallback: 'Pasta de export não abriu.')}';
          }
        }
      }
      setState(() => exportMsg = msg);
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
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Analisar',
                title: 'Banca',
                subtitle: 'Estimativa baseada no seu material',
                trailing: IconButton(
                  tooltip: 'Atualizar',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(refreshTickProvider.notifier).state++;
                  },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              profile.when(
                loading: () => const SkeletonList(count: 2, lines: 3),
                error: (e, _) => QuietEmpty(message: humanApiError(e, fallback: 'Perfil da banca indisponível.')),
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
                loading: () => const SkeletonList(count: 3, lines: 2),
                error: (e, _) => QuietEmpty(
                  message: humanApiError(e, fallback: 'Perfil da banca indisponível.'),
                  action: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ref.read(refreshTickProvider.notifier).state++;
                        },
                        child: const Text('Tentar'),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go('/sessao');
                        },
                        child: const Text('Sessão'),
                      ),
                    ],
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
                  _ctaPaths = [
                    for (final raw in ctas.take(6))
                      (Map<String, dynamic>.from(raw as Map)['path']?.toString() ?? '/sessao'),
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SurfacePanel(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: cs.primaryContainer.f35,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.insights_rounded,
                              size: 28,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    total != null ? '$total questões na análise' : 'Perfil local',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                  if (data['avgStatementLength'] != null || data['avgStatementLen'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Tamanho médio do enunciado: ${data['avgStatementLength'] ?? data['avgStatementLen']} chars',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: cs.onPrimaryContainer.withOpacity(0.85),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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
                            for (var i = 0; i < ctas.length && i < 6; i++)
                              Builder(
                                builder: (_) {
                                  final c = Map<String, dynamic>.from(ctas[i] as Map);
                                  return FilledButton.tonal(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      context.go(c['path']?.toString() ?? '/sessao');
                                    },
                                    child: Text('${i + 1}) ${c['label']?.toString() ?? 'Estudar'}'),
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: DataTable(
                              columnSpacing: 6,
                              horizontalMargin: 4,
                              headingRowHeight: 32,
                              dataRowMinHeight: 36,
                              dataRowMaxHeight: 36,
                              columns: [
                                DataColumn(
                                  label: Text(
                                    'Disc.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                                for (final y in yearList)
                                  DataColumn(
                                    label: Text(
                                      y,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                              ],
                              rows: [
                                for (final entry in heat.entries)
                                  DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          entry.key.toString().split(' ').first,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                      for (final y in yearList)
                                        DataCell(
                                          _HeatCell(
                                            value: Map<String, dynamic>.from(entry.value as Map)[y] as int? ?? 0,
                                            color: _heatColor(
                                              Map<String, dynamic>.from(entry.value as Map)[y] as int? ?? 0,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (co.isNotEmpty) ...[
                        SectionLabel('Tópicos que costumam aparecer juntos'),
                        StaggeredFadeIn(
                          itemDelay: const Duration(milliseconds: 60),
                          children: [
                            for (final raw in co.take(10))
                              PlaylistTile(
                                title: '${(raw as Map)['a']} ↔ ${raw['b']}',
                                subtitle: '${raw['count']} ocorrência(s)',
                                leadingIcon: Icons.link_rounded,
                                onPlay: () {
                                  HapticFeedback.selectionClick();
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
                        ),
                      ],
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text('Detalhes e export', style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        )),
                        children: [
                          if (data['difficultyDistribution'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Dificuldade: ${data['difficultyDistribution']}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: cs.onSurface.f72,
                                ),
                              ),
                            ),
                          if (data['correctAlternativeBias'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Viés de alternativa: ${data['correctAlternativeBias']}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: cs.onSurface.f72,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          if ((data['topVerbs'] as List? ?? []).isNotEmpty) ...[
                            Text('Verbos frequentes', style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                )),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final v in (data['topVerbs'] as List? ?? []).take(12))
                                  Chip(label: Text('${(v as List)[0]} (${v[1]})')),
                              ],
                            ),
                          ],
                          if ((data['topKeywords'] as List? ?? []).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('Palavras', style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                )),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final v in (data['topKeywords'] as List? ?? []).take(16))
                                  Chip(label: Text('${(v as List)[0]}')),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _export();
                            },
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Exportar perfil (E)'),
                          ),
                          if (exportMsg != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                exportMsg!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: cs.onSurface.f72,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              SectionLabel('Frequência no tempo'),
              freq.when(
                loading: () => const SkeletonList(count: 2, lines: 2),
                error: (e, _) => QuietEmpty(
                  message: humanApiError(e, fallback: 'Frequência indisponível.'),
                  action: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref.read(refreshTickProvider.notifier).state++;
                    },
                    child: const Text('Tentar'),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return QuietEmpty(
                      message: 'Sem série temporal ainda.',
                      action: TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go('/sessao');
                        },
                        child: const Text('Sessão'),
                      ),
                    );
                  }
                  return StaggeredFadeIn(
                    itemDelay: const Duration(milliseconds: 50),
                    children: [
                      for (final raw in items.take(24))
                        PlaylistTile(
                          title: '${(raw as Map)['subject']} · ${raw['topic']}',
                          subtitle:
                              'Anos: ${(raw['years'] as List? ?? []).join(', ')} · ${raw['frequency'] ?? '—'}x'
                              '${raw['forgotten'] == true ? ' · sumiu' : ''}'
                              '${raw['favorite'] == true ? ' · frequente' : ''}',
                          leadingIcon: Icons.timeline_rounded,
                          onPlay: () {
                            HapticFeedback.selectionClick();
                            context.go(
                              '/adaptativo?subject=${Uri.encodeComponent(raw['subject']?.toString() ?? '')}'
                              '&topic=${Uri.encodeComponent(raw['topic']?.toString() ?? '')}',
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
    if (n <= 0) return Theme.of(context).colorScheme.surfaceContainerHighest;
    if (n == 1) return AppTheme.warning.withOpacity(0.25);
    if (n == 2) return AppTheme.warning.withOpacity(0.55);
    return AppTheme.warning;
  }
}

/// Célula do heatmap com cantos arredondados e cor semântica.
class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.value, required this.color});
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isHot = value > 0;
    return Container(
      width: 34,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHot ? color.withOpacity(0.4) : cs.outlineVariant.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isHot
              ? (value >= 3 ? cs.onPrimary : cs.onSurface)
              : cs.onSurfaceVariant.f60,
        ),
      ),
    );
  }
}
