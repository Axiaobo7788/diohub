import 'package:diohub/common/misc/floating_glass_pill.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/view/settings/widgets/previews/mock_list_content.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contextual preview: glass pill (feed-style) over mini issue cards.
/// Reflects current surface rendering (glass/blur/solid) via [GlassPill].
class SurfaceGlassPreview extends ConsumerWidget {
  const SurfaceGlassPreview({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    ref.watch(appearanceProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 140,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          const MockListContent(topPadding: 52),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassPill(
              style: GlassPillStyle(context),
              isFloating: true,
              child: Padding(
                padding: context.spacing.cardContentPadding,
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    context.spacing.itemGap,
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'octocat',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Feed',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
