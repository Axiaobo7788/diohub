import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/misc/liquid_glass_wrapper.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/view/onboarding/widgets/onboarding_preview_data.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared home preview: toolbar pill + octocat repo card. Used by all onboarding
/// sections and can be reused in Settings theme preview.
class OnboardingHomePreview extends ConsumerWidget {
  const OnboardingHomePreview({
    required this.toolbarBuilder,
    this.surfaceRendering,
    this.codeSnippet,
    super.key,
  });

  final Widget toolbarBuilder;
  final SurfaceRendering? surfaceRendering;
  final Widget? codeSnippet;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Z-order: repo card behind, glass pill in front (overlapping top of card).
    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const OnboardingPlaceholderRepoCard(),
            if (codeSnippet != null) ...<Widget>[
              context.spacing.contentGap,
              codeSnippet!,
            ],
          ],
        ),
        toolbarBuilder,
      ],
    );
  }
}

/// Static collapsed pill with viewer avatar + name. Use for Theme, Surface, Code.
class CollapsedPillPreview extends ConsumerWidget {
  const CollapsedPillPreview({
    this.surfaceRendering,
    super.key,
  });

  final SurfaceRendering? surfaceRendering;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<ViewerInfo?> viewerAsync =
        ref.watch(currentUserProvider);
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

    final leading = avatarUrl != null && avatarUrl.isNotEmpty
        ? ProfileTile.login(
            avatarUrl: avatarUrl,
            userLogin: viewer!.login,
            padding: EdgeInsets.zero,
            size: 32,
            disableTap: true,
          )
        : CircleAvatar(
            radius: 16,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );

    final Row content = Row(
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
      surfaceRenderingOverride: surfaceRendering ?? SurfaceRendering.blur,
      child: Padding(
        padding: context.spacing.cardContentPadding,
        child: content,
      ),
    );
  }
}
