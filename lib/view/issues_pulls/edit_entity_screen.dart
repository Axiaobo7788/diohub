/// Base class for edit screens (Issue and Pull Request).
///
/// Extracts shared state fields, initialization pattern, and ComposeScaffold structure.
/// Subclasses provide entity-specific loading, config building, and metadata widgets.
library;

import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/compose/compose_scaffold.dart';
import 'package:diohub/common/compose/editor/markdown_live_text_field.dart';
import 'package:diohub/common/compose/models/compose_config.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/view/issues_pulls/widgets/milestone_select_sheet.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base state for edit screens (Issue and PR).
abstract class EditEntityScreenState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> {
  late String title;
  late String body;
  late List<String> labelIds;
  late List<String> assigneeIds;
  String? milestoneId;
  bool initialized = false;

  /// Repository reference for this entity.
  RepoRef get repoRef;

  /// Entity-specific config for ComposeScaffold.
  ComposeConfig buildConfig();

  /// Load the entity data asynchronously and trigger UI rebuild.
  Widget buildAsync(BuildContext context);

  /// Optional metadata widgets above the main body (e.g., state toggle, base branch).
  List<Widget> buildMetadataWidgets(BuildContext context);

  /// Entity title for error messages (e.g., "Issue", "Pull Request").
  String get entityTitle;

  @override
  Widget build(BuildContext context) => buildAsync(context);

  /// Standard content layout with ComposeScaffold.
  Widget buildContent() {
    final config = buildConfig();

    return ComposeScaffold(
      config: config,
      metadataBuilder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...buildMetadataWidgets(context),
          InkWell(
            onTap: () async {
              await AppSheet.scrollable<void>(
                context,
                header: AppSheetHeader.text('Milestone'),
                bodyBuilder: (ctx, setState, scrollController) =>
                    MilestoneSelectSheet(
                  scrollController: scrollController,
                  repoRef: repoRef,
                  initialMilestoneId: milestoneId,
                  onSelected: (id) {
                    setState(() => milestoneId = id);
                  },
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Chip(
              label: Text(
                milestoneId == null ? 'Milestone' : 'Milestone selected',
              ),
            ),
          ),
          context.spacing.sectionGap,
        ],
      ),
      bodyBuilder: (
        context,
        titleController,
        bodyController,
        bodyFocusNode,
      ) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            context.spacing.sectionGap,
            MarkdownLiveTextField(
              controller: bodyController,
              focusNode: bodyFocusNode,
              placeholder: 'Add a description…',
              maxLines: 12,
            ),
          ],
        );
      },
    );
  }

  /// Standard loading/error scaffold wrapper.
  Widget buildLoadingScaffold() => const Scaffold(
        body: Center(child: LoadingIndicator()),
      );

  Widget buildErrorScaffold(Object error) => Scaffold(
        appBar: AppBar(title: Text('Edit $entityTitle')),
        body: Center(child: Text('Failed to load: $error')),
      );
}
