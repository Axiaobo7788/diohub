import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Horizontal breadcrumb bar for code browser path (repo name + path segments).
/// Reuses wiki breadcrumb styling; last segment is emphasized.
class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({
    required this.repoName,
    required this.currentPath,
    required this.onSegmentTap,
    required this.onRootTap,
    super.key,
  });

  final String repoName;
  final String currentPath;
  final ValueChanged<int> onSegmentTap;
  final VoidCallback onRootTap;

  @override
  Widget build(BuildContext context) {
    final List<String> segments = currentPath
        .split('/')
        .where((String s) => s.isNotEmpty)
        .toList();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Padding(
      padding: context.spacing.screenPadding.copyWith(top: 8, bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _BreadcrumbSegment(
              label: repoName,
              icon: Octicons.file_directory,
              isLast: segments.isEmpty,
              onTap: onRootTap,
              scheme: scheme,
              textTheme: textTheme,
            ),
            for (int i = 0; i < segments.length; i++) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '/',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              _BreadcrumbSegment(
                label: segments[i],
                isLast: i == segments.length - 1,
                onTap: () => onSegmentTap(i),
                scheme: scheme,
                textTheme: textTheme,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbSegment extends StatelessWidget {
  const _BreadcrumbSegment({
    required this.label,
    required this.isLast,
    required this.onTap,
    required this.scheme,
    required this.textTheme,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool isLast;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...[
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          context.spacing.tightGap,
        ],
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: isLast ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (isLast) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
