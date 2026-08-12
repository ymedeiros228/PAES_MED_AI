import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app.dart';
import '../../../core/data/study_prefs_providers.dart';

/// Onboarding de primeira execução — tela única, simples e direta.
/// Pede apenas a data da prova (opcional) e segue para o dashboard.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  DateTime? _examDate;
  bool _saving = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      helpText: 'Data da prova',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _examDate = picked);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    if (_examDate != null) {
      final iso =
          '${_examDate!.year}-${_examDate!.month.toString().padLeft(2, '0')}-${_examDate!.day.toString().padLeft(2, '0')}';
      await ref.read(examDateProvider.notifier).setDate(iso);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done_v1', true);
    await prefs.setBool('first_run_coach_pending', true);
    notifyOnboardingFinished();
    if (mounted) context.go('/dashboard');
  }

  String get _dateLabel {
    if (_examDate == null) return 'Toque para escolher';
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
    final bright = Theme.of(context).brightness;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient(bright),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 480 : double.infinity,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),

                        // Logo / título
                        Text(
                          'PAES MED AI',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Medicina · UEMA',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.75),
                            letterSpacing: 0.3,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Card principal
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Bem-vindo!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Seu assistente de estudos para a prova de '
                                'Medicina da UEMA. Questões oficiais, '
                                'flashcards, tutor com IA e simulados — '
                                'tudo em um lugar.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: cs.onSurface.withOpacity(0.75),
                                  height: 1.55,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Seletor de data
                              Text(
                                'Quando é a sua prova?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Opcional — você pode mudar depois em Ajustes',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(0.55),
                                ),
                              ),
                              const SizedBox(height: 16),

                              InkWell(
                                onTap: _saving ? null : _pickDate,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest
                                        .withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: cs.outlineVariant),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.event_rounded,
                                          color: cs.primary, size: 24),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _dateLabel,
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: _examDate == null
                                                    ? cs.onSurface
                                                        .withOpacity(0.5)
                                                    : cs.onSurface,
                                              ),
                                            ),
                                            if (_examDate != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                _daysLeft > 0
                                                    ? '$_daysLeft dias restantes'
                                                    : 'Data no passado',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: _daysLeft > 0
                                                      ? cs.primary
                                                      : cs.error,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded,
                                          color: cs.onSurface.withOpacity(0.4)),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // CTA
                              FilledButton(
                                onPressed: _saving ? null : _finish,
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Começar a estudar',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Features preview
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FeatureChip(
                                icon: Icons.quiz_rounded, label: 'Questões'),
                            _FeatureChip(
                                icon: Icons.style_rounded, label: 'Flashcards'),
                            _FeatureChip(
                                icon: Icons.auto_awesome_rounded,
                                label: 'Tutor IA'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.85), size: 28),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
