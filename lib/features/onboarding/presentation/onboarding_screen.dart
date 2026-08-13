import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app.dart';
import '../../../core/data/study_prefs_providers.dart';

/// Onboarding de primeira execução.
///
/// Visual: hero gradiente animado + card flutuante + seletor de data
/// elegante + preview de features. Tela única, direta e convidativa.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  DateTime? _examDate;
  bool _saving = false;
  int _dailyGoal = 60;
  int _studyStart = 8;
  int _studyEnd = 22;
  List<int> _studyDays = [2, 3, 4, 5, 6];

  late final AnimationController _bgCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _featureCtrl;
  late final Animation<double> _bgAnim;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _featureFade;

  @override
  void initState() {
    super.initState();

    // Background: rotação lenta do gradiente (loop 20s)
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.linear);

    // Card: fade + slide up (entrada)
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardFade = CurvedAnimation(
        parent: _cardCtrl, curve: Curves.easeOutCubic);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _cardCtrl, curve: Curves.easeOutCubic));

    // Features: fade escalonado (depois do card)
    _featureCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _featureFade = CurvedAnimation(
        parent: _featureCtrl, curve: Curves.easeOutCubic);

    // Sequência: card → features
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _featureCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    _featureCtrl.dispose();
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

  Future<void> _finish() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    if (_examDate != null) {
      final iso =
          '${_examDate!.year}-${_examDate!.month.toString().padLeft(2, '0')}-${_examDate!.day.toString().padLeft(2, '0')}';
      await ref.read(examDateProvider.notifier).setDate(iso);
    }
    await ref.read(dailyGoalProvider.notifier).setGoal(_dailyGoal);
    await ref.read(studyHoursProvider.notifier).setHours(_studyStart, _studyEnd);
    await ref.read(studyDaysProvider.notifier).setDays(_studyDays);
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnim,
        builder: (context, _) {
          // Gradiente rotativo: dois pontos que se movem em circulo
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
                        const Color(0xFF08202E),
                      ]
                    : [
                        const Color(0xFF0B1F33),
                        const Color(0xFF0F6B5C),
                        const Color(0xFF148F78),
                      ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 500 : double.infinity,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),

                            // ===== HERO =====
                            _HeroHeader(),

                            const SizedBox(height: 32),

                            // ===== CARD PRINCIPAL =====
                            FadeTransition(
                              opacity: _cardFade,
                              child: SlideTransition(
                                position: _cardSlide,
                                child: _MainCard(
                                  examDate: _examDate,
                                  dateLabel: _dateLabel,
                                  daysLeft: _daysLeft,
                                  saving: _saving,
                                  onPickDate: _pickDate,
                                  onFinish: _finish,
                                  cs: cs,
                                  dailyGoal: _dailyGoal,
                                  onGoalChanged: (g) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _dailyGoal = g);
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ===== FEATURES PREVIEW =====
                            FadeTransition(
                              opacity: _featureFade,
                              child: _FeaturesRow(),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// HERO: logo + título + subtítulo com brilho sutil
// ============================================================
class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ícone em círculo com brilho
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        // Título
        Text(
          'PAES MED AI',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.1,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Subtítulo
        Text(
          'Medicina · UEMA',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.8),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CARD PRINCIPAL: boas-vindas + seletor de data + CTA
// ============================================================
class _MainCard extends StatelessWidget {
  const _MainCard({
    required this.examDate,
    required this.dateLabel,
    required this.daysLeft,
    required this.saving,
    required this.onPickDate,
    required this.onFinish,
    required this.cs,
    required this.dailyGoal,
    required this.onGoalChanged,
  });

  final DateTime? examDate;
  final String dateLabel;
  final int daysLeft;
  final bool saving;
  final VoidCallback onPickDate;
  final VoidCallback onFinish;
  final ColorScheme cs;
  final int dailyGoal;
  final ValueChanged<int> onGoalChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Badge "Bem-vindo"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.waving_hand_rounded,
                    color: AppTheme.teal, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Bem-vindo!',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Descrição
          Text(
            'Seu assistente de estudos para a prova de '
            'Medicina da UEMA.',
            textAlign: TextAlign.left,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Questões oficiais, flashcards, tutor com IA e '
            'simulados — tudo em um lugar.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurface.withOpacity(0.7),
              height: 1.55,
            ),
          ),

          const SizedBox(height: 24),

          // Divisor
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Seletor de data
          Text(
            'Quando é a sua prova?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Opcional — você pode mudar depois em Ajustes',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 14),

          // Botão seletor de data
          InkWell(
            onTap: saving ? null : onPickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 18),
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
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: examDate == null
                                ? cs.onSurface.withOpacity(0.5)
                                : cs.onSurface,
                          ),
                        ),
                        if (examDate != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: daysLeft > 0
                                    ? AppTheme.teal
                                    : cs.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                daysLeft > 0
                                    ? '$daysLeft dias restantes'
                                    : 'Data no passado',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: daysLeft > 0
                                      ? AppTheme.teal
                                      : cs.error,
                                ),
                              ),
                            ],
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

          const SizedBox(height: 28),

          // CTA
          SizedBox(
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
                          'Começar a estudar',
                          style: GoogleFonts.inter(
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
    );
  }
}

// ============================================================
// FEATURES: 3 cards com ícone + label
// ============================================================
class _FeaturesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FeatureCard(
            icon: Icons.quiz_rounded,
            title: 'Questões',
            subtitle: 'Oficiais UEMA',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FeatureCard(
            icon: Icons.style_rounded,
            title: 'Flashcards',
            subtitle: 'Revisão espaçada',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FeatureCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Tutor IA',
            subtitle: 'Dúvidas na hora',
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}
