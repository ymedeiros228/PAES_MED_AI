import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../features/settings/data/update_provider.dart';

class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final update = ref.watch(updateCheckProvider);

    if (update.checking || !update.hasUpdate) return const SizedBox.shrink();
    if (update.latestVersion == null) return const SizedBox.shrink();

    return TapScale(
      child: Material(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/atualizacoes'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.tertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.new_releases_rounded, color: cs.onTertiary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atualização disponível',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onTertiaryContainer),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nova versão ${update.latestVersion!} está disponível. Toque para atualizar.',
                        style: TextStyle(fontSize: 13, color: cs.onTertiaryContainer.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: cs.onTertiaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
