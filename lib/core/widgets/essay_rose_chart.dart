/// Widgets compartilhados de redação (radar + barras).
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'ui_kit.dart';

class EssayRoseChart extends StatelessWidget {
  const EssayRoseChart({
    required this.axes,
    required this.averages,
    required this.labels,
    this.height = 220,
    this.deltas,
    super.key,
  });

  final List<String> axes;
  final Map<String, dynamic> averages;
  final Map<String, dynamic> labels;
  final Map<String, double>? deltas;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final keys = axes.isNotEmpty
        ? axes
        : const [
            'grammar',
            'cohesion',
            'coherence',
            'argumentation',
            'intervention',
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: RadarChart(
            RadarChartData(
              dataSets: [
                RadarDataSet(
                  dataEntries: [
                    for (final key in keys)
                      RadarEntry(
                        value: () {
                          final raw = averages[key];
                          final v = raw is num ? raw.toDouble() : 0.0;
                          return v.clamp(0.0, 10.0);
                        }(),
                      ),
                  ],
                  fillColor: cs.primary.withOpacity(0.18),
                  borderColor: cs.primary,
                  entryRadius: 2.5,
                  borderWidth: 2,
                ),
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: BorderSide(color: cs.outlineVariant),
              tickBorderData: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
              gridBorderData: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
              ticksTextStyle: Theme.of(context).textTheme.labelSmall,
              tickCount: 5,
              titleTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ) ??
                  const TextStyle(fontSize: 11),
              getTitle: (index, angle) {
                if (index < 0 || index >= keys.length) {
                  return const RadarChartTitle(text: '');
                }
                final key = keys[index];
                final short = labels[key]?.toString() ?? key;
                return RadarChartTitle(
                  text: short.length > 12 ? '${short.substring(0, 10)}…' : short,
                );
              },
              titlePositionPercentageOffset: 0.18,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Radar dos eixos (0–10) · treino local',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 12),
        for (final key in keys)
          Builder(
            builder: (_) {
              final raw = averages[key];
              final value = raw is num ? raw.toDouble() : null;
              final label = labels[key]?.toString() ?? key;
              final t = value == null ? 0.0 : (value / 10.0).clamp(0.0, 1.0);
              final d = deltas?[key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
                        if (d != null) ...[
                          DeltaChip(label: label.split(' ').first, delta: d),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          value == null ? '—' : value.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: t,
                        minHeight: 8,
                        backgroundColor: cs.surfaceContainerHighest,
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
