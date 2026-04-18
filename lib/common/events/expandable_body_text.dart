import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A text widget that truncates to [maxLines] and shows a "Show more" control
/// that expands inline to show the full content (no popup).
///
/// Used for event body text (release notes, review comments, discussion body)
/// where the full content is too long for inline display.
///
/// If the text fits within [maxLines], no expand control is shown.
class ExpandableBodyText extends StatefulWidget {
  const ExpandableBodyText({
    required this.text,
    this.maxLines = 3,
    this.title,
    this.textStyle,
    super.key,
  });

  /// The full body text to display.
  final String text;

  /// Maximum lines before truncation + inline expand. Defaults to 3.
  final int maxLines;

  /// Optional title (unused in inline mode; kept for API compatibility).
  final String? title;

  /// Optional text style override.
  final TextStyle? textStyle;

  @override
  State<ExpandableBodyText> createState() => _ExpandableBodyTextState();
}

class _ExpandableBodyTextState extends State<ExpandableBodyText> {
  bool _expanded = false;

  @override
  Widget build(final BuildContext context) {
    final TextStyle? effectiveStyle =
        widget.textStyle ?? Theme.of(context).textTheme.bodySmall;

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        // Measure if text overflows within maxLines.
        final TextSpan span =
            TextSpan(text: widget.text, style: effectiveStyle);
        final TextPainter tp = TextPainter(
          text: span,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final bool overflows = tp.didExceedMaxLines;
        tp.dispose();

        if (!overflows && !_expanded) {
          return Text(widget.text, style: effectiveStyle);
        }

        if (overflows && !_expanded) {
          return TapFeedback(
            onTap: () => setState(() => _expanded = true),
            borderRadius: context.radius(RadiusSize.small),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.text,
                  maxLines: widget.maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: effectiveStyle,
                ),
                context.spacing.tightGap,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Octicons.unfold,
                      size: 12,
                      color: context.colorScheme.primary,
                    ),
                    context.spacing.tightGap,
                    Text(
                      'Show more',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(widget.text, style: effectiveStyle),
            context.spacing.tightGap,
            TapFeedback(
              onTap: () => setState(() => _expanded = false),
              borderRadius: context.radius(RadiusSize.small),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Octicons.fold,
                    size: 12,
                    color: context.colorScheme.primary,
                  ),
                  context.spacing.tightGap,
                  Text(
                    'Show less',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
