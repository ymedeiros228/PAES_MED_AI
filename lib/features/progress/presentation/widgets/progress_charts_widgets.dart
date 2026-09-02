import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui_kit.dart';

double progressRelevoValue(Map<String, dynamic> peak) =>
    (peak['value'] as num?)?.toDouble() ?? 2.0;

double progressRelevoMax(Map<String, dynamic> peak) {
  final max = (peak['max'] as num?)?.toDouble();
  return max != null && max > 0 ? max : 10.0;
}

const _relevoValleyThreshold = 5.5;
const _relevoRowHeight = 42.0;
const _relevoStackBreakpoint = 420.0;

class ProgressReadableRelief extends StatelessWidget {
  const ProgressReadableRelief({
    required this.peaks,
    required this.progress,
  });

  final List<Map<String, dynamic>> peaks;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final ordered = [...peaks]
      ..sort(
        (a, b) => progressRelevoValue(b).compareTo(progressRelevoValue(a)),
      );
    final maxScale = ordered
        .map(progressRelevoMax)
        .fold<double>(0, (highest, value) => value > highest ? value : highest);
    final panelHeight = 88 + ordered.length * _relevoRowHeight;

    return Container(
      constraints: BoxConstraints(minHeight: panelHeight),
      padding: const EdgeInsets.all(kGap16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.navy,
            Color.alphaBlend(AppTheme.teal.f45, AppTheme.navy),
          ],
        ),
        borderRadius: BorderRadius.circular(kRadiusPanel),
        border: Border.all(color: AppTheme.teal.f55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Escala: 0–${maxScale.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: kGap8),
              Wrap(
                spacing: kGap12,
                runSpacing: kGap4,
                children: [
                  _ReliefLegend(
                    color: AppTheme.teal,
                    label: 'Ponto forte',
                  ),
                  _ReliefLegend(
                    color: AppTheme.sand,
                    label: 'Ponto a melhorar (< 5.5)',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: kGap12),
          for (final peak in ordered)
            _ReliefRow(
              label: peak['label']?.toString() ?? 'Eixo',
              value: progressRelevoValue(peak),
              max: progressRelevoMax(peak),
              progress: progress,
              trackColor: Colors.white.withOpacity(0.20),
            ),
        ],
      ),
    );
  }
}

class _ReliefLegend extends StatelessWidget {
  const _ReliefLegend({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(kRadiusMicro),
          ),
        ),
        const SizedBox(width: kGap4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.78),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ],
    );
  }
}

class _ReliefRow extends StatelessWidget {
  const _ReliefRow({
    required this.label,
    required this.value,
    required this.max,
    required this.progress,
    required this.trackColor,
  });

  final String label;
  final double value;
  final double max;
  final double progress;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final isValley = value < _relevoValleyThreshold;
    final barColor = isValley ? AppTheme.sand : AppTheme.teal;
    final ratio = (value / max).clamp(0.0, 1.0);
    final thresholdRatio = (_relevoValleyThreshold / max).clamp(0.0, 1.0);
    final note = '${value.toStringAsFixed(1)} de ${max.toStringAsFixed(0)}';

