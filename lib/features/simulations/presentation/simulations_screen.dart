import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/providers.dart';
import '../../../core/widgets/resolution_debrief.dart';
import '../../../core/widgets/training_basis_banner.dart';
import '../../../core/widgets/ui_kit.dart';

class SimulationsScreen extends ConsumerStatefulWidget {
  const SimulationsScreen({super.key});

  @override
  ConsumerState<SimulationsScreen> createState() => _SimulationsScreenState();
}

class _SimulationsScreenState extends ConsumerState<SimulationsScreen> {
  String mode = 'dia_prova';
  String? subject;
  int limit = 10;
  bool showOtherModes = false;
  List<dynamic> questions = [];
  final Map<String, int> answers = {};
  final Map<String, String> errorTypes = {};
  Map<String, dynamic>? report;
  Map<String, dynamic>? lastSimMeta;
  /// Ciclo AJ: corpos com quality/eixos para debrief pós-sim.
  final Map<String, Map<String, dynamic>> debriefById = {};
  final Set<String> debriefLoading = {};
  String defaultErrorType = 'conceito';
  final sw = Stopwatch();
  Timer? ticker;
  bool examLocked = false;
  bool preflightDone = false;
  bool running = false;

  static const _modes = <(String, String, String, IconData)>[
    ('dia_prova', 'Dia de prova', 'Cronômetro e sem gabarito até terminar', Icons.timer_outlined),
    ('prova_completa', 'Prova completa', 'Treino com o recorte usual da prova', Icons.assignment_outlined),
    ('medicina', 'Medicina', 'Foco em Natureza e raciocínio biomédico', Icons.biotech_outlined),
    ('revisao', 'Revisão', 'O que já está na fila / due', Icons.replay_rounded),
    ('incidencia', 'Por incidência', 'Tópicos que mais caem (quando houver base)', Icons.insights_outlined),
    ('disciplina', 'Por disciplina', 'Escolha a matéria', Icons.menu_book_outlined),
  ];

