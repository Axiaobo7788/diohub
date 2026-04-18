import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/cards/branch_refs.dart';
import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repository/compare_result.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
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
      header: AppSheetHeader.text('Select ${isBase ? 'base' : 'head'} ref'),
      bodyBuilder: (BuildContext ctx, StateSetter setState,
              ScrollController scrollController) =>
          BranchSelectSheet(
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
    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: Column(
        children: [
          Padding(
            padding: context.spacing.contentPadding,
            child: Row(
              children: [
                Expanded(
                  child: TapFeedback(
                    onTap: () => _openBranchSheet(true),
                    child: _activeBase != null && _activeBase!.isNotEmpty
                        ? BranchRefPill(branchName: _activeBase!)
                        : Padding(
                            padding: context.spacing.chipPadding,
                            child: Text(
                              'Select base…',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: _swapBaseAndHead,
                  tooltip: 'Swap base and head',
                ),
                Expanded(
                  child: TapFeedback(
                    onTap: () => _openBranchSheet(false),
                    child: _activeHead != null && _activeHead!.isNotEmpty
                        ? BranchRefPill(branchName: _activeHead!)
                        : Padding(
                            padding: context.spacing.chipPadding,
                            child: Text(
                              'Select head…',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                  ),
                ),
              ],
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
            const Expanded(
              child: Center(
                child: Text('Enter base and head refs, then tap Compare'),
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
        compareResultProvider((repoRef: repoRef, base: base, head: head)));

    return compareAsync.when(
      loading: () => const CenteredSpinner(),
      error: (Object e, _) => Center(child: Text('Error: $e')),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                            context.spacing.tightGap,
                            Text(
                              '${result.aheadBy}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                            context.spacing.contentGap,
                            Text(
                              'ahead',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            context.spacing.contentGap,
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                            context.spacing.tightGap,
                            Text(
                              '${result.behindBy}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                            context.spacing.tightGap,
                            Text(
                              'behind',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    context.spacing.contentGap,
                    Text(
                      '${result.files.length} files changed',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Commits'),
                  Tab(text: 'Files'),
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
                          leading: _fileStatusIcon(f.status),
                          title: Text(f.filename,
                              style: const TextStyle(fontSize: 13)),
                          trailing: Text(
                            '+${f.additions} -${f.deletions}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  f.additions > 0 ? Colors.green : Colors.red,
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

  Widget _fileStatusIcon(String status) {
    return switch (status) {
      'added' => const Icon(Icons.add_circle, color: Colors.green, size: 16),
      'removed' => const Icon(Icons.remove_circle, color: Colors.red, size: 16),
      'renamed' => const Icon(
          Icons.drive_file_rename_outline,
          color: Colors.blue,
          size: 16,
        ),
      _ => const Icon(Icons.edit, color: Colors.orange, size: 16),
    };
  }
}
