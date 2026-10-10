import 'package:flutter/material.dart';
import '../../../questions/presentation/widgets/figura_aviso.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';
import 'simulation_setup_panel.dart';
import 'simulation_widgets.dart';

/// Fluxo durante o simulado: cronômetro, questões e botão de corrigir.
class SimulationExamPanel extends StatelessWidget {
  const SimulationExamPanel({
    super.key,
    required this.running,
    required this.examLocked,
    required this.checkpointSaveError,
    required this.defaultErrorType,
    required this.diaProvaHardCap,
    required this.elapsedSeconds,
    required this.clock,
    required this.timeRemainingLabel,
    required this.questions,
    required this.answers,
    required this.errorTypes,
    required this.keyboardQuestionIndex,
    required this.grading,
    required this.onRetryCheckpointSave,
    required this.onDefaultErrorTypeChanged,
    required this.onSelectAnswer,
    required this.onErrorTypeForQuestion,
    required this.onGrade,
  });

  final bool running;
  final bool examLocked;
  final String? checkpointSaveError;
  final String defaultErrorType;
  final Duration? diaProvaHardCap;
  final int elapsedSeconds;
  final String clock;
  final String timeRemainingLabel;
  final List<dynamic> questions;
  final Map<String, int> answers;
  final Map<String, String> errorTypes;
  final int keyboardQuestionIndex;
  final bool grading;
  final VoidCallback onRetryCheckpointSave;
  final ValueChanged<String> onDefaultErrorTypeChanged;
  final void Function(int questionIndex, String questionId, int optionIndex) onSelectAnswer;
  final void Function(String questionId, String errorType) onErrorTypeForQuestion;
  final VoidCallback onGrade;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (running && checkpointSaveError != null) ...[
          QuietEmpty(
            message: checkpointSaveError!,
            action: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onRetryCheckpointSave();
              },
              child: const Text('Tentar'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (running && !examLocked) ...[
          const SectionLabel('Se errar, marque o tipo', hint: 'Padrão para o bloco inteiro'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in simulationErrorLabels.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: defaultErrorType == e.key,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    onDefaultErrorTypeChanged(e.key);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (examLocked)
          SurfacePanel(
            margin: const EdgeInsets.only(bottom: 12),
            color: cs.tertiaryContainer.f45,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SimulationCircularTimer(
                  remainingSeconds: diaProvaHardCap != null
                      ? (diaProvaHardCap!.inSeconds - elapsedSeconds)
                          .clamp(0, diaProvaHardCap!.inSeconds)
                      : 0,
                  totalSeconds: diaProvaHardCap?.inSeconds ?? 0,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulado do dia em andamento',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Respondidas: ${answers.length} de ${questions.length}',
                        style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'O gabarito só aparece no final. Quando o tempo acabar, o app corrige sozinho.',
                        style: TextStyle(fontSize: 13, color: cs.onSurface.f65),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (questions.isNotEmpty) ...[
          Row(children: [
            Text(
              'Questão ${(keyboardQuestionIndex + 1).clamp(1, questions.length)} de ${questions.length}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const Spacer(),
            Text('${answers.length} respondidas',
                style: TextStyle(fontSize: 12, color: cs.onSurface.f72)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: answers.length / questions.length),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 4),
            ),
          ),
          const SizedBox(height: 14),
        ],
        for (var qi = 0; qi < questions.length; qi++)
          Builder(
            builder: (context) {
              final q = Map<String, dynamic>.from(questions[qi] as Map);
              final id = q['id'] as String;
              final opts = (q['options'] as List).map((e) => e.toString()).toList();
              final year = q['year'];
              final kbActive = running && qi == keyboardQuestionIndex;
              return SurfacePanel(
                margin: const EdgeInsets.only(bottom: 12),
                color: kbActive ? cs.primaryContainer.withOpacity(0.28) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Questão ${qi + 1} de ${questions.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    QuestionMetaChips(
                      subject: '${q['subject'] ?? ''}',
                      topic: '${q['topic'] ?? ''}',
                      year: (year as num?)?.toInt(),
                    ),
                    const SizedBox(height: 8),
                    FiguraAviso(statement: q['statement']?.toString() ?? ''),
                    StatementView(
                      key: ValueKey('sim_stmt_$id'),
                      text: q['statement']?.toString() ?? '',
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < opts.length; i++)
                      ChoiceOptionTile(
                        key: ValueKey('sim_opt_${id}_$i'),
                        index: i,
                        label: opts[i].toString(),
                        selected: answers[id] == i,
                        enabled: true,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelectAnswer(qi, id, i);
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        year != null
                            ? 'Fonte: PAES $year · UEMA (oficial)'
                            : 'Fonte: acervo local',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: cs.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ),
                    if (answers.containsKey(id) && !examLocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: DropdownButton<String>(
                          value: errorTypes[id] ?? defaultErrorType,
                          hint: const Text('Tipo de erro se miss'),
                          items: [
                            for (final e in simulationErrorLabels.entries)
                              DropdownMenuItem(value: e.key, child: Text(e.value)),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            HapticFeedback.selectionClick();
                            onErrorTypeForQuestion(id, v);
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
