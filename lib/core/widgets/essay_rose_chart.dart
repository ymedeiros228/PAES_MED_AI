/// Widgets compartilhados de redação (radar + barras).
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'ui_kit.dart';

class EssayRoseChart extends StatefulWidget {
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
  State<EssayRoseChart> createState() => _EssayRoseChartState();
}

class _EssayRoseChartState extends State<EssayRoseChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final keys = widget.axes.isNotEmpty
        ? widget.axes
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
          height: widget.height,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              return RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      dataEntries: [
                        for (final key in keys)
                          RadarEntry(
                            value: () {
                              final raw = widget.averages[key];
                              final v = raw is num ? raw.toDouble() : 0.0;
                              return (v.clamp(0.0, 10.0)) * _anim.value;
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
                  ticksTextStyle: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5)),
                  tickCount: 5,
                  titleTextStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.8),
                  ),
                  getTitle: (index, angle) {
                    if (index < 0 || index >= keys.length) {
                      return const RadarChartTitle(text: '');
                    }
                    final key = keys[index];
                    final short = widget.labels[key]?.toString() ?? key;
                    return RadarChartTitle(
                      text: short.length > 12 ? '${short.substring(0, 10)}…' : short,
                    );
                  },
                  titlePositionPercentageOffset: 0.18,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Radar dos eixos (0–10) · treino local',
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        for (final key in keys)
          Builder(
            builder: (_) {
              final raw = widget.averages[key];
              final value = raw is num ? raw.toDouble() : null;
              final label = widget.labels[key]?.toString() ?? key;
              final t = value == null ? 0.0 : (value / 10.0).clamp(0.0, 1.0);
              final d = widget.deltas?[key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (d != null) ...[
                          DeltaChip(label: label.split(' ').first, delta: d),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          value == null ? '—' : value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedBuilder(
                        animation: _anim,
                        builder: (context, _) => LinearProgressIndicator(
                          value: t * _anim.value,
                          minHeight: 8,
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
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
