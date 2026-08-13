import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../core/widgets/ui_kit.dart';

/// Domínio: ranking para estudar. Ferramentas de curadoria ficam em Avançado.
class MedicineScreen extends ConsumerStatefulWidget {
  const MedicineScreen({super.key});

  @override
  ConsumerState<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends ConsumerState<MedicineScreen> {
  int selected = 0;
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _rankItems = const [];
  int _officialN = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _sessionPath(Map<String, dynamic> item, int officialN) {
    final s = item['subject']?.toString() ?? '';
    final t = item['topic']?.toString() ?? '';
    final nat = const {'Biologia', 'Química', 'Física'}.contains(s);
    final years = item['years'] as List? ?? const [];
    return '/sessao?examBoard=UEMA_PAES'
        '&subject=${Uri.encodeComponent(s)}'
        '&topic=${Uri.encodeComponent(t)}'
        '&preferNatureza=${nat ? '1' : '0'}'
        '${years.isNotEmpty ? '&year=${years.last}' : ''}'
        '${officialN >= 10 ? '&preferOfficial=1' : ''}';
  }

  void _openSelected(int officialN) {
    if (_rankItems.isEmpty) return;
    final idx = selected.clamp(0, _rankItems.length - 1);
    context.go(_sessionPath(_rankItems[idx], officialN));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event, int officialN) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyR || key == LogicalKeyboardKey.f5) {
      ref.read(refreshTickProvider.notifier).state++;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS && _rankItems.isNotEmpty) {
      _openSelected(officialN);
      return KeyEventResult.handled;
    }
    if (_rankItems.isEmpty) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyJ) {
      setState(() => selected = (selected + 1).clamp(0, _rankItems.length - 1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyK) {
      setState(() => selected = (selected - 1).clamp(0, _rankItems.length - 1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _openSelected(officialN);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(medicineProvider);
    final tick = ref.watch(refreshTickProvider);
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) => _onKey(node, event, _officialN),
      child: async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonList(count: 3, lines: 2),
      ),
      error: (e, _) => EmptyState(
        title: 'Domínio indisponível',
        subtitle: humanApiError(e, fallback: 'Tente de novo em instantes.'),
        action: Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            FilledButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                ref.read(refreshTickProvider.notifier).state++;
              },
              child: const Text('Tentar de novo'),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1');
              },
              child: const Text('Sessão'),
            ),
          ],
        ),
      ),
      data: (payload) {
        final items = (payload['items'] as List? ?? []);
        final basis = Map<String, dynamic>.from(payload['statsBasis'] as Map? ?? {});
        final curation = Map<String, dynamic>.from(payload['curation'] as Map? ?? {});
        final officialN = basis['officialCount'] as int? ?? 0;
        _officialN = officialN;
        _rankItems = [
          for (final raw in items.take(24)) Map<String, dynamic>.from(raw as Map),
        ];
        if (selected >= _rankItems.length && _rankItems.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => selected = _rankItems.length - 1);
          });
        }
        final realN = curation['realCount'] as int? ?? 0;
        final realPct = curation['realPercent'];
        final crossN = curation['crossDomainCount'] as int? ?? 0;
        final natN = curation['naturezaCount'] as int? ?? 0;
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
                    title: 'Domínio',
                    subtitle: items.isEmpty
                        ? 'Onde vale focar a seguir'
                        : '${items.length} assunto(s) por prioridade de estudo',
                  ),

                  if (officialN == 0)
                    QuietEmpty(
                      message: 'Sem provas oficiais ainda — ranking usa base de treino.',
                      action: TextButton(
                        onPressed: () => context.go('/biblioteca'),
                        child: const Text('Biblioteca'),
                      ),
                    )
                  else
                    SurfacePanel(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: cs.primaryContainer.withOpacity(0.4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Provas UEMA na base',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onPrimaryContainer),
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () => context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'),
                            child: const Text('Sessão Natureza'),
                          ),
                        ],
                      ),
                    ),

                  // Fila de revisão humana + labels sujos — Avançado (Z3 / BR)
                  SectionLabel(
                    'Prioridade',
                    hint: officialN >= 10
                        ? 'Sua pontuação de estudo (base oficial) — não é taxa de aprovação'
                        : 'Sua pontuação de estudo com base de treino — não é frequência na prova',
                  ),
                  if (items.isEmpty)
                    QuietEmpty(
                      message: 'Nada ranqueado ainda — faça uma sessão primeiro.',
                      action: TextButton(
                        onPressed: () => context.go('/sessao'),
                        child: const Text('Sessão'),
                      ),
                    )
                  else
                    StaggeredFadeIn(
                      itemDelay: const Duration(milliseconds: 70),
                      children: [
                        for (var i = 0; i < _rankItems.length; i++)
                          Builder(
                            builder: (context) {
                              final item = _rankItems[i];
                              final s = item['subject']?.toString() ?? '';
                              final t = item['topic']?.toString() ?? '';
                              final nat = const {'Biologia', 'Química', 'Física'}.contains(s);
                              final status = item['curationStatus']?.toString() ?? '';
                              final curated = item['curated'] == true;
                              final dirty = item['crossDomain'] == true || status == 'sujo';
                              String? badge;
                              if (dirty) {
                                badge = 'interdisciplinar';
                              } else if (curated) {
                                badge = 'confirmado';
                              } else if (status == 'natureza' || nat) {
                                badge = 'a revisar';
                              }
                              final nOff = item['frequency'] ?? item['realInTopic'] ?? item['n'];
                              final years = item['years'] as List? ?? const [];
                              final yearHint = years.isNotEmpty
                                  ? ' · anos ${years.take(3).join(', ')}'
                                  : '';
                              final countHint = nOff != null
                                  ? ' · $nOff na base'
                                  : '';
                              final sessao = _sessionPath(item, officialN);
                              return PlaylistTile(
                                title: s,
                                subtitle: '$t$countHint$yearHint',
                                badge: badge,
                                active: i == selected,
                                leadingIcon: Icons.play_circle_outline_rounded,
                                onPlay: () {
                                  setState(() => selected = i);
                                  context.go(sessao);
                                },
                              );
                            },
                          ),
                      ],
                    ),

                  const SizedBox(height: 16),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Avançado',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: const Text('Rascunhos, assuntos duvidosos, inventário e curadoria'),
                    children: [
                      FutureBuilder(
                        key: ValueKey('drafts-$tick'),
                        future: apiClient.get('/api/professor/draft-queue?limit=5'),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const CompactStatus(
                              message: 'Carregando rascunhos para revisar…',
                              icon: Icons.hourglass_empty_rounded,
                            );
                          }
                          if (snap.hasError || snap.data is! Map) {
                            return const CompactStatus(
                              message: 'Rascunhos indisponíveis no momento.',
                              icon: Icons.sync_problem_outlined,
                            );
                          }
                          final q = Map<String, dynamic>.from(snap.data as Map);
                          final draftItems = q['items'] as List? ?? const [];
                          final n = q['count'] as int? ?? draftItems.length;
                          if (n == 0) {
                            return const CompactStatus(
                              message: 'Nenhum rascunho para revisar.',
                              icon: Icons.inbox_outlined,
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionLabel(
                                'Para revisar hoje',
                                hint: '$n rascunho(s) Natureza — Aceitar grava como revisão ok (não é texto da banca)',
                              ),
                              for (final raw in draftItems.take(5))
                                Builder(
                                  builder: (context) {
                                    final it = Map<String, dynamic>.from(raw as Map);
                                    final id = it['questionId']?.toString() ?? '';
                                    final ql = it['studentLabel']?.toString() ??
                                        it['resolutionQuality']?.toString() ??
                                        'rascunho';
                                    return PlaylistTile(
                                      title: '${it['subject']}',
                                      subtitle: '${it['topic']}',
                                      badge: ql == 'template' ? 'modelo' : 'rascunho',
                                      leadingIcon: Icons.edit_note_rounded,
                                      onPlay: () {
                                        HapticFeedback.selectionClick();
                                        context.go('/questoes/$id');
                                      },
                                      secondary: TextButton(
                                        onPressed: () async {
                                          HapticFeedback.mediumImpact();
                                          try {
                                            await apiClient.post(
                                              '/api/professor/draft-accept',
                                              {'questionId': id},
                                            );
                                            ref.read(refreshTickProvider.notifier).state++;
                                            ref.invalidate(medicineProvider);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    humanApiError(
                                                      e,
                                                      fallback: 'Não deu para aceitar o rascunho.',
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: const Text('Ok'),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
                      FutureBuilder(
                        key: ValueKey('dirty-$tick'),
                        future: apiClient.get('/api/curation/dirty-labels?limit=8'),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const CompactStatus(
                              message: 'Carregando assuntos para revisar…',
                              icon: Icons.hourglass_empty_rounded,
                            );
                          }
                          if (snap.hasError || snap.data is! Map) {
                            return const CompactStatus(
                              message: 'Assuntos suspeitos indisponíveis no momento.',
                              icon: Icons.sync_problem_outlined,
                            );
                          }
                          final d = Map<String, dynamic>.from(snap.data as Map);
                          final n = d['count'] as int? ?? 0;
                          final dirtyItems = d['items'] as List? ?? const [];
                          if (n == 0) {
                            return const CompactStatus(
                              message: 'Nenhum assunto suspeito encontrado.',
                              icon: Icons.label_outline_rounded,
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionLabel('Assuntos suspeitos', hint: '$n assuntos de áreas misturadas · rode Reclassificar'),
                              for (final raw in dirtyItems.take(6))
                                Builder(
                                  builder: (_) {
                                    final it = Map<String, dynamic>.from(raw as Map);
                                    return PlaylistTile(
                                      title: '${it['subject']}',
                                      subtitle: '${it['topic']}',
                                      badge: 'sujo',
                                      leadingIcon: Icons.warning_amber_rounded,
                                      onPlay: () {
                                        final id = it['id']?.toString();
                                        if (id != null && id.isNotEmpty) context.go('/questoes/$id');
                                      },
                                    );
                                  },
                                ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
                      SurfacePanel(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionLabel('Inventário (base local)'),
                            const SizedBox(height: 8),
                            Text(
                              'Oficiais: $officialN · Natureza: $natN\n'
                              'Resoluções reais: $realN'
                              '${realPct != null ? ' ($realPct%)' : ''}\n'
                              'Cross-domain (labels suspeitas): $crossN',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                            ),
                            if (curation['message'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                curation['message'].toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: cs.onSurface.f72,
                                ),
                              ),
                            ],
                            Text(
                              'Números da base — sem inventar % de frequência na prova.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        title: const Text('Gerar rascunhos de explicação'),
                        subtitle: const Text('Não substitui revisão humana'),
                        trailing: FilledButton.tonal(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            try {
                              final data = await apiClient.post('/api/professor/batch-fill', {
                                'limit': 8,
                                'preferUema': true,
                              });
                              if (!context.mounted) return;
                              final n = (data as Map)['updated'] ?? 0;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gerados: $n')),
                              );
                              ref.invalidate(medicineProvider);
                              ref.read(refreshTickProvider.notifier).state++;
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'))));
                            }
                          },
                          child: const Text('Gerar'),
                        ),
                      ),
                      ListTile(
                        title: const Text('Reclassificar assuntos'),
                        subtitle: const Text('Corrige disciplina mal etiquetada (Natureza × outras)'),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            HapticFeedback.selectionClick();
                            try {
                              final data = await apiClient.post('/api/ingest/classify-pending', {});
                              if (!context.mounted) return;
                              final m = data as Map;
                              final residual = m['residualCrossDomain'] ?? m['updated'];
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    m['message']?.toString() ??
                                        'Atualizados: ${m['updated'] ?? 0} · residual: $residual',
                                  ),
                                ),
                              );
                              ref.invalidate(medicineProvider);
                              ref.read(refreshTickProvider.notifier).state++;
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'))));
                            }
                          },
                          child: const Text('Rodar'),
                        ),
                      ),
                      ListTile(
                        title: const Text('Completar explicações Natureza'),
                        subtitle: const Text('4 eixos didáticos — modelo de apoio, não texto da banca'),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            HapticFeedback.selectionClick();
                            try {
                              final data = await apiClient.post('/api/curation/promote-natureza-real', {
                                'limit': 8,
                              });
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Completadas: ${(data as Map)['promoted'] ?? 0}')),
                              );
                              ref.invalidate(medicineProvider);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'))));
                            }
                          },
                          child: const Text('Rodar'),
                        ),
                      ),
                      ListTile(
                        title: const Text('Completar base didática (todas as áreas)'),
                        subtitle: const Text('Não inventa frequência na prova; só preenche explicação de treino'),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            try {
                              final data = await apiClient.post('/api/curation/promote-all-pending', {
                                'limit': 40,
                              });
                              if (!context.mounted) return;
                              final m = data as Map;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Elevados: ${m['promotedTotal'] ?? 0}')),
                              );
                              ref.invalidate(medicineProvider);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(humanApiError(e, fallback: 'Não deu para concluir. Tente de novo.'))));
                            }
                          },
                          child: const Text('Rodar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
    );
  }
}
