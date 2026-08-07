import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app.dart';
import '../../../core/data/api_client.dart';
import '../../../core/data/api_error.dart';
import '../../../core/data/study_prefs_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int step = 0;
  late final TextEditingController examCtrl;
  String? folderMsg;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    examCtrl = TextEditingController(text: ref.read(examDateProvider).date);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    examCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    if (step == 1) {
      final raw = examCtrl.text.trim();
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
        await ref.read(examDateProvider.notifier).setDate(raw);
      }
    }
    if (step < 3) {
      setState(() => step++);
      return;
    }
    await _finish(path: '/dashboard');
  }

  void _back() {
    if (step > 0) setState(() => step--);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary.context?.widget is EditableText) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _back();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      unawaited(_advance());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _openFolder(String folder) async {
    try {
      final data = await apiClient.post('/api/library/open-folder', {'folder': folder});
      setState(() => folderMsg = 'Aberta: ${(data as Map)['path']}');
    } catch (e) {
      setState(
        () => folderMsg = humanApiError(e, fallback: 'Pasta indisponível — use Biblioteca depois.'),
      );
    }
  }

  Future<void> _finish({bool skipExam = false, String path = '/dashboard'}) async {
    final raw = examCtrl.text.trim();
    if (!skipExam && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      await ref.read(examDateProvider.notifier).setDate(raw);
    }
    await ref.read(focusModeProvider.notifier).setFocus(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done_v1', true);
    await prefs.setBool('first_run_coach_pending', true);
    notifyOnboardingFinished();
    if (mounted) context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final examState = ref.watch(examDateProvider);

    final titles = ['Bem-vindo', 'Data da prova', 'Provas no PC', 'Seu dia a dia'];
    final bodies = [
      'Hub pessoal para Medicina na UEMA — acervo, sessão e revisão no seu ritmo.',
      'Calibra o plano e a contagem. Pode pular e definir depois em Ajustes.',
      'Importe 2024–26 na Biblioteca (Atualizar 2024–26) ou abra as pastas e coloque os PDFs à mão.',
      'Semana 1 na Biblioteca → depois Hoje ou Sessão. Simulado quando quiser medir.',
    ];

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PAES MED AI',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'Medicina · PAES/UEMA',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.primary),
              ),
              const Spacer(),
              Icon(
                [Icons.school_rounded, Icons.event_rounded, Icons.folder_open_rounded, Icons.flag_rounded][step],
                size: 56,
                color: cs.primary,
              ),
              const SizedBox(height: 16),
              Text(titles[step], style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(bodies[step], style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4)),
              Text(
                '← volta · → ou Enter avança',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.5)),
              ),
              if (step == 1) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: examCtrl,
                  decoration: const InputDecoration(
                    labelText: 'AAAA-MM-DD',
                    hintText: '2026-12-01',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (examState.hydrateNote != null && examCtrl.text.trim().isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    examState.hydrateNote!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.tertiary),
                  ),
                ],
                if (examState.syncError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    examState.syncError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error),
                  ),
                ],
              ],
              if (step == 2) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(onPressed: () => _openFolder('provas'), child: const Text('Provas')),
                    FilledButton.tonal(onPressed: () => _openFolder('gabaritos'), child: const Text('Gabaritos')),
                    OutlinedButton(onPressed: () => _openFolder('edital'), child: const Text('Edital')),
                  ],
                ),
                if (folderMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(folderMsg!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
              if (step == 3) ...[
                const SizedBox(height: 16),
                // Mini preview do painel Biblioteca (mock estático)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Na Biblioteca você verá',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _MiniLibRow(year: '2024', status: 'Pronto · Estudar'),
                      _MiniLibRow(year: '2025', status: 'Pronto · Estudar'),
                      _MiniLibRow(year: '2026', status: 'Atualizar se faltar'),
                      const SizedBox(height: 6),
                      Text(
                        'Painel Semana 1 · oficiais 2024–26 · sem inventar ano ausente',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: i == step ? 22 : 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: i == step ? cs.primary : cs.outlineVariant,
                      ),
                    ),
                  const Spacer(),
                  if (step == 1)
                    TextButton(onPressed: () => setState(() => step++), child: const Text('Pular data')),
                  if (step < 3)
                    FilledButton(
                      onPressed: _advance,
                      child: const Text('Continuar (Enter)'),
                    )
                  else ...[
                    FilledButton(
                      onPressed: () => _finish(skipExam: true, path: '/biblioteca?semana1=1'),
                      child: const Text('Semana 1 (Biblioteca)'),
                    ),
                    TextButton(
                      onPressed: () => _finish(path: '/dashboard'),
                      child: const Text('Ir ao Hoje'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _MiniLibRow extends StatelessWidget {
  const _MiniLibRow({required this.year, required this.status});
  final String year;
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(year, style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(status, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Preferência simples de data da prova / modo foco.
class StudyPrefs {
  static const examDateKey = 'exam_date_iso';
  static const focusModeKey = 'focus_mode';
}
