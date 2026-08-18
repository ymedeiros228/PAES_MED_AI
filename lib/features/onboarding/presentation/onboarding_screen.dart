import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app.dart';
import '../../../core/data/study_prefs_providers.dart';

/// Onboarding de 3 telas: Bem-vindo, Data da prova, Pronto.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  DateTime? _examDate;
  bool _saving = false;

  late final AnimationController _bgCtrl;
  late final Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      helpText: 'Quando é a sua prova?',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        final cs = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: cs.copyWith(
              primary: AppTheme.teal,
              onPrimary: Colors.white,
              surface: cs.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _examDate = picked);
    }
  }

  void _nextPage() {
    HapticFeedback.selectionClick();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    if (_examDate != null) {
      final iso =
          '${_examDate!.year}-${_examDate!.month.toString().padLeft(2, '0')}-${_examDate!.day.toString().padLeft(2, '0')}';
      await ref.read(examDateProvider.notifier).setDate(iso);
    }
    await ref.read(dailyGoalProvider.notifier).setGoal(60);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done_v1', true);
    await prefs.setBool('onboarding_done_v2', true);
    await prefs.setBool('first_run_coach_pending', true);
    notifyOnboardingFinished();
    if (mounted) context.go('/dashboard');
  }

  String get _dateLabel {
    if (_examDate == null) return 'Toque para escolher a data';
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return '${_examDate!.day} de ${months[_examDate!.month - 1]} de ${_examDate!.year}';
  }

  int get _daysLeft {
    if (_examDate == null) return 0;
    return _examDate!.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnim,
        builder: (context, _) {
          final t = _bgAnim.value * 2 * math.pi;
          final x1 = 0.5 + 0.3 * math.cos(t);
          final y1 = 0.3 + 0.2 * math.sin(t);
          final x2 = 0.5 + 0.3 * math.cos(t + math.pi);
          final y2 = 0.7 + 0.2 * math.sin(t + math.pi);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(x1, y1),
                end: Alignment(x2, y2),
                colors: isDark
                    ? [
                        const Color(0xFF061224),
                        const Color(0xFF0A3D35),
                      ]
                    : [
                        const Color(0xFFE8F5F3),
                        const Color(0xFFD4ECE6),
                      ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Indicador de páginas (pontos)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.teal
                                : AppTheme.teal.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Páginas
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      children: [
                        _WelcomePage(onNext: _nextPage),
                        _DatePage(
                          examDate: _examDate,
                          dateLabel: _dateLabel,
                          daysLeft: _daysLeft,
                          onPickDate: _pickDate,
                          onNext: _nextPage,
                        ),
                        _ReadyPage(
                          daysLeft: _daysLeft,
                          hasDate: _examDate != null,
                          saving: _saving,
                          onFinish: _finish,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// Tela 1: Bem-vindo
// ============================================================
class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.teal, AppTheme.teal.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.teal.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                size: 52,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'PAES MED AI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seu caminho para Medicina UEMA',
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            // Features
            _FeatureItem(
              icon: Icons.menu_book_rounded,
              title: '92 materiais de estudo',
              subtitle: 'PDFs organizados por disciplina',
              cs: cs,
            ),
            const SizedBox(height: 16),
            _FeatureItem(
              icon: Icons.quiz_rounded,
              title: '657 questões',
              subtitle: 'Oficiais da UEMA + geradas',
              cs: cs,
            ),
            const SizedBox(height: 16),
            _FeatureItem(
              icon: Icons.smart_toy_rounded,
              title: 'Tutor com IA',
              subtitle: 'Tire dúvidas enquanto estuda',
              cs: cs,
            ),
            const SizedBox(height: 40),
            // Botão
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Começar',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Tela 2: Data da prova
// ============================================================
class _DatePage extends StatelessWidget {
  const _DatePage({
    required this.examDate,
    required this.dateLabel,
    required this.daysLeft,
    required this.onPickDate,
    required this.onNext,
  });
  final DateTime? examDate;
  final String dateLabel;
  final int daysLeft;
  final VoidCallback onPickDate;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 64,
              color: AppTheme.teal,
            ),
            const SizedBox(height: 24),
            Text(
              'Quando é a sua prova?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Opcional — você pode mudar depois em Ajustes',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.55),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Botão seletor de data
            InkWell(
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: examDate != null
                      ? AppTheme.teal.withOpacity(0.08)
                      : cs.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: examDate != null
                        ? AppTheme.teal.withOpacity(0.4)
                        : cs.outlineVariant,
                    width: examDate != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: examDate != null
                            ? AppTheme.teal
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        examDate != null
                            ? Icons.event_available_rounded
                            : Icons.calendar_today_rounded,
                        color: examDate != null
                            ? Colors.white
                            : cs.onSurface.withOpacity(0.5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: examDate == null
                                  ? cs.onSurface.withOpacity(0.5)
                                  : cs.onSurface,
                            ),
                          ),
                          if (examDate != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              daysLeft > 0
                                  ? '$daysLeft dias restantes'
                                  : 'Data no passado',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: daysLeft > 0
                                    ? AppTheme.teal
                                    : cs.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurface.withOpacity(0.35),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  examDate != null ? 'Próximo' : 'Pular por agora',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Tela 3: Pronto
// ============================================================
class _ReadyPage extends StatelessWidget {
  const _ReadyPage({
    required this.daysLeft,
    required this.hasDate,
    required this.saving,
    required this.onFinish,
  });
  final int daysLeft;
  final bool hasDate;
  final bool saving;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Check animado
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.teal,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.teal.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Tudo configurado!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (hasDate && daysLeft > 0) ...[
              Text(
                '$daysLeft',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.teal,
                  height: 1.0,
                ),
              ),
              Text(
                'dias até a prova',
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              Text(
                'Bem-vindo ao PAES MED AI',
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: saving ? null : onFinish,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Estudar agora',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Widget auxiliar: item de feature
// ============================================================
class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cs,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.teal, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
