import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart' show LabelFragment;
import 'package:diohub_models/models/issues/issue_model.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:diohub/utils/timeline/timeline_compound_data.dart'
    show TimelineLabelInfo;
import 'package:flutter/material.dart';

class IssueLabel extends StatelessWidget {
  IssueLabel(final Label label, {this.isRemoved = false, super.key})
      : name = label.name,
        color = label.color;

  IssueLabel.gql(final LabelFragment label, {this.isRemoved = false, super.key})
      : name = label.name,
        color = label.color;

  /// Build from raw name and color (e.g. from [TimelineLabelInfo]).
  const IssueLabel.fromNameColor(
    this.name,
    this.color, {
    this.isRemoved = false,
    super.key,
  });

  final String name;
  final String color;
  final bool isRemoved;

  @override
  Widget build(final BuildContext context) {
    final Color labelColor = tryParseHexColor(color, fallback: const Color(0xFFFFFFFF))!;
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    final Widget chip = Container(
      padding: context.spacing.chipPadding,
      decoration: BoxDecoration(
        color: labelColor.tintStrong,
        borderRadius: context.radius(RadiusSize.small),
        border: Border.all(
          color: labelColor.borderO,
        ),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              decoration: isRemoved ? TextDecoration.lineThrough : null,
              decorationColor: isRemoved ? textColor.muted : null,
              decorationThickness: isRemoved ? 1.5 : null,
            ),
      ),
    );

    if (isRemoved) {
      // Removed labels: reduced opacity with strikethrough
      return Opacity(
        opacity: 0.5,
        child: chip,
      );
    }

    return chip;
  }
}