    return Semantics(
      label: 'Eixo $label, nota $note${isValley ? ', ponto a melhorar' : ', ponto forte'}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: kGap8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < _relevoStackBreakpoint;
            final labelWidget = Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.92),
                fontWeight: FontWeight.w700,
              ),
            );
            final bar = _ReliefBar(
              ratio: ratio,
              progress: progress,
              thresholdRatio: thresholdRatio,
              barColor: barColor,
              trackColor: trackColor,
            );
            final valueWidget = SizedBox(
              width: 42,
              child: Text(
                value.toStringAsFixed(1),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  labelWidget,
                  const SizedBox(height: kGap4),
                  Row(
                    children: [
                      Expanded(child: bar),
                      const SizedBox(width: kGap8),
                      valueWidget,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                SizedBox(width: 108, child: labelWidget),
                const SizedBox(width: kGap8),
                Expanded(child: bar),
                const SizedBox(width: kGap8),
                valueWidget,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReliefBar extends StatelessWidget {
  const _ReliefBar({
    required this.ratio,
    required this.progress,
    required this.thresholdRatio,
    required this.barColor,
    required this.trackColor,
  });

  final double ratio;
  final double progress;
  final double thresholdRatio;
  final Color barColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final thresholdOffset =
              (constraints.maxWidth * thresholdRatio).clamp(0.0, constraints.maxWidth - 2).toDouble();
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(kRadiusControl),
                ),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio * progress,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(kRadiusControl),
                  ),
                ),
              ),
              Positioned(
                left: thresholdOffset,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProgressSubjectBarChart extends StatelessWidget {
  const ProgressSubjectBarChart({required this.scores});

  final Map<String, double> scores;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.infinite,
      painter: _BarChartPainter(scores: scores, cs: cs),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.scores, required this.cs});

  final Map<String, double> scores;
  final ColorScheme cs;

  @override
  void paint(Canvas canvas, Size size) {
    final entries = scores.entries.toList();
    if (entries.isEmpty) return;

    const labelArea = 48.0;
    const valueArea = 20.0;
    final chartTop = valueArea;
    final chartBottom = size.height - labelArea;
    final chartHeight = chartBottom - chartTop;
    final chartWidth = size.width;
    final barCount = entries.length;
    final slotWidth = chartWidth / barCount;
    final barWidth = (slotWidth * 0.5).clamp(10.0, 52.0);

    // Grid horizontal tracejado
    final gridPaint = Paint()
      ..color = cs.onSurface.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var p = 25; p < 100; p += 25) {
      final y = chartBottom - (p / 100) * chartHeight;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(chartWidth, y);
      canvas.drawPath(path, gridPaint);
    }

    final axisPaint = Paint()
      ..color = cs.onSurface.withOpacity(0.2)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(0, chartBottom), Offset(chartWidth, chartBottom), axisPaint);

    final valueStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
    );
    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: cs.onSurface.withOpacity(0.7),
    );

    for (var i = 0; i < barCount; i++) {
      final entry = entries[i];
      final value = entry.value.clamp(0.0, 100.0);
      // Cor baseada no valor
      final baseColor = value > 70
          ? cs.primary
          : value >= 50
              ? cs.tertiary
              : cs.error;
      final barHeight = (value / 100) * chartHeight;
      final cx = slotWidth * i + slotWidth / 2;
      final left = cx - barWidth / 2;
      final top = chartBottom - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(8),
      );

      // Sombra suave
      final shadowPaint = Paint()
        ..color = baseColor.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left + 1, top + 2, barWidth, barHeight),
          const Radius.circular(8),
        ),
        shadowPaint,
      );

      // Barra com gradiente vertical
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor,
            baseColor.withOpacity(0.7),
          ],
        ).createShader(Rect.fromLTWH(left, top, barWidth, barHeight));
      canvas.drawRRect(rect, gradientPaint);

      // Brilho no topo
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      final highlightRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 2, top + 2, barWidth - 4, (barHeight * 0.3).clamp(4, 20)),
        const Radius.circular(6),
      );
      canvas.drawRRect(highlightRect, highlightPaint);

      final tpValue = TextPainter(
        text: TextSpan(text: '${value.toStringAsFixed(0)}%', style: valueStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tpValue.paint(
        canvas,
        Offset(cx - tpValue.width / 2, top - tpValue.height - 3),
      );

      canvas.save();
      canvas.translate(cx, chartBottom + 8);
      canvas.rotate(-0.785);
      final tpLabel = TextPainter(
        text: TextSpan(text: entry.key, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: labelArea);
      tpLabel.paint(canvas, Offset(0, 0));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.scores != scores || old.cs != cs;
}

// ============================================================
// Mega Plan 3 — Graficos de Progresso com fl_chart
// ============================================================

/// Grafico de linha: evolucao do acerto acumulado ao longo do tempo.
class ProgressEvolutionLineChart extends StatelessWidget {
  const ProgressEvolutionLineChart({required this.points});

  final List<Map<String, dynamic>> points;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (points.length < 2) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (final p in points) {
      final n = (p['n'] as num?)?.toDouble() ?? 0;
      final acc = ((p['accuracy'] as num?)?.toDouble() ?? 0) * 100;
      spots.add(FlSpot(n, acc.clamp(0, 100)));
    }
    final maxX = spots.last.x;
    final lineColor = cs.primary;

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: maxX,
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.onSurface.withOpacity(0.08),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (maxX / 5).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 25,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => cs.primary,
            tooltipRoundedRadius: 10,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              '${s.x.toInt()} questões\n${s.y.toStringAsFixed(1)}% acerto',
              TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            )).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: lineColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 5,
                color: lineColor,
                strokeWidth: 2.5,
                strokeColor: cs.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(0.25),
                  lineColor.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Donut chart: distribuicao dos tipos de erro.
class ProgressErrorTypeDonut extends StatelessWidget {
  const ProgressErrorTypeDonut({required this.errorTypes});

  final Map<String, dynamic> errorTypes;

  static const _labels = {
    'conceito': 'Conceito',
    'interpretacao': 'Interpretação',
    'calculo': 'Cálculo',
    'distracao': 'Distração',
    'tempo': 'Tempo',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = errorTypes.entries.where((e) => (e.value as num).toInt() > 0).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    final total = entries.fold(0, (sum, e) => sum + (e.value as num).toInt());
    final colors = <Color>[
      cs.error,
      cs.tertiary,
      cs.primary,
      cs.secondary,
      cs.outline,
    ];

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final value = (e.value as num).toDouble();
      final pct = (value / total * 100);
      final baseColor = colors[i % colors.length];
      sections.add(PieChartSectionData(
        value: value,
        color: baseColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor,
            baseColor.withOpacity(0.7),
          ],
        ),
        radius: 48,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 2),
          ],
        ),
        titlePositionPercentageOffset: 0.55,
        borderSide: BorderSide(
          color: cs.surface,
          width: 3,
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 38,
                    centerSpaceColor: cs.surface,
                    sectionsSpace: 4,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    colors[i % colors.length],
                                    colors[i % colors.length].withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors[i % colors.length].withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _labels[entries[i].key] ?? entries[i].key,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              '${entries[i].value}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: colors[i % colors.length],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Total: $total erros registrados',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mapa de calor: tópicos com menor acerto destacados por cor.
class ProgressWeakTopicsHeatmap extends StatelessWidget {
  const ProgressWeakTopicsHeatmap({required this.topics});

  final List<Map<String, dynamic>> topics;

  Color _colorFor(double acc, ColorScheme cs) {
    if (acc < 0.4) return cs.error.withOpacity(0.85);
    if (acc < 0.6) return cs.error.withOpacity(0.55);
    if (acc < 0.8) return cs.tertiary.withOpacity(0.65);
    return cs.primary.withOpacity(0.7);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = List<Map<String, dynamic>>.from(topics)
      ..sort((a, b) {
        final aa = (a['accuracy'] as num?)?.toDouble() ?? 1.0;
        final bb = (b['accuracy'] as num?)?.toDouble() ?? 1.0;
        return aa.compareTo(bb);
      });
    final display = sorted.take(12).toList();
    if (display.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: display.map((t) {
        final key = t['key']?.toString() ?? '';
        final parts = key.split('::');
        final subj = parts.isNotEmpty ? parts[0] : (t['subject']?.toString() ?? '');
        final topic = parts.length > 1 ? parts.sublist(1).join('::') : (t['topic']?.toString() ?? '');
        final acc = (t['accuracy'] as num?)?.toDouble() ?? 0;
        final n = (t['n'] as num?)?.toInt() ?? 0;
        final color = _colorFor(acc, cs);
        final isWeak = acc < 0.5;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    isWeak ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      subj,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                topic,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(acc * 100).toStringAsFixed(0)}% · $n resp.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}


class ProgressStudyHeatmapCard extends StatelessWidget {
  const ProgressStudyHeatmapCard({required this.insights});
  final Map<String, dynamic> insights;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final studyDays = (insights['studyDays'] as List?) ?? [];
    final trend = Map<String, dynamic>.from(insights['weeklyTrend'] as Map? ?? {});
    final streakInfo = Map<String, dynamic>.from(insights['streakInsight'] as Map? ?? {});
    final streak = streakInfo['streak'] ?? 0;

    return SurfacePanel(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: cs.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Sua semana',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                if (streak is int && streak > 0) ...[
                  Icon(Icons.local_fire_department_rounded, color: const Color(0xFFE8A04B), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$streak dias',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE8A04B),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Heatmap: 14 dias em grid
            if (studyDays.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final day in studyDays)
                    _HeatmapCell(
                      dayLabel: day['dayLabel']?.toString() ?? '',
                      studied: day['studied'] == true,
                      minutes: (day['minutes'] ?? 0) as int,
                    ),
                ],
              ),

            const SizedBox(height: 16),

            // Tendencia
            if (trend.isNotEmpty) ...[
              _ProgressTrendChip(trend: trend),
            ],
          ],
        ),
      ),
    );
  }
}


