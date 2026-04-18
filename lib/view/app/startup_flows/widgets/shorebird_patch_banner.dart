import 'package:diohub/common/animations/logo_progress_indicator.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/providers/shorebird/shorebird_update_provider.dart';
import 'package:diohub/providers/shorebird/shorebird_update_state.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Custom banner for Shorebird patch updates.
///
/// Displays the current patch state with the LogoProgressIndicator,
/// state-driven copy, and appropriate CTA buttons.
class ShorebirdPatchBanner extends ConsumerWidget {
  const ShorebirdPatchBanner({
    required this.onDismiss,
    required this.onAction,
    super.key,
  });

  final VoidCallback onDismiss;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ShorebirdPatchState> state =
        ref.watch(shorebirdUpdateProvider);

    return state.when(
      data: (ShorebirdPatchState patchState) => _buildBannerForState(
        context,
        patchState,
      ),
      loading: () => _buildBannerForState(
        context,
        const PatchDownloading(),
      ),
      error: (Object error, StackTrace _) => _buildBannerForState(
        context,
        PatchFailed(error.toString()),
      ),
    );
  }

  Widget _buildBannerForState(
    BuildContext context,
    ShorebirdPatchState state,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    late final String title;
    late final String subtitle;
    late final String actionLabel;
    late final Widget leadingWidget;

    switch (state) {
      case PatchAvailable():
        title = 'Update Available';
        subtitle = 'A small improvement is ready to download';
        actionLabel = 'Update Now';
        leadingWidget = LogoProgressIndicator(size: 28);
      case PatchDownloading():
        title = 'Downloading Update';
        subtitle = "This won't take long";
        actionLabel = 'Downloading...';
        leadingWidget = LogoProgressIndicator(size: 28);
      case PatchReadyToInstall():
        title = 'Update Ready';
        subtitle = 'Restart to apply improvements';
        actionLabel = 'Restart Now';
        leadingWidget = LogoProgressIndicator(size: 28, value: 1.0);
      case PatchFailed(:final String message):
        title = 'Update Failed';
        subtitle = message;
        actionLabel = 'Retry';
        leadingWidget = LogoProgressIndicator(size: 28, value: 0.0);
      case PatchUpToDate():
        return const SizedBox.shrink();
      case PatchUnavailable():
        return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: kStateDuration,
      switchInCurve: kStateCurve,
      switchOutCurve: kStateCurve,
      child: Card(
        key: ValueKey<String>(state.runtimeType.toString()),
        margin: EdgeInsets.fromLTRB(
          spacing.screenPadding.left,
          spacing.itemSpacing,
          spacing.screenPadding.right,
          spacing.itemSpacing,
        ),
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: spacing.cardContentPadding,
          child: Row(
            children: <Widget>[
              leadingWidget,
              SizedBox(width: spacing.itemSpacing),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: spacing.tightSpacing),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: spacing.itemSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        if (state is! PatchDownloading) ...<Widget>[
                          TextButton(
                            onPressed: onDismiss,
                            child: const Text('Later'),
                          ),
                          SizedBox(width: spacing.tightSpacing),
                        ],
                        FilledButton(
                          onPressed:
                              state is PatchDownloading ? null : onAction,
                          child: Text(actionLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (state is! PatchDownloading)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                  tooltip: 'Dismiss',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
