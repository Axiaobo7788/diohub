import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/misc/floating_glass_pill.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/view/settings/widgets/previews/mock_list_content.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contextual preview: app bar (floating pill or attached bar) over mini issue cards.
/// Differentiates from Surface preview by showing full app bar with back, title, star, share.
class AppBarPreview extends ConsumerWidget {
  const AppBarPreview({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AppearanceSettings appearance = ref.watch(appearanceProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool floating = appearance.appBarStyle == AppBarStyle.floating;

    return SizedBox(
      height: 140,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          const MockListContent(topPadding: 52),
          Positioned(
            top: floating ? 8 : 0,
            left: floating ? 16 : 0,
            right: floating ? 16 : 0,
            child: floating
                ? GlassPill(
                    style: GlassPillStyle(context),
                    isFloating: true,
                    child: _AppBarRow(colorScheme: colorScheme),
                  )
                : Container(
                    padding: context.spacing.cardContentPadding,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: _AppBarRow(colorScheme: colorScheme),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AppBarRow extends StatelessWidget {
  const _AppBarRow({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(Icons.arrow_back, size: 20, color: colorScheme.onSurface),
        context.spacing.itemGap,
        Expanded(
          child: Text(
            'octocat/Hello-World',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(Icons.star_border, size: 20, color: colorScheme.onSurfaceVariant),
        context.spacing.itemGap,
        Icon(Icons.share, size: 20, color: colorScheme.onSurfaceVariant),
      ],
    );
  }
}