  static const _errorLabels = {
    'conceito': 'Conceito',
    'interpretacao': 'Interpretação',
    'calculo': 'Cálculo',
    'distracao': 'Distração',
    'tempo': 'Tempo',
  };

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  Future<bool> _preflightDiaProva() async {
    Map<String, dynamic> basis = {};
    try {
      final h = await apiClient.get('/health');
      basis = Map<String, dynamic>.from(h as Map);
    } catch (_) {}
    final n = basis['officialCount'] as int? ?? 0;
    final mins = (limit * 1.5).ceil().clamp(15, 90);
    if (!mounted) return false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pronto para o dia de prova?'),
        content: Text(
          n < 10
              ? 'Há poucas oficiais na base ($n). Este modo NÃO inventa prova UEMA — sem acervo sério, a base de treino fica rotulada como treino.\n\n'
                  'Tempo estimado: ~$mins min.\nResolução só ao finalizar.'
              : 'Base oficial: $n questões (contagem local).\nTempo estimado: ~$mins min.\nResolução oculta até finalizar · sem treino disfarçado neste pack.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Começar')),
        ],
      ),
    );
    return go == true;
  }

  Future<void> _start() async {
    if (mode == 'dia_prova') {
      final ok = await _preflightDiaProva();
      if (!ok) return;
    }
    final data = await apiClient.post('/api/simulations', {
      'mode': mode,
      'subject': subject,
      'limit': limit,
    });
    final map = Map<String, dynamic>.from(data as Map);
    ticker?.cancel();
    setState(() {
      lastSimMeta = map;
      questions = map['questions'] as List<dynamic>? ?? [];
      answers.clear();
      errorTypes.clear();
      debriefById.clear();
      debriefLoading.clear();
      report = null;
      running = true;
      examLocked = mode == 'dia_prova';
      preflightDone = mode == 'dia_prova';
      sw
        ..reset()
        ..start();
    });
    final hardCap = mode == 'dia_prova' ? Duration(minutes: (limit * 1.5).ceil().clamp(15, 90)) : null;
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (hardCap != null && sw.elapsed >= hardCap && report == null) {
        _grade();
        return;
      }
      setState(() {});
    });
  }

  Future<void> _grade() async {
    sw.stop();
    ticker?.cancel();
    final payload = answers.entries
        .map((e) => {
              'questionId': e.key,
              'selectedIndex': e.value,
              'timeMs': sw.elapsedMilliseconds ~/ answers.length.clamp(1, 999),
              'errorType': errorTypes[e.key] ?? defaultErrorType,
            })
        .toList();
    final data = await apiClient.post('/api/simulations/grade', {'answers': payload});
    ref.read(refreshTickProvider.notifier).state++;
    setState(() {
      report = Map<String, dynamic>.from(data as Map);
      running = false;
      examLocked = false;
    });
    for (final raw in (report?['results'] as List? ?? [])) {
      final r = Map<String, dynamic>.from(raw as Map);
      if (r['correct'] == true) continue;
      final id = r['questionId']?.toString();
      if (id != null && id.isNotEmpty) unawaited(_ensureDebrief(id));
    }
  }

  Future<void> _ensureDebrief(String id) async {
    if (debriefById.containsKey(id) || debriefLoading.contains(id)) return;
    setState(() => debriefLoading.add(id));
    try {
      for (final raw in questions) {
        final q = Map<String, dynamic>.from(raw as Map);
        if (q['id']?.toString() == id &&
            (q['resolutionQuality'] != null ||
                q['resolutionAxes'] != null ||
                q['resolution'] != null)) {
          if (mounted) {
            setState(() {
              debriefById[id] = q;
              debriefLoading.remove(id);
            });
          }
          return;
        }
      }
      final data = await apiClient.get('/api/questions/$id');
      if (!mounted) return;
      setState(() {
        debriefById[id] = Map<String, dynamic>.from(data as Map);
        debriefLoading.remove(id);
      });
    } catch (_) {
      if (mounted) setState(() => debriefLoading.remove(id));
    }
  }

  Widget _debriefBlock(String questionId, String subject, String topic) {
    final q = debriefById[questionId];
    if (debriefLoading.contains(questionId) && q == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (q == null) {
      return TextButton(
        onPressed: () => _ensureDebrief(questionId),
        child: const Text('Carregar explicação'),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: ResolutionDebrief(
        question: q,
        trailing: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: () => context.go(
                '/adaptativo?subject=${Uri.encodeComponent(subject)}'
                '&topic=${Uri.encodeComponent(topic)}',
              ),
              child: const Text('Remediar'),
            ),
            TextButton(onPressed: () => context.go('/fila'), child: const Text('Fila')),
            TextButton(
              onPressed: () => context.go(
                '/sessao?examBoard=UEMA_PAES&preferNatureza=1',
              ),
              child: const Text('Sessão Natureza'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _remediateGaps() async {
    final gaps = (report!['gaps'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    try {
      final data = await apiClient.post('/api/simulations/schedule-gaps', {'gaps': gaps});
      final map = Map<String, dynamic>.from(data as Map);
      final cta = map['cta']?.toString() ?? '/fila';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lacunas na fila (${map['scheduled'] ?? 0}).')),
      );
      context.go(cta);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String get _clock {
    final e = sw.elapsed;
    return '${e.inMinutes.toString().padLeft(2, '0')}:${(e.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inSession = running || report != null;
    final genInPack = lastSimMeta == null
        ? 0
        : (lastSimMeta!['generatedInPack'] as int? ??
            (lastSimMeta!['questions'] as List? ?? [])
                .where((q) => q is Map && q['generated'] == true)
                .length);
    final wrongResults = (report?['results'] as List? ?? [])
        .whereType<Map>()
        .where((r) => r['correct'] != true)
        .toList();

    return ListView(
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: 'Treino',
                title: 'Simulados',
                subtitle: inSession
                    ? (report != null ? 'Resultado deste bloco' : 'Responda e finalize quando quiser')
                    : 'Escolha um modo e faça um bloco como no dia da prova',
                trailing: inSession && report == null
                    ? SurfacePanel(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        color: examLocked ? cs.tertiaryContainer.withOpacity(0.55) : null,
                        child: Text(
                          _clock,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontFeatures: const [FontFeature.tabularFigures()],
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      )
                    : null,
              ),

              if (lastSimMeta != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TrainingBasisBanner(
                    basis: lastSimMeta!['basis']?.toString(),
                    message: lastSimMeta!['warning']?.toString() ??
                        (lastSimMeta!['basis'] == 'oficial'
                            ? (genInPack > 0
                                ? 'Pack com $genInPack item(ns) gerados — não confunda com oficiais.'
                                : null)
                            : 'Este bloco usou base de treino. Monte a Biblioteca para Dia de prova sério.'),
                    showLibraryCta: lastSimMeta!['basis'] != 'oficial',
                    areaKey: 'simulados',
                  ),
                )
              else if (!inSession && (mode == 'dia_prova' || mode == 'medicina'))
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: TrainingBasisBanner(
                    basis: 'treino',
                    message:
                        'Dia de prova e Medicina pedem oficiais. Sem acervo, o app rotula treino — não inventa incidência.',
                    areaKey: 'simulados',
                  ),
                ),

              if (!inSession) ...[
                SectionLabel('Dia de prova', hint: 'Caminho principal · cronômetro · gabarito no fim'),
                _ModeCard(
                  selected: mode == 'dia_prova',
                  icon: Icons.timer_outlined,
                  title: 'Dia de prova',
                  subtitle: 'Cronômetro e sem gabarito até terminar',
                  onTap: () => setState(() => mode = 'dia_prova'),
                ),
                const SizedBox(height: 4),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  initiallyExpanded: showOtherModes || mode != 'dia_prova',
                  onExpansionChanged: (v) => setState(() => showOtherModes = v),
                  title: Text('Outros modos', style: Theme.of(context).textTheme.titleSmall),
                  children: [
                    for (final m in _modes.where((e) => e.$1 != 'dia_prova'))
                      _ModeCard(
                        selected: mode == m.$1,
                        icon: m.$4,
                        title: m.$2,
                        subtitle: m.$3,
                        onTap: () => setState(() => mode = m.$1),
                      ),
                  ],
                ),
                if (mode == 'disciplina') ...[
                  const SizedBox(height: 8),
                  DropdownMenu<String>(
                    label: const Text('Disciplina'),
                    onSelected: (v) => setState(() => subject = v),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'Biologia', label: 'Biologia'),
                      DropdownMenuEntry(value: 'Química', label: 'Química'),
                      DropdownMenuEntry(value: 'Física', label: 'Física'),
                      DropdownMenuEntry(value: 'Matemática', label: 'Matemática'),
                      DropdownMenuEntry(value: 'Língua Portuguesa e Literatura', label: 'Português'),
                    ],
                  ),
                ],
                if (mode == 'disciplina' && (subject == null || subject!.isEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Escolha a disciplina antes de iniciar.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                const SizedBox(height: 12),
                SectionLabel('Quantidade', hint: '$limit questões'),
                Slider(
                  value: limit.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  label: '$limit',
                  onChanged: (v) => setState(() => limit = v.round()),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: (mode == 'disciplina' && (subject == null || subject!.isEmpty))
                      ? null
                      : _start,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(mode == 'dia_prova' ? 'Começar dia de prova' : 'Iniciar simulado'),
                ),
              ],

              if (running && report == null && !examLocked) ...[
                SectionLabel('Se errar, marque o tipo', hint: 'Padrão para o bloco inteiro'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final e in _errorLabels.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        selected: defaultErrorType == e.key,
                        onSelected: (_) => setState(() => defaultErrorType = e.key),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              if (examLocked && report == null)
                QuietEmpty(
                  message: 'Modo dia de prova: resposta livre agora; revisão só no fim.',
                ),

              for (var qi = 0; qi < questions.length; qi++)
                Builder(
                  builder: (context) {
                    final q = Map<String, dynamic>.from(questions[qi] as Map);
                    final id = q['id'] as String;
                    final opts = (q['options'] as List).map((e) => e.toString()).toList();
                    final year = q['year'];
                    return SurfacePanel(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Questão ${qi + 1} de ${questions.length}'
                            '${year != null ? ' · $year' : ''}',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${q['subject'] ?? ''} · ${q['topic'] ?? ''}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(q['statement']?.toString() ?? ''),
                          const SizedBox(height: 4),
                          for (var i = 0; i < opts.length; i++)
                            RadioListTile<int>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: i,
                              groupValue: answers[id],
                              onChanged: report != null ? null : (v) => setState(() => answers[id] = v!),
                              title: Text('${'ABCDE'[i]}) ${opts[i]}'),
                            ),
                          if (report == null && answers.containsKey(id) && !examLocked)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: DropdownButton<String>(
                                value: errorTypes[id] ?? defaultErrorType,
                                hint: const Text('Tipo de erro se miss'),
                                items: [
                                  for (final e in _errorLabels.entries)
                                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => errorTypes[id] = v);
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

              if (questions.isNotEmpty && report == null) ...[
                const SizedBox(height: 4),
                FilledButton.tonal(
                  onPressed: answers.length < questions.length ? null : _grade,
                  child: Text(
                    answers.length < questions.length
                        ? 'Responda todas (${answers.length}/${questions.length})'
                        : 'Finalizar e corrigir',
                  ),
                ),
              ],

              if (report != null) ...[
                SectionLabel('Resultado'),
                SurfacePanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: cs.primaryContainer.withOpacity(0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${((report!['accuracy'] as num) * 100).toStringAsFixed(0)}% de acerto',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${report!['correct']}/${report!['total']} corretas · tempo $_clock',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (report!['avgTimeMs'] != null)
                        Text(
                          'Média ${((report!['avgTimeMs'] as num) / 1000).toStringAsFixed(1)}s por item',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (report!['warning'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${report!['warning']}',
                          style: TextStyle(color: cs.error),
                        ),
                      ],
                    ],
                  ),
                ),

                if ((report!['subjectBreakdown'] as List? ?? []).isNotEmpty) ...[
                  SectionLabel('Por disciplina'),
                  for (final s in (report!['subjectBreakdown'] as List).take(8))
                    PlaylistTile(
                      title: (s as Map)['subject']?.toString() ?? '—',
                      subtitle:
                          '${s['correct']}/${s['total']} · ${(((s['accuracy'] as num?) ?? 0) * 100).toStringAsFixed(0)}%',
                      leadingIcon: Icons.school_outlined,
                    ),
                ],

                if ((report!['gaps'] as List? ?? []).isNotEmpty) ...[
                  SectionLabel('Lacunas para treinar'),
                  for (final g in (report!['gaps'] as List).take(6))
                    PlaylistTile(
                      title: '${(g as Map)['subject']} · ${g['topic']}',
                      subtitle: '${g['wrong']} erro(s)',
                      leadingIcon: Icons.flag_outlined,
                      onPlay: () => context.go(
                        '/adaptativo?subject=${Uri.encodeComponent(g['subject']?.toString() ?? '')}'
                        '&topic=${Uri.encodeComponent(g['topic']?.toString() ?? '')}',
                      ),
                    ),
                ],

                if (wrongResults.isNotEmpty) ...[
                  SectionLabel('Erros — debrief', hint: '4 eixos quando a resolução for real'),
                  for (final r in wrongResults.take(8))
                    SurfacePanel(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r['subject'] ?? ''} · ${r['topic'] ?? ''}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          _debriefBlock(
                            r['questionId']?.toString() ?? '',
                            r['subject']?.toString() ?? '',
                            r['topic']?.toString() ?? '',
                          ),
                        ],
                      ),
                    ),
                ],

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((report!['gaps'] as List? ?? []).isNotEmpty)
                      FilledButton(
                        onPressed: _remediateGaps,
                        child: const Text('Mandar lacunas para a fila'),
                      )
                    else
                      FilledButton(
                        onPressed: () => context.go('/fila'),
                        child: const Text('Ir à fila'),
                      ),
                    FilledButton.tonal(
                      onPressed: () => context.go('/sessao?examBoard=UEMA_PAES&preferNatureza=1'),
                      child: const Text('Sessão Natureza'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => context.go('/redacao'),
                      child: const Text('Redação'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Voltar ao Hoje'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          questions = [];
                          report = null;
                          lastSimMeta = null;
                          debriefById.clear();
                          debriefLoading.clear();
                          running = false;
                          answers.clear();
                        });
                      },
                      child: const Text('Novo simulado'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Detalhe das respostas', style: Theme.of(context).textTheme.titleSmall),
                  children: [
                    for (final r in (report!['results'] as List? ?? []))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          (r as Map)['correct'] == true ? Icons.check_circle : Icons.cancel,
                          color: r['correct'] == true ? Colors.green : Colors.red,
                        ),
                        title: Text('${r['subject']} · ${r['topic']}'),
                        trailing: TextButton(
                          onPressed: () => context.go('/questoes/${r['questionId']}'),
                          child: const Text('Ver'),
                        ),
                      ),
                    if ((report!['professorHints'] as List? ?? []).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Macete dos erros', style: Theme.of(context).textTheme.titleSmall),
                      for (final h in (report!['professorHints'] as List).take(5))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${(h as Map)['topic']}'),
                          subtitle: Text(h['macete']?.toString() ?? ''),
                          trailing: TextButton(
                            onPressed: () => context.go('/questoes/${h['questionId']}'),
                            child: const Text('Abrir'),
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? cs.primaryContainer.withOpacity(0.55) : cs.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? cs.primary.withOpacity(0.55) : cs.outlineVariant.withOpacity(0.85),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: selected ? cs.primary : cs.onSurface.withOpacity(0.7)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
