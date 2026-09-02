import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/ui_kit.dart';
import 'simulation_widgets.dart';

/// Modos disponíveis fora do fluxo de prova.
const simulationModes = <(String, String, String, IconData)>[
  ('dia_prova', 'Simulado do dia', 'Cronômetro ligado, gabarito no final', Icons.timer_outlined),
  ('paes_realista', 'Simulado PAES', '60 questões no estilo UEMA, cronômetro 4h', Icons.assignment_turned_in),
  ('revisao', 'Revisão', 'O que já está na fila para revisar', Icons.replay_rounded),
  ('disciplina', 'Por disciplina', 'Escolha a matéria', Icons.menu_book_outlined),
];

/// Painel de configuração antes de iniciar um simulado.
class SimulationSetupPanel extends StatelessWidget {
  const SimulationSetupPanel({
    super.key,
    required this.mode,
    required this.subject,
    required this.limit,
    required this.starting,
    required this.showOtherModes,
    this.checkpointLoadError,
    this.startError,
    this.pendingCheckpoint,
    required this.onModeChanged,
    required this.onSubjectChanged,
    required this.onLimitChanged,
    required this.onShowOtherModesChanged,
    required this.onStart,
    required this.onReloadCheckpoint,
    required this.onDismissStartError,
    required this.onRestoreCheckpoint,
    required this.onClearCheckpoint,
  });

  final String mode;
  final String? subject;
  final int limit;
  final bool starting;
  final bool showOtherModes;
  final String? checkpointLoadError;
  final String? startError;
  final Map<String, dynamic>? pendingCheckpoint;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<int> onLimitChanged;
  final ValueChanged<bool> onShowOtherModesChanged;
  final VoidCallback onStart;
  final VoidCallback onReloadCheckpoint;
  final VoidCallback onDismissStartError;
  final VoidCallback onRestoreCheckpoint;
  final Future<void> Function() onClearCheckpoint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (checkpointLoadError != null)
          QuietEmpty(
            message: checkpointLoadError!,
            action: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onReloadCheckpoint();
              },
              child: const Text('Tentar'),
            ),
          ),
        if (startError != null)
          QuietEmpty(
            message: startError!,
            action: Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onDismissStartError();
                  },
                  child: const Text('Ok'),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go('/biblioteca');
                  },
                  child: const Text('Biblioteca'),
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
        if (pendingCheckpoint != null)
          SurfacePanel(
            margin: const EdgeInsets.only(bottom: 12),
            color: cs.tertiaryContainer.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulado em andamento',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Modo ${pendingCheckpoint!['mode'] ?? '—'} · '
                  '${(pendingCheckpoint!['answers'] as Map? ?? {}).length} respondida(s)',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onRestoreCheckpoint();
                      },
                      child: const Text('Continuar'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        await onClearCheckpoint();
                      },
                      child: const Text('Descartar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SectionLabel('Simulado do dia', hint: 'Recomendado · como no dia da prova'),
        SimulationModeCard(
          selected: mode == 'dia_prova',
          icon: Icons.timer_outlined,
          title: 'Simulado do dia',
          subtitle: 'Cronômetro ligado, gabarito no final',
          onTap: () {
            HapticFeedback.selectionClick();
            onModeChanged('dia_prova');
          },
        ),
        const SizedBox(height: 4),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          initiallyExpanded: showOtherModes || mode != 'dia_prova',
          onExpansionChanged: onShowOtherModesChanged,
          title: Text(
            'Outros modos',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
          ),
          children: [
            for (final m in simulationModes.where((e) => e.$1 != 'dia_prova'))
              SimulationModeCard(
                selected: mode == m.$1,
                icon: m.$4,
                title: m.$2,
                subtitle: m.$3,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onModeChanged(m.$1);
                },
              ),
          ],
        ),
        if (mode == 'disciplina') ...[
          const SizedBox(height: 8),
          DropdownMenu<String>(
            label: const Text('Disciplina'),
            onSelected: onSubjectChanged,
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
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Escolha a disciplina antes de iniciar.',
              style: TextStyle(fontSize: 13, color: cs.error),
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
          onChanged: (v) => onLimitChanged(v.round()),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: starting || (mode == 'disciplina' && (subject == null || subject!.isEmpty))
              ? null
              : onStart,
          icon: starting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: Text(
            starting
                ? 'Carregando questões…'
                : mode == 'dia_prova'
                    ? 'Começar simulado do dia'
                    : 'Iniciar simulado',
          ),
        ),
      ],
    );
  }
}
