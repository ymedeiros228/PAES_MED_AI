import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Aviso suave se ainda não há provas oficiais. Some quando base está ok.
class TrainingBasisBanner extends StatefulWidget {
  const TrainingBasisBanner({
    super.key,
    this.basis,
    this.officialCount,
    this.message,
    this.showLibraryCta = true,
    this.areaKey = 'global',
  });

  final String? basis;
  final int? officialCount;
  final String? message;
  final bool showLibraryCta;
  final String areaKey;

  @override
  State<TrainingBasisBanner> createState() => _TrainingBasisBannerState();
}

class _TrainingBasisBannerState extends State<TrainingBasisBanner> {
  bool? dismissed;

  bool get isTraining =>
      (widget.officialCount ?? 0) < 10 || (widget.basis ?? 'treino') != 'oficial';

  String get _prefsKey => 'demo_ack_${widget.areaKey}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => dismissed = p.getBool(_prefsKey) ?? false);
  }

  Future<void> _ack() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefsKey, true);
    if (mounted) setState(() => dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Com base oficial suficiente: silêncio total.
    if (!isTraining) return const SizedBox.shrink();
    if (dismissed == true) return const SizedBox.shrink();
    if (dismissed == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.tertiaryContainer.f55,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Icon(Icons.school_outlined, color: cs.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ainda no modo treino',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Importe provas UEMA na Biblioteca para estatísticas reais.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: cs.onTertiaryContainer.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showLibraryCta)
                TextButton(
                  onPressed: () => context.go('/biblioteca'),
                  child: const Text('Biblioteca'),
                ),
              TextButton(onPressed: _ack, child: const Text('Ok')),
            ],
          ),
        ),
      ),
    );
  }
}
