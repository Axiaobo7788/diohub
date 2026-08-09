import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/app_typography.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repository/compare_result.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/view/repository/widgets/branch_select_sheet.dart';

@RoutePage()
class CompareViewScreen extends ConsumerStatefulWidget {
  const CompareViewScreen({
    super.key,
    required this.repoRef,
    this.base,
    this.head,
  });

  final RepoRef repoRef;
  final String? base;
  final String? head;

  @override
  ConsumerState<CompareViewScreen> createState() => _CompareViewScreenState();
}

class _CompareViewScreenState extends ConsumerState<CompareViewScreen> {
  String? _activeBase;
  String? _activeHead;

  @override
  void initState() {
    super.initState();
    _activeBase = widget.base?.isNotEmpty == true ? widget.base : null;
    _activeHead = widget.head?.isNotEmpty == true ? widget.head : null;
  }

  Future<void> _openBranchSheet(bool isBase) async {
    final selected = await AppSheet.scrollable<String?>(
      context,
      header: AppSheetHeader.text(
        isBase
            ? context.l10n.compareSelectBaseRef
            : context.l10n.compareSelectHeadRef,
      ),
      bodyBuilder:
          (
            BuildContext ctx,
            StateSetter setState,
            ScrollController scrollController,
          ) => BranchSelectSheet(
            widget.repoRef,
            currentBranch: isBase ? _activeBase : _activeHead,
            onSelected: (String branch) {
              Navigator.of(ctx).pop(branch);
            },
            controller: scrollController,
          ),
    );
    if (selected != null && mounted) {
      setState(() {
        if (isBase) {
          _activeBase = selected;
        } else {
          _activeHead = selected;
        }
      });
    }
  }

  void _swapBaseAndHead() {
    setState(() {
      final t = _activeBase;
      _activeBase = _activeHead;
      _activeHead = t;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget baseSelector = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: OutlinedButton.icon(
        onPressed: () => _openBranchSheet(true),
        icon: const Icon(Icons.call_split, size: 18),
        label: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            _activeBase?.isNotEmpty == true
                ? _activeBase!
                : context.l10n.compareSelectBase,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
    final Widget headSelector = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: OutlinedButton.icon(
        onPressed: () => _openBranchSheet(false),
        icon: const Icon(Icons.call_split, size: 18),
        label: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            _activeHead?.isNotEmpty == true
                ? _activeHead!
                : context.l10n.compareSelectHead,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.compareTitle)),
      body: Column(
        children: [
          Padding(
            padding: context.spacing.contentPadding,
            child: LayoutBuilder(
              builder:
                  (
                    final BuildContext context,
                    final BoxConstraints constraints,
                  ) {
                    final bool stacked =
                        constraints.maxWidth < 480 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.3;
                    final Widget swap = IconButton(
                      icon: Icon(stacked ? Icons.swap_vert : Icons.swap_horiz),
                      onPressed: _swapBaseAndHead,
                      tooltip: context.l10n.compareSwapBaseHead,
                    );
                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          baseSelector,
                          Center(child: swap),
                          headSelector,
                        ],
                      );
                    }
                    return Row(
                      children: <Widget>[
                        Expanded(child: baseSelector),
                        swap,
                        Expanded(child: headSelector),
                      ],
                    );
                  },
            ),
          ),
          if (_activeBase != null &&
              _activeBase!.isNotEmpty &&
              _activeHead != null &&
              _activeHead!.isNotEmpty)
            Expanded(
              child: _CompareResultView(
                repoRef: widget.repoRef,
                base: _activeBase!,
                head: _activeHead!,
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  context.l10n.compareEnterRefs,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompareResultView extends ConsumerWidget {
  const _CompareResultView({
    required this.repoRef,
    required this.base,
    required this.head,
  });

  final RepoRef repoRef;
  final String base;
  final String head;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compareAsync = ref.watch(
      compareResultProvider((repoRef: repoRef, base: base, head: head)),
    );

    return compareAsync.when(
      loading: () => const CenteredSpinner(),
      error: (Object e, _) => Center(
        child: Padding(
          padding: context.spacing.contentPadding,
          child: Text(
            context.l10n.compareLoadError('$e'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (CompareResult result) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.contentPadding.horizontal / 2,
                  vertical: context.spacing.listInset.vertical,
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.spacing.chipPadding.horizontal,
                        vertical: context.spacing.tightSpacing,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cs.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 18,
                            color: cs.primary,
                          ),
                          Text(
                            '${result.aheadBy}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                          Text(
                            context.l10n.compareAhead,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 18,
                            color: cs.primary,
                          ),
                          Text(
                            '${result.behindBy}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                          Text(
                            context.l10n.compareBehind,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      context.l10n.compareFilesChanged(result.files.length),
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              TabBar(
                tabs: [
                  Tab(text: context.l10n.compareCommits),
                  Tab(text: context.l10n.compareFiles),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView.builder(
                      padding: context.spacing.contentPadding,
                      itemCount: result.commits.length,
                      itemBuilder: (BuildContext context, int index) {
                        final c = result.commits[index];
                        final model =
                            CommitListItemModel.fromCompareCommitSummary(
                              c.sha,
                              c.message,
                              repoRef,
                              authorName: c.authorName,
                              authorAvatarUrl: c.authorAvatarUrl,
                              date: c.date,
                            );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: BorderedContainer(
                            ref: CommitRef(repo: repoRef, oid: c.sha),
                            child: CommitCard(data: model, repoRef: repoRef),
                          ),
                        );
                      },
                    ),
                    ListView.builder(
                      padding: context.spacing.contentPadding,
                      itemExtent: 56,
                      itemCount: result.files.length,
                      itemBuilder: (BuildContext context, int index) {
                        final f = result.files[index];
                        return ListTile(
                          dense: true,
                          leading: _fileStatusIcon(context, f.status),
                          title: Text(
                            f.filename,
                            style: context.appTypography.mono,
                          ),
                          trailing: Semantics(
                            label: '+${f.additions}, -${f.deletions}',
                            child: ExcludeSemantics(
                              child: Text(
                                '+${f.additions} -${f.deletions}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fileStatusIcon(final BuildContext context, final String status) {
    final (IconData icon, Color color, String label) = switch (status
        .toLowerCase()) {
      'added' => (
        Icons.add_circle,
        DiffColors.addition,
        context.l10n.compareFileStatusAdded,
      ),
      'removed' => (
        Icons.remove_circle,
        DiffColors.deletion,
        context.l10n.compareFileStatusRemoved,
      ),
      'renamed' => (
        Icons.drive_file_rename_outline,
        DiffColors.renamed,
        context.l10n.compareFileStatusRenamed,
      ),
      _ => (
        Icons.edit,
        DiffColors.modified,
        context.l10n.compareFileStatusModified,
      ),
    };
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        label: label,
        image: true,
        child: ExcludeSemantics(child: Icon(icon, color: color, size: 16)),
      ),
    );
  }
}
