import 'dart:async';

import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/misc/liquid_glass_wrapper.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder toolbar that loops minimise → collapsed so the user sees the
/// animation. When [AnimationPreset.none], shows only the collapsed pill.
class OnboardingToolbarPreview extends ConsumerStatefulWidget {
  const OnboardingToolbarPreview({super.key});

  @override
  ConsumerState<OnboardingToolbarPreview> createState() =>
      _OnboardingToolbarPreviewState();
}

class _OnboardingToolbarPreviewState
    extends ConsumerState<OnboardingToolbarPreview> {
  static const Duration _period = Duration(milliseconds: 2500);
  bool _showCollapsed = true;
  Timer? _timer;
  bool _timerStarted = false;

  void _maybeStartTimer() {
    if (_timerStarted) return;
    final AppearanceSettings appearance = ref.read(appearanceProvider);
    if (appearance.disableAnimations) return;
    _timerStarted = true;
    _timer = Timer.periodic(_period, (final _) {
      if (mounted) setState(() => _showCollapsed = !_showCollapsed);
    });
  }

  @override
  void initState() {
    super.initState();
    _maybeStartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final AppearanceSettings appearance = ref.watch(appearanceProvider);
    ref.listen(
      appearanceProvider.select((final a) => a.disableAnimations),
      (final prev, final next) {
        if (next) {
          _timer?.cancel();
          _timer = null;
          _timerStarted = false;
        } else {
          _maybeStartTimer();
        }
      },
    );
    if (appearance.disableAnimations) {
      return _buildCollapsedPill(context, ref);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showCollapsed
          ? _buildCollapsedPill(context, ref)
          : _buildMinimisedPill(context, ref),
    );
  }

  Widget _buildMinimisedPill(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<ViewerInfo?> viewerAsync = ref.watch(currentUserProvider);
    final ViewerInfo? viewer = viewerAsync.value;
    final String? avatarUrl = viewer?.avatarUrl.toString();

    final Widget child = avatarUrl != null && avatarUrl.isNotEmpty
        ? ClipOval(
            child: Image.network(
              avatarUrl,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (final _, final __, final ___) =>
                  _minimisedPlaceholder(context),
            ),
          )
        : _minimisedPlaceholder(context);

    return LiquidGlassWrapper(
      key: const ValueKey('minimised'),
      size: RadiusSize.medium,
      surfaceRenderingOverride: SurfaceRendering.blur,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: child,
      ),
    );
  }

  Widget _minimisedPlaceholder(final BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );

  Widget _buildCollapsedPill(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<ViewerInfo?> viewerAsync = ref.watch(currentUserProvider);
    final ViewerInfo? viewer = viewerAsync.value;
    final String name = viewer != null
        ? (viewer.name?.trim().isNotEmpty ?? false
            ? viewer.name!
            : viewer.login)
        : 'You';
    final String? subtitle = viewer != null
        ? (viewer.name?.trim().isNotEmpty ?? false ? '@${viewer.login}' : null)
        : null;
    final String? avatarUrl = viewer?.avatarUrl.toString();

    final Widget leading = avatarUrl != null && avatarUrl.isNotEmpty
        ? ProfileTile.login(
            avatarUrl: avatarUrl,
            userLogin: viewer!.login,
            padding: EdgeInsets.zero,
            size: 32,
            disableTap: true,
          )
        : _minimisedPlaceholder(context);

    final Row content = Row(
      key: const ValueKey('collapsed'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        leading,
        context.spacing.itemGap,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ],
    );

    return LiquidGlassWrapper(
      size: RadiusSize.medium,
      surfaceRenderingOverride: SurfaceRendering.blur,
      child: Padding(
        padding: context.spacing.cardContentPadding,
        child: content,
      ),
    );
  }
}
