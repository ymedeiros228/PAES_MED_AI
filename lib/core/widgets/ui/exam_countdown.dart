import 'package:flutter/material.dart';

import '../../data/study_prefs_providers.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_theme.dart';
import 'layout_tokens.dart';

/// Cartão compacto da contagem até a prova (barra lateral, Ajustes, Plano).
/// Recebe o [ExamCountdown] de `ref.watch(examCountdownProvider)` — a mesma
/// fonte usada no Início, então os números nunca se contradizem.
///
/// ```dart
/// ExamCountdownCard(
///   countdown: ref.watch(examCountdownProvider),
///   onSetDate: () => context.go('/configuracoes'),
/// )
/// ```
class ExamCountdownCard extends StatelessWidget {
  const ExamCountdownCard({
    required this.countdown,
    this.onSetDate,
    super.key,
  });

  final ExamCountdown countdown;

  /// Abre o lugar onde a data é definida (Ajustes). Mostrado quando não há
  /// data ou quando a prova já passou.
  final VoidCallback? onSetDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cd = countdown;
    final needsDate = !cd.hasDate || cd.isPast;

    Widget body;
    if (cd.isUpcoming || cd.isToday) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            cd.isToday ? 'Hoje' : '${cd.daysLeft}',
            style: AppFonts.display(
              fontSize: cd.isToday ? 22 : 28,
              fontWeight: FontWeight.w700,
              color: cs.primary,
              height: 1,
              letterSpacing: -0.5,
            ).copyWith(fontFeatures: AppFonts.tabular),
          ),
          const SizedBox(width: kGap12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cd.isToday ? 'é a prova. Boa prova!' : (cd.daysLeft == 1 ? 'dia até a prova' : 'dias até a prova'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface, height: 1.3),
                ),
                Text(
                  'PAES · ${cd.dateLabel}',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.f72, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                cd.isPast ? Icons.event_busy_rounded : Icons.event_rounded,
                size: 18,
                color: cs.tertiary,
              ),
              const SizedBox(width: kGap8),
              Expanded(
                child: Text(
                  cd.isPast ? 'Prova de ${cd.dateLabel} já passou' : 'Sem data da prova',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface, height: 1.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: kGap4),
          Text(
            cd.isPast ? 'Defina a data da próxima para voltar a contar.' : 'Defina para ver a contagem.',
            style: TextStyle(fontSize: 12, color: cs.onSurface.f72, height: 1.4),
          ),
        ],
      );
    }

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(kGap12, kGap12, kGap12, kGap12),
      decoration: BoxDecoration(
        color: needsDate ? cs.tertiaryContainer.withOpacity(0.35) : cs.primaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(kRadiusButton),
        border: Border.all(
          color: needsDate ? cs.tertiary.withOpacity(0.35) : cs.primary.withOpacity(0.25),
        ),
      ),
      child: body,
    );

    if (onSetDate == null || !needsDate) {
      return Semantics(label: cd.shortLabel, excludeSemantics: true, child: card);
    }
    return Semantics(
      button: true,
      label: '${cd.shortLabel}. Abrir Ajustes para definir a data.',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onSetDate,
          borderRadius: BorderRadius.circular(kRadiusButton),
          child: card,
        ),
      ),
    );
  }
}
