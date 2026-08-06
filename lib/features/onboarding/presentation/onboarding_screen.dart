import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app.dart';
import '../../../core/data/api_client.dart';
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

  @override
  void initState() {
    super.initState();
    examCtrl = TextEditingController(text: ref.read(examDateProvider));
  }

  @override
  void dispose() {
    examCtrl.dispose();
    super.dispose();
  }

  Future<void> _openFolder(String folder) async {
    try {
      final data = await apiClient.post('/api/library/open-folder', {'folder': folder});
      setState(() => folderMsg = 'Aberta: ${(data as Map)['path']}');
    } catch (_) {
      setState(() => folderMsg = 'Pasta indisponível agora. Depois: Ajustes ou Biblioteca.');
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

    final titles = ['Bem-vindo', 'Data da prova', 'Provas no PC', 'Seu dia a dia'];
    final bodies = [
      'Hub pessoal para Medicina na UEMA — acervo, sessão e revisão no seu ritmo.',
      'Calibra o plano e a contagem. Pode pular e definir depois em Ajustes.',
      'Importe 2024–26 na Biblioteca com um toque, ou abra as pastas e coloque os PDFs à mão.',
      'Hoje → Sessão ou Fila. Biblioteca se ainda faltar prova. Simulado quando quiser medir.',
    ];

    return Scaffold(
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
              if (step == 0) ...[
                const SizedBox(height: 10),
                Text(
                  'Sem prova no PC ainda? Depois do tour, comece pela Biblioteca (Semana 1).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.65)),
                ),
              ],
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.wb_sunny_outlined, size: 18),
                      label: const Text('Hoje'),
                      onPressed: () => _finish(path: '/dashboard'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.timer_outlined, size: 18),
                      label: const Text('Sessão'),
                      onPressed: () => _finish(path: '/sessao'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.auto_stories_outlined, size: 18),
                      label: const Text('Biblioteca'),
                      onPressed: () => _finish(path: '/biblioteca'),
                    ),
                  ],
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
                      onPressed: () async {
                        if (step == 1) {
                          final raw = examCtrl.text.trim();
                          if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
                            await ref.read(examDateProvider.notifier).setDate(raw);
                          }
                        }
                        setState(() => step++);
                      },
                      child: const Text('Continuar'),
                    )
                  else ...[
                    TextButton(
                      onPressed: () => _finish(skipExam: true, path: '/biblioteca'),
                      child: const Text('Biblioteca'),
                    ),
                    FilledButton(
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
    );
  }
}

/// Preferência simples de data da prova / modo foco.
class StudyPrefs {
  static const examDateKey = 'exam_date_iso';
  static const focusModeKey = 'focus_mode';
}
