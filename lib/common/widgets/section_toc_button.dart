import 'package:diohub/common/misc/liquid_glass_wrapper.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A single entry for the section table-of-contents popup.
///
/// [level] is used for indent in the popup (e.g. 1 = no indent, 2 = one level).
class SectionTocEntry {
  const SectionTocEntry({
    required this.id,
    required this.title,
    this.icon,
    this.level = 1,
  });

  final String id;
  final String title;
  final IconData? icon;
  final int level;
}

/// A pill button that opens a popup listing [entries] and calls [onSelect] with
/// the selected entry's id. Shown only when [entries] is non-empty.
///
/// Used in the first sticky section header per screen ("On this page").
class SectionTocButton extends StatelessWidget {
  const SectionTocButton({
    required this.entries,
    required this.onSelect,
    this.label = 'On this page',
    this.icon,
    super.key,
  });

  final List<SectionTocEntry> entries;
  final void Function(String id) onSelect;
  final String label;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final IconData effectiveIcon = icon ?? Octicons.list_unordered;
    final AppSpacing spacing = context.spacing;

    return PopupButton(
      popupBuilder: (final BuildContext context, final onDismiss) =>
          LiquidGlassWrapper(
        size: RadiusSize.large,
        child: Padding(
          padding: EdgeInsets.all(spacing.itemSpacing),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: entries
                  .asMap()
                  .entries
                  .map((final MapEntry<int, SectionTocEntry> entry) {
                final int index = entry.key;
                final SectionTocEntry e = entry.value;
                final bool isLast = index == entries.length - 1;
                final double indent = (e.level - 1).clamp(0, 3) * 8.0;

                return TapFeedback(
                  onTap: () {
                    onSelect(e.id);
                    onDismiss();
                  },
                  borderRadius: BorderRadius.only(
                    bottomLeft:
                        isLast ? const Radius.circular(14) : Radius.zero,
                    bottomRight:
                        isLast ? const Radius.circular(14) : Radius.zero,
                  ),
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 16 + indent,
                      right: 16,
                      top: 10,
                      bottom: 10,
                    ),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: context.colorScheme.outline
                                    .withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                    ),
                    child: Row(
                      children: <Widget>[
                        if (e.icon != null) ...<Widget>[
                          Icon(
                            e.icon,
                            size: 16,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                          context.spacing.itemGap,
                        ],
                        Expanded(
                          child: Text(
                            e.title,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: e.level <= 2
                                  ? context.colorScheme.onSurface
                                  : context.colorScheme.onSurfaceVariant,
                              fontWeight: e.level == 1
                                  ? FontWeight.w600
                                  : e.level <= 3
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                              fontSize: e.level <= 2 ? 13 : 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      buttonBuilder: (final BuildContext context, final showMenu) =>
          TapFeedback(
        onTap: showMenu,
        child: Padding(
          padding: spacing.chipPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                effectiveIcon,
                size: 14,
                color: context.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: spacing.tightSpacing),
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
