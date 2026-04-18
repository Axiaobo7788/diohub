import 'package:diohub/common/misc/floating_glass_pill.dart';
import 'package:diohub/common/widgets/metadata_rows.dart' show MetadataRow;
import 'package:diohub/common/widgets/sliver_expand_transition.dart'
    show SliverExpandTransition;
import 'package:diohub/common/wrappers/sticky_glass_header.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// A sliver that renders a sticky glass header with a title, followed by
/// a [SliverList] of child [MetadataRow]-style widgets.
///
/// Intended for use inside the pull-to-expand metadata area as a child of
/// [SliverExpandTransition].
///
/// ```dart
/// MetadataSectionSliver(
///   title: 'Authorship',
///   icon: Icons.person_outline_rounded,
///   children: [
///     MetadataRow(label: 'Author', child: Text('octocat')),
///     MetadataTimestampRow(timestamps: [...]),
///   ],
/// )
/// ```
class MetadataSectionSliver extends StatelessWidget {
  const MetadataSectionSliver({
    required this.title,
    required this.children,
    this.icon,
    this.subtitle,
    this.trailing,
    this.statRail,
    this.variant = MetadataSectionVariant.neutral,
    this.style,
    super.key,
  });

  /// Header title text.
  final String title;

  /// Optional leading icon shown before the title.
  final IconData? icon;

  /// Optional subtitle shown under the title.
  final String? subtitle;

  /// Optional trailing widget (e.g. "On this page" pill).
  final Widget? trailing;

  /// Optional top stat rail shown before [children].
  final Widget? statRail;

  /// Section visual variant.
  final MetadataSectionVariant variant;

  /// Glass pill styling. Defaults to [GlassPillStyle.metadataSection].
  final GlassPillStyle? style;

  /// The rows to display beneath the sticky header.
  final List<Widget> children;

  @override
  Widget build(final BuildContext context) {
    if (children.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final Color? restingColor = switch (variant) {
      MetadataSectionVariant.strong =>
        Theme.of(context).colorScheme.surfaceContainerHigh,
      MetadataSectionVariant.muted =>
        Theme.of(context).colorScheme.surfaceContainerLow,
      MetadataSectionVariant.neutral => null,
    };
    final GlassPillStyle effectiveStyle = style ??
        GlassPillStyle.metadataSection(context, restingColor: restingColor);

    return StickyGlassSection.withTitle(
      title: title,
      icon: icon,
      trailing: subtitle != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (trailing != null) trailing!,
                if (trailing != null) context.spacing.itemGap,
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            )
          : trailing,
      style: effectiveStyle,
      sliver: SliverList.list(
        children: <Widget>[
          if (statRail != null) statRail!,
          ...children,
        ],
      ),
    );
  }
}

enum MetadataSectionVariant {
  strong,
  neutral,
  muted,
}
