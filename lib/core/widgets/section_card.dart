import 'package:flutter/material.dart';

import 'ui_kit.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      padding: padding,
      child: child,
    );
  }
}
