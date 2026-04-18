import 'package:diohub/app/settings/code_browser_settings.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/code_browser/code_browser_state_provider.dart';
import 'package:diohub/providers/settings/code_browser_settings_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Compact toolbar: search field, sort popup, filter menu for the directory view.
class DirectoryToolbar extends ConsumerStatefulWidget {
  const DirectoryToolbar({
    required this.repoRef,
    required this.settings,
    required this.searchQuery,
    super.key,
  });

  final RepoRef repoRef;
  final CodeBrowserSettings settings;
  final String searchQuery;

  @override
  ConsumerState<DirectoryToolbar> createState() => _DirectoryToolbarState();
}

class _DirectoryToolbarState extends ConsumerState<DirectoryToolbar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(DirectoryToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        _searchController.text != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = context.spacing;

    return Padding(
      padding: spacing.screenPadding.copyWith(top: 4, bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (String value) => ref
                  .read(codeBrowserStateProvider(widget.repoRef).notifier)
                  .setSearchQuery(value),
              decoration: InputDecoration(
                hintText: 'Search in folder',
                isDense: true,
                prefixIcon: const Icon(Octicons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          spacing.tightGap,
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () => _showSortMenu(context, ref, widget.settings),
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterMenu(context, ref, widget.settings),
            tooltip: 'Filter',
          ),
        ],
      ),
    );
  }

  void _showSortMenu(
      BuildContext context, WidgetRef ref, CodeBrowserSettings settings) {
    final notifier = ref.read(codeBrowserSettingsProvider.notifier);
    showMenu<CodeSortOrder>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 100, 100),
      items: CodeSortOrder.values
          .map((CodeSortOrder o) => PopupMenuItem<CodeSortOrder>(
                value: o,
                child: Text(_sortLabel(o)),
              ))
          // ignore: prefer_async_await
          .toList(),
      // ignore: prefer_async_await
    ).then((CodeSortOrder? value) {
      if (value != null) {
        notifier.update((final s) => s.copyWith(sortOrder: value));
      }
    });
  }

  static String _sortLabel(CodeSortOrder o) {
    return switch (o) {
      CodeSortOrder.type => 'Type (folders first)',
      CodeSortOrder.nameAsc => 'Name A–Z',
      CodeSortOrder.nameDesc => 'Name Z–A',
      CodeSortOrder.size => 'Size',
      CodeSortOrder.extension => 'Extension',
    };
  }

  void _showFilterMenu(
      BuildContext context, WidgetRef ref, CodeBrowserSettings settings) {
    final notifier = ref.read(codeBrowserSettingsProvider.notifier);
    AppSheet.simple<void>(
      context,
      header: AppSheetHeader.text('Filter'),
      bodyBuilder: (BuildContext ctx, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile(
            title: const Text('Show dotfiles'),
            value: settings.showDotfiles,
            onChanged: (bool v) =>
                notifier.update((final s) => s.copyWith(showDotfiles: v)),
          ),
          SwitchListTile(
            title: const Text('Show generated files'),
            value: settings.showGeneratedFiles,
            onChanged: (bool v) =>
                notifier.update((final s) => s.copyWith(showGeneratedFiles: v)),
          ),
          SwitchListTile(
            title: const Text('Show metadata'),
            value: settings.showMetadata,
            onChanged: (bool v) =>
                notifier.update((final s) => s.copyWith(showMetadata: v)),
          ),
          SwitchListTile(
            title: const Text('Show last commit'),
            value: settings.showLastCommitInfo,
            onChanged: (bool v) =>
                notifier.update((final s) => s.copyWith(showLastCommitInfo: v)),
          ),
        ],
      ),
    );
  }
}
