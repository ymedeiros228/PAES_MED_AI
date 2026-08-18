import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/focus_controller.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key, this.subject, this.year});

  final String? subject;
  final int? year;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(focusControllerProvider.notifier).configure(subject: widget.subject, year: widget.year);
    });
  }

  String _fmtTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(focusControllerProvider);
    final cs = Theme.of(context).colorScheme;

    if (!_started) {
      return _buildSetupScreen(state, cs);
    }
    if (state.isLoading) {
      return _buildLoading(cs);
    }
    if (state.error != null && state.questions.isEmpty) {
      return _buildError(state, cs);
    }
    if (state.finished) {
      return _buildSummary(state, cs);
    }
    return _buildQuestionScreen(state, cs);
  }

  Widget _buildSetupScreen(FocusState state, ColorScheme cs) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text('Modo Foco', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.center_focus_strong_rounded, size: 72, color: cs.primary),
              const SizedBox(height: 24),
              Text(
                'Estudo sem distrações',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Uma questão por vez. Responda, veja a resolução e avance.\nSem sidebar, sem notificações — só você e a prova.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 32),
              _FilterChip(
                label: widget.subject ?? 'Todas as disciplinas',
                icon: Icons.school_rounded,
                onTap: () => _showSubjectPicker(cs),
              ),
              const SizedBox(height: 10),
              _FilterChip(
                label: widget.year == null ? 'Todos os anos' : 'Ano ${widget.year}',
                icon: Icons.calendar_today_rounded,
                onTap: () => _showYearPicker(cs),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _started = true);
                  ref.read(focusControllerProvider.notifier).loadQuestions(count: 20);
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Começar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubjectPicker(ColorScheme cs) {
    final subjects = ['Todas', 'Biologia', 'Física', 'Química', 'História', 'Geografia', 'Matemática', 'Filosofia', 'Sociologia', 'Língua Portuguesa e Literatura'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text('Escolha a disciplina', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            ...subjects.map((s) => ListTile(
              title: Text(s),
              trailing: widget.subject == s || (s == 'Todas' && widget.subject == null) ? Icon(Icons.check, color: cs.primary) : null,
              onTap: () {
                Navigator.pop(ctx);
                ref.read(focusControllerProvider.notifier).configure(subject: s == 'Todas' ? null : s, year: widget.year);
                setState(() {});
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showYearPicker(ColorScheme cs) {
    final years = [null, 2026, 2025, 2024, 2022, 2021, 2020, 2019, 2018, 2017, 2015];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text('Escolha o ano', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            ...years.map((y) => ListTile(
              title: Text(y == null ? 'Todos os anos' : y.toString()),
              trailing: widget.year == y ? Icon(Icons.check, color: cs.primary) : null,
              onTap: () {
                Navigator.pop(ctx);
                ref.read(focusControllerProvider.notifier).configure(subject: widget.subject, year: y);
                setState(() {});
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(ColorScheme cs) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Carregando questões...', style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildError(FocusState state, ColorScheme cs) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.go('/dashboard'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text(state.error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => setState(() => _started = false), child: const Text('Voltar')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionScreen(FocusState state, ColorScheme cs) {
    final q = state.currentQuestion!;
    final progress = (state.currentIndex + 1) / state.total;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header com cronometro e progresso
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _confirmExit(cs);
                    },
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(_fmtTime(state.elapsedSeconds), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Info da questao
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Questão ${state.currentIndex + 1} de ${state.total}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.5)),
                  ),
                  const Spacer(),
                  if (q.year > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(6)),
                      child: Text('${q.year}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSecondaryContainer)),
                    ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: cs.tertiaryContainer, borderRadius: BorderRadius.circular(6)),
                    child: Text(q.subject, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onTertiaryContainer)),
                  ),
                ],
              ),
            ),
            // Enunciado e alternativas
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Text(q.statement, style: TextStyle(fontSize: 15, height: 1.5)),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(q.options.length, (i) {
                    final letter = String.fromCharCode(65 + i);
                    final isSelected = state.selectedIndex == i;
                    final isCorrect = i == q.correctIndex;
                    final showResult = state.revealed;
                    Color? bg;
                    Color? border;
                    Icon? trailing;
                    if (showResult && isCorrect) {
                      bg = cs.primaryContainer.withOpacity(0.4);
                      border = cs.primary;
                      trailing = Icon(Icons.check_circle, color: cs.primary, size: 22);
                    } else if (showResult && isSelected && !isCorrect) {
                      bg = cs.errorContainer.withOpacity(0.4);
                      border = cs.error;
                      trailing = Icon(Icons.cancel, color: cs.error, size: 22);
                    } else if (isSelected) {
                      bg = cs.primaryContainer.withOpacity(0.3);
                      border = cs.primary.withOpacity(0.5);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: showResult ? null : () {
                          HapticFeedback.selectionClick();
                          ref.read(focusControllerProvider.notifier).selectOption(i);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border ?? cs.outlineVariant, width: border != null ? 2 : 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: showResult && isCorrect ? cs.primary : (showResult && isSelected && !isCorrect ? cs.error : cs.surfaceContainerHighest),
                                ),
                                child: Center(
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: showResult && (isCorrect || (isSelected && !isCorrect)) ? cs.onPrimary : cs.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(q.options[i], style: TextStyle(fontSize: 14, height: 1.4))),
                              if (trailing != null) ...[const SizedBox(width: 8), trailing],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  if (state.revealed && q.resolution != null && q.resolution!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, size: 18, color: cs.primary),
                              const SizedBox(width: 6),
                              Text('Resolução', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(q.resolution!, style: TextStyle(fontSize: 13, height: 1.5, color: cs.onPrimaryContainer.withOpacity(0.95))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Barra de acoes
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  if (!state.revealed)
                    Expanded(
                      child: FilledButton(
                        onPressed: state.selectedIndex == null ? null : () {
                          HapticFeedback.mediumImpact();
                          ref.read(focusControllerProvider.notifier).revealAnswer();
                        },
                        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                        child: const Text('Confirmar resposta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    )
                  else
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ref.read(focusControllerProvider.notifier).nextQuestion();
                        },
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          state.currentIndex + 1 >= state.total ? 'Ver resultado' : 'Próxima questão',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(FocusState state, ColorScheme cs) {
    final correct = state.correctCount;
    final total = state.total;
    final pct = total > 0 ? (correct / total * 100).round() : 0;
    final wrong = total - correct;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.go('/dashboard')),
        title: Text('Resultado', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                pct >= 70 ? Icons.emoji_events_rounded : (pct >= 50 ? Icons.thumb_up_rounded : Icons.school_rounded),
                size: 80,
                color: pct >= 70 ? Colors.amber[700] : (pct >= 50 ? cs.primary : cs.onSurface.withOpacity(0.4)),
              ),
              const SizedBox(height: 16),
              Text(
                '$pct%',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: cs.primary),
              ),
              const SizedBox(height: 4),
              Text(
                '$correct de $total questões corretas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: cs.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 24),
              _StatCard(icon: Icons.check_circle_outline, label: 'Acertos', value: '$correct', color: cs.primary),
              const SizedBox(height: 10),
              _StatCard(icon: Icons.cancel_outlined, label: 'Erros', value: '$wrong', color: cs.error),
              const SizedBox(height: 10),
              _StatCard(icon: Icons.timer_outlined, label: 'Tempo total', value: _fmtTime(state.elapsedSeconds), color: cs.tertiary),
              const SizedBox(height: 10),
              _StatCard(icon: Icons.speed_rounded, label: 'Tempo médio por questão', value: _fmtTime((state.elapsedSeconds / total).round()), color: cs.secondary),
              const Spacer(),
              if (state.wrongIds.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(focusControllerProvider.notifier).reset();
                    setState(() => _started = false);
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Revisar erradas (em breve)'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(focusControllerProvider.notifier).reset();
                  setState(() => _started = false);
                },
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                child: const Text('Nova sessão', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: () => context.go('/dashboard'), child: const Text('Voltar ao início')),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmExit(ColorScheme cs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do Modo Foco?'),
        content: const Text('Seu progresso desta sessão será perdido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continuar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(focusControllerProvider.notifier).reset();
              context.go('/dashboard');
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
            Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.7)))),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
