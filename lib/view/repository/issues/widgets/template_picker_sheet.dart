import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Bottom sheet to pick an issue template or blank issue.
class TemplatePickerSheet {
  TemplatePickerSheet._();

  /// Shows the sheet. Returns the selected template, or [null] for "Blank Issue".
  /// [templates] may be empty; [showBlankOption] adds a "Blank Issue" tile.
  static Future<RepoIssueTemplate?> show(
    BuildContext context, {
    required List<RepoIssueTemplate> templates,
    bool showBlankOption = true,
  }) async {
    return AppSheet.simple<RepoIssueTemplate?>(
      context,
      header: AppSheetHeader.text('Choose a template'),
      bodyBuilder: (BuildContext context, StateSetter setState) =>
          _TemplatePickerBody(
        templates: templates,
        showBlankOption: showBlankOption,
      ),
    );
  }
}

class _TemplatePickerBody extends StatelessWidget {
  const _TemplatePickerBody({
    required this.templates,
    required this.showBlankOption,
  });

  final List<RepoIssueTemplate> templates;
  final bool showBlankOption;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];

    for (final RepoIssueTemplate template
        in templates) {
      children.add(
        TapFeedback(
          onTap: () => Navigator.of(context)
              .pop<RepoIssueTemplate?>(template),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.screenPadding.left,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Octicons.file,
                      size: 18,
                      color: context.colorScheme.onSurfaceVariant.secondary,
                    ),
                    SizedBox(width: context.spacing.itemSpacing),
                    Expanded(
                      child: Text(
                        template.name,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (template.about != null && template.about!.isNotEmpty) ...[
                  context.spacing.tightGap,
                  Padding(
                    padding:
                        EdgeInsets.only(left: 18 + context.spacing.itemSpacing),
                    child: Text(
                      template.about!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant.secondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (showBlankOption) {
      children.add(
        TapFeedback(
          onTap: () => Navigator.of(context)
              .pop<RepoIssueTemplate?>(null),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.screenPadding.left,
              vertical: 12,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Octicons.plus,
                  size: 18,
                  color: context.colorScheme.onSurfaceVariant.secondary,
                ),
                SizedBox(width: context.spacing.itemSpacing),
                Expanded(
                  child: Text(
                    'Blank Issue',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