class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({required this.dayLabel, required this.studied, required this.minutes});
  final String dayLabel;
  final bool studied;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final intensity = studied ? (minutes / 30).clamp(0.3, 1.0) : 0.0;

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            gradient: studied
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.primary.withOpacity(intensity),
                      cs.primary.withOpacity(intensity * 0.7),
                    ],
                  )
                : null,
            color: studied ? null : cs.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
            boxShadow: studied
                ? [
                    BoxShadow(
                      color: cs.primary.withOpacity(intensity * 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: studied ? cs.onSurface.withOpacity(0.7) : cs.onSurface.withOpacity(0.35),
          ),
        ),
      ],
    );
  }
}


class _ProgressTrendChip extends StatelessWidget {
  const _ProgressTrendChip({required this.trend});
  final Map<String, dynamic> trend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = trend['trend']?.toString() ?? 'sem_dados';
    final msg = trend['message']?.toString() ?? '';

    final (icon, color) = switch (t) {
      'melhorou' => (Icons.trending_up_rounded, const Color(0xFF4CAF50)),
      'piorou' => (Icons.trending_down_rounded, cs.error),
      'estavel' => (Icons.trending_flat_rounded, cs.onSurface.withOpacity(0.5)),
      'novo' => (Icons.auto_awesome_rounded, cs.primary),
      _ => (Icons.info_outline_rounded, cs.onSurface.withOpacity(0.4)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
