import 'package:diohub/common/misc/changed_files_list_card.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Slivers for the commit Files tab for use inside the shell's scroll view.
List<Widget> buildChangedFilesSlivers(
  final BuildContext context,
  final CommitInfo commit,
  final List<FileElement>? files,
) {
  if (files == null || files.isEmpty) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: context.spacing.spaciousPadding,
            child: const Text('No changed files available'),
          ),
        ),
      ),
    ];
  }

  return <Widget>[
    SliverToBoxAdapter(
      child: Padding(
        padding: context.spacing.spaciousPadding,
        child: Text(
          'Showing ${files.length} changed files with ${commit.additions} additions and ${commit.deletions} deletions.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (final BuildContext context, final int index) {
          if (index.isOdd) {
            return context.spacing.contentGap;
          }
          return ChangedFilesListCard(files[index ~/ 2]);
        },
        childCount: files.length * 2 - 1,
      ),
    ),
  ];
}

class ChangedFiles extends StatelessWidget {
  const ChangedFiles({
    required this.commit,
    required this.files,
    super.key,
  });

  final CommitInfo commit;
  final List<FileElement>? files;

  @override
  Widget build(final BuildContext context) {
    if (files == null || files!.isEmpty) {
      return Center(
        child: Padding(
          padding: context.spacing.spaciousPadding,
          child: const Text('No changed files available'),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: context.spacing.spaciousPadding,
          child: Text(
            'Showing ${files!.length} changed files with ${commit.additions} additions and ${commit.deletions} deletions.',
            textAlign: TextAlign.center,
          ),
        ),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: files!.length,
          separatorBuilder: (final BuildContext context, final int index) =>
              context.spacing.contentGap,
          itemBuilder: (final BuildContext context, final int index) =>
              ChangedFilesListCard(files![index]),
        ),
      ],
    );
  }
}
