import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class TutorTypingIndicator extends StatefulWidget {
  const TutorTypingIndicator({super.key});

  @override
  State<TutorTypingIndicator> createState() => _TutorTypingIndicatorState();
}

class _TutorTypingIndicatorState extends State<TutorTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = (_controller.value + i * 0.2) % 1.0;
                  final scale =
                      0.6 + 0.4 * (0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2));
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.4 + 0.4 * scale),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(width: 8),
            Text(
              'Pensando…',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.f55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
