import 'package:diohub/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Stable header placeholder while the local account session is resolving.
class SettingsAccountHeaderPlaceholder extends StatelessWidget {
  const SettingsAccountHeaderPlaceholder({super.key});

  @override
  Widget build(final BuildContext context) {
    final Color color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 180,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 128,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

/// Keeps account loading and failure distinct from a confirmed signed-out
/// settings session without replacing the surrounding Settings shell.
class SettingsAccountBoundary extends StatelessWidget {
  const SettingsAccountBoundary({
    required this.loading,
    required this.onRetry,
    super.key,
  });

  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(final BuildContext context) {
    if (loading) {
      return const Center(
        key: ValueKey<String>('settings-account-loading'),
        child: SizedBox.square(
          dimension: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    }
    return Center(
      key: const ValueKey<String>('settings-account-error'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 44),
              const SizedBox(height: 16),
              Text(
                context.l10n.repoAccountStateLoadError,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                key: const ValueKey<String>('settings-account-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
