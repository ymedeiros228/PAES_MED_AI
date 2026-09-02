import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/ui_kit.dart';

/// Relógio da sessão com efeito de "breathing" quando pausado.
/// Pulsar suave (opacity 0.6 ↔ 1.0) indica que está pausado mas ativo.
/// Pulse (AnimatedScale) no último minuto da fase avisa que o tempo está acabando.
class SessionBreathingClock extends StatefulWidget {
  const SessionBreathingClock({required this.paused, required this.clock, this.pulse = false});
  final bool paused;
  final String clock;
  /// Pulse sutil quando faltam ≤ 60s na fase atual.
  final bool pulse;

  @override
  State<SessionBreathingClock> createState() => SessionBreathingClockState();
}

class SessionBreathingClockState extends State<SessionBreathingClock>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.paused) _breath.repeat(reverse: true);
    if (widget.pulse && !widget.paused) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SessionBreathingClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paused != widget.paused) {
      if (widget.paused) {
        _breath.repeat(reverse: true);
      } else {
        _breath.stop();
        _breath.value = 1.0;
      }
    }
    if (oldWidget.pulse != widget.pulse) {
      if (widget.pulse && !widget.paused) {
        _pulse.repeat(reverse: true);
      } else {
        _pulse.stop();
        _pulse.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = widget.paused ? 'Pausado ${widget.clock}' : widget.clock;
    final color = widget.paused ? cs.tertiary : (widget.pulse ? cs.tertiary : cs.primary);
    final icon = widget.paused
        ? Icons.pause_circle_outline_rounded
        : (widget.pulse ? Icons.timer_3_outlined : Icons.timer_outlined);

    Widget content(Color c) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: 0.2,
              ),
            ),
          ],
        );

    if (!widget.paused && !widget.pulse) {
      return SurfacePanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: content(color),
      );
    }

    if (widget.pulse && !widget.paused) {
      // Pulse sutil (scale 1.0 ↔ 1.06) no último minuto da fase
      return AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_pulse.value);
          return SurfacePanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: AnimatedScale(
              scale: 1.0 + t * 0.06,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
              child: content(color.withOpacity(0.7 + t * 0.3)),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_breath.value);
        return SurfacePanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: content(color.withOpacity(0.6 + t * 0.4)),
        );
      },
    );
  }
}

class SessionInsightBanner extends StatelessWidget {
  const SessionInsightBanner({
    required this.correctCount,
    required this.wrongCount,
    required this.total,
    required this.subject,
    required this.topic,
  });

  final int correctCount;
  final int wrongCount;
  final int total;
  final String subject;
  final String topic;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final acc = total > 0 ? correctCount / total : 0.0;

    String message;
    IconData icon;
    Color color;

    if (total == 0) {
      return const SizedBox.shrink();
    } else if (acc >= 0.8) {
      message = 'Excelente! Você dominou $topic em $subject. '
          'Hora de tentar um tópico novo ou um simulado completo.';
      icon = Icons.celebration_rounded;
      color = const Color(0xFF4CAF50);
    } else if (acc >= 0.6) {
      message = 'Bom ritmo em $topic! Revise os $wrongCount erro(s) e '
          'tente novamente amanhã para consolidar.';
      icon = Icons.trending_up_rounded;
      color = cs.primary;
    } else if (acc >= 0.4) {
      message = 'Você acertou $correctCount de $total em $topic. '
          'Leia a teoria antes de tentar de novo - vai fazer diferença.';
      icon = Icons.menu_book_rounded;
      color = const Color(0xFFE8A04B);
    } else {
      message = 'Tópico difícil: $topic em $subject. Não desanime! '
          'Comece pela teoria e volte com calma.';
      icon = Icons.school_rounded;
      color = cs.error;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Cartao de inicio da sessao: resumo, 1 botao, personalizacao escondida.
class SessionStartCard extends StatelessWidget {
  const SessionStartCard({required this.plan, required this.onStart});
  final Map<String, dynamic>? plan;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final study = plan?['studyToday'] as Map? ?? {};
    final subj = study['subject']?.toString() ?? 'do seu plano';
    final top = study['topic']?.toString() ?? 'Tema do dia';
    final phases = (plan?['sessionPlan'] as List? ?? [
      {'phase': 'questions', 'minutes': 40, 'title': 'Estudar'},
      {'phase': 'revisions', 'minutes': 10, 'title': 'Debrief'},
    ]);
    final totalMin = phases.fold<int>(0, (s, p) => s + ((p as Map)['minutes'] as num? ?? 0).toInt());
    final questionCount = (plan?['questionCount'] as int?) ?? (phases.firstWhere(
          (p) => (p as Map)['phase'] == 'questions',
      orElse: () => {'count': 8},
    ) as Map)['count'] ?? 8;

    return SurfacePanel(
      color: cs.primaryContainer.withOpacity(0.25),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Pronto para estudar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$subj · $top',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SessionMetric(icon: Icons.quiz_outlined, value: '$questionCount', label: 'questões'),
                      const SizedBox(width: 24),
                      _SessionMetric(icon: Icons.timer_outlined, value: '$totalMin', label: 'minutos'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TapScale(
                    child: FilledButton.icon(
                      onPressed: onStart,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: Text(
                        'Estudar agora',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              collapsedBackgroundColor: cs.surfaceContainerHighest.withOpacity(0.2),
              backgroundColor: cs.surfaceContainerHighest.withOpacity(0.2),
              title: Text(
                'Personalizar sessão',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              subtitle: Text(
                'Escolha outro modo de estudo',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.4),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SessionShortcutChip(label: 'Questões', icon: Icons.quiz_outlined, path: '/questoes'),
                      _SessionShortcutChip(label: 'Flashcards', icon: Icons.style_outlined, path: '/flashcards'),
                      _SessionShortcutChip(label: 'Tutor IA', icon: Icons.auto_awesome_outlined, path: '/tutor'),
                      _SessionShortcutChip(label: 'Simulado', icon: Icons.bolt_outlined, path: '/simulados'),
                      _SessionShortcutChip(label: 'Redação', icon: Icons.edit_note_outlined, path: '/redacao'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _SessionMetric extends StatelessWidget {
  const _SessionMetric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: cs.primary, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}


class _SessionShortcutChip extends StatelessWidget {
  const _SessionShortcutChip({required this.label, required this.icon, required this.path});
  final String label;
  final IconData icon;
  final String path;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        HapticFeedback.selectionClick();
        context.go(path);
      },
    );
  }
}
