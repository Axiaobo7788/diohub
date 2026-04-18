import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/file_tree_view_provider.dart';
import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// A widget for displaying files in a tree view structure.
///
/// Supports nested directory paths and provides visual indicators for hierarchy.
/// Directory headers are pinned when scrolling to show the current path.
///
/// Uses Riverpod for state management to handle expand/collapse and view mode.
class FileTreeView extends ConsumerWidget {
  FileTreeView({
    required this.files,
    required this.onFileTap,
    this.showToolbar = true,
    super.key,
  });

  final List<FileElement> files;
  final void Function(FileElement file)? onFileTap;
  final bool showToolbar;

  /// Cached directory tree structure, computed once from immutable files list
  late final DirectoryNode _directoryTree = _buildDirectoryTree();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final FileTreeViewState state = ref.watch(fileTreeViewProvider(files));

    // Build slivers based on current state
    final List<Widget> slivers = _buildSlivers(context, ref, state);

    return MultiSliver(children: slivers);
  }

  List<Widget> _buildSlivers(
    final BuildContext context,
    final WidgetRef ref,
    final FileTreeViewState state,
  ) {
    if (!state.showTreeView) {
      // Flat list view
      return <Widget>[
        if (showToolbar)
          SliverToBoxAdapter(
            child: _buildToolbar(context, ref, state),
          ),
        SliverPadding(
          padding: EdgeInsets.only(
            left: context.spacing.contentPadding.left,
            right: context.spacing.contentPadding.right,
            top: 0,
            bottom: 0,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (final BuildContext context, final int index) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildFileCard(context, files[index], 0, ''),
              ),
              childCount: files.length,
            ),
          ),
        ),
      ];
    }

    // Tree view
    return _buildTreeViewSlivers(context, ref, state);
  }

  List<Widget> _buildTreeViewSlivers(
    final BuildContext context,
    final WidgetRef ref,
    final FileTreeViewState state,
  ) {
    final List<Widget> slivers = <Widget>[];

    // Add toolbar if enabled
    if (showToolbar) {
      slivers.add(
        SliverToBoxAdapter(
          child: _buildToolbar(context, ref, state),
        ),
      );
    }

    // Add directory slivers using cached tree
    slivers.addAll(
        _buildDirectoryNodeSlivers(context, ref, _directoryTree, <String>[], '', state));

    return slivers;
  }

  DirectoryNode _buildDirectoryTree() {
    final DirectoryNode root = DirectoryNode('');

    for (final FileElement file in files) {
      final String filename = file.filename;
      final List<String> pathParts = filename.split('/');

      if (pathParts.length == 1) {
        // Root level file
        root.files.add(file);
      } else {
        // File in a directory
        DirectoryNode current = root;
        for (int i = 0; i < pathParts.length - 1; i++) {
          final String dirName = pathParts[i];
          current = current.getOrCreateChild(dirName);
        }
        current.files.add(file);
      }
    }

    return root;
  }

  Widget _buildToolbar(
    final BuildContext context,
    final WidgetRef ref,
    final FileTreeViewState state,
  ) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: _ExpandableToolbar(
          files: files,
          state: state,
          onExpandAll: () =>
              ref.read(fileTreeViewProvider(files).notifier).expandAll(),
          onCollapseAll: () =>
              ref.read(fileTreeViewProvider(files).notifier).collapseAll(),
          onViewModeChanged: (final bool value) =>
              ref.read(fileTreeViewProvider(files).notifier).setViewMode(value),
          showTreeView: state.showTreeView,
        ),
      );

  List<Widget> _buildDirectoryNodeSlivers(
    final BuildContext context,
    final WidgetRef ref,
    final DirectoryNode node,
    final List<String> pathParts,
    final String currentPath,
    final FileTreeViewState state,
  ) {
    final List<Widget> slivers = <Widget>[];

    // Sort children directories
    final List<DirectoryNode> sortedDirs = node.children.values.toList()
      ..sort((final DirectoryNode a, final DirectoryNode b) =>
          a.name.compareTo(b.name));

    // Add directories with sticky headers
    for (final DirectoryNode dir in sortedDirs) {
      final String newPath =
          currentPath.isEmpty ? dir.name : '$currentPath/${dir.name}';
      final List<String> newPathParts = <String>[...pathParts, dir.name];
      final bool isExpanded = state.expandedPaths.contains(newPath);

      // Collect files for this directory
      final List<FileElement> sortedFiles = dir.files.toList()
        ..sort((final FileElement a, final FileElement b) =>
            (a.filename).compareTo(b.filename));

      // Get nested subdirectories (these are already slivers)
      final List<Widget> nestedSubdirs = _buildDirectoryNodeSlivers(
        context,
        ref,
        dir,
        newPathParts,
        newPath,
        state,
      );

      // Combine files and nested directories into content slivers
      final List<Widget> contentSlivers = <Widget>[];

      // Add files first as slivers (wrapped in animated widget)
      for (final FileElement file in sortedFiles) {
        contentSlivers.add(
          _AnimatedSliverWrapper(
            expand: isExpanded,
            child: SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: 4,
                  left: 12 + (newPathParts.length * 18.0),
                  right: 12,
                ),
                child: _buildFileCard(
                  context,
                  file,
                  newPathParts.length,
                  newPath,
                ),
              ),
            ),
          ),
        );
      }

      // Add nested subdirectories (they handle their own animation via their headers)
      contentSlivers.addAll(nestedSubdirs);

      // Wrap everything in a sticky header that unpins when content scrolls out
      slivers.add(
        SliverStickyHeader(
          header: _buildDirectoryHeader(
            context,
            ref,
            newPathParts,
            newPath,
            dir,
            pathParts.length, // depth
            isExpanded,
          ),
          sliver: MultiSliver(
            children: contentSlivers,
          ),
        ),
      );
    }

    // Add root-level files (files in the current node)
    final List<FileElement> sortedFiles = node.files.toList()
      ..sort((final FileElement a, final FileElement b) =>
          (a.filename).compareTo(b.filename));
    for (final FileElement file in sortedFiles) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: 4,
              left: 12 + (pathParts.length * 18.0),
              right: 12,
            ),
            child: _buildFileCard(context, file, pathParts.length, currentPath),
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildDirectoryHeader(
    final BuildContext context,
    final WidgetRef ref,
    final List<String> pathParts,
    final String fullPath,
    final DirectoryNode node,
    final int depth,
    final bool isExpanded,
  ) {
    final int totalFiles = node.totalFileCount;
    // Show only the directory name (last part of path)
    final String displayName =
        pathParts.isNotEmpty ? pathParts.last : node.name;
    final FileTreeViewNotifier notifier =
        ref.read(fileTreeViewProvider(files).notifier);

    return Padding(
      padding: EdgeInsets.only(
        left: 12 + (depth * 18.0),
        right: 12,
        top: 2,
        bottom: 2,
      ),
      child: HighlightedContainer(
        highlightColor: context.colorScheme.primary,
        size: RadiusSize.small,
        child: Material(
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: context.radius(RadiusSize.small),
          child: InkWell(
            onTap: () => notifier.toggleDirectory(fullPath),
            borderRadius: context.radius(RadiusSize.small),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.itemSpacing, vertical: 6),
              child: Row(
                children: <Widget>[
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: kMicroDuration,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: context.colorScheme.onSurfaceVariant.secondary,
                    ),
                  ),
                  context.spacing.compactGap,
                  Icon(
                    Icons.folder_rounded,
                    size: 14,
                    color: context.colorScheme.primary,
                  ),
                  context.spacing.compactGap,
                  Expanded(
                    child: Text(
                      displayName,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  context.spacing.compactGap,
                  Container(
                    padding: context.spacing.badgePadding,
                    decoration: context.surfaceDecoration(
                      RadiusSize.small,
                      color: context.colorScheme.surfaceContainer.hinted,
                    ),
                    child: Text(
                      '$totalFiles',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant.strong,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileCard(
    final BuildContext context,
    final FileElement file,
    final int depth,
    final String currentPath,
  ) {
    // final String? status = file.status;
    Color statusColor;
    IconData statusIcon;
    Widget statusTextWidget;
    String subtitleText;

    if (file.isAdded) {
      statusColor = Colors.green.shade400;
      statusIcon = Octicons.diff_added;
      final int additions = file.additions;
      statusTextWidget = Text(
        '+$additions',
        style: context.textTheme.bodySmall?.copyWith(
          color: Colors.green.shade400,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      );
      subtitleText = 'File added';
    } else if (file.isRemoved) {
      statusColor = Colors.red.shade400;
      statusIcon = Octicons.diff_removed;
      final int deletions = file.deletions ?? 0;
      statusTextWidget = Text(
        '-$deletions',
        style: context.textTheme.bodySmall?.copyWith(
          color: Colors.red.shade400,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      );
      subtitleText = 'File removed';
    } else {
      statusColor = context.colorScheme.primary;
      statusIcon = Octicons.diff_modified;
      final int additions = file.additions;
      final int deletions = file.deletions;
      final int changes = file.changes;
      statusTextWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '+$additions',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.green.shade400,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '-$deletions',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.red.shade400,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      );
      subtitleText = '$changes changes';
    }

    final String filename = file.filename ?? '';
    // In flat mode (depth 0), show full path. In tree mode, show just filename
    final String displayName = depth == 0 && filename.contains('/')
        ? filename
        : filename.contains('/')
            ? filename.substring(filename.lastIndexOf('/') + 1)
            : filename;

    // Show path as subtitle in flat mode
    final bool showPath = depth == 0 && filename.contains('/');
    final List<String> pathParts = filename.split('/');
    final String path = pathParts.length > 1
        ? pathParts.sublist(0, pathParts.length - 1).join('/')
        : '';

    return HighlightedContainer(
      highlightColor: statusColor,
      size: RadiusSize.small,
      child: Material(
        color: Color.lerp(
          context.colorScheme.surfaceContainer,
          Colors.black,
          0.1,
        ),
        borderRadius: context.radius(RadiusSize.small),
        child: InkWell(
          onTap: file.patch != null && onFileTap != null
              ? () => onFileTap!(file)
              : null,
          borderRadius: context.radius(RadiusSize.small),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.itemSpacing),
            child: Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: context.surfaceDecoration(
                    RadiusSize.small,
                    color: statusColor.tintMedium,
                  ),
                  child: Icon(
                    statusIcon,
                    size: 14,
                    color: statusColor,
                  ),
                ),
                context.spacing.itemGap,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        displayName,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: context.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (showPath && path.isNotEmpty)
                        Text(
                          path,
                          style: context.textTheme.bodySmall?.copyWith(
                            color:
                                context.colorScheme.onSurfaceVariant.secondary,
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          subtitleText,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                ),
                context.spacing.itemGap,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    statusTextWidget,
                    if (file.patch != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 12,
                        color: context.colorScheme.onSurfaceVariant.hinted,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A wrapper that animates sliver content using SizeTransition
class _AnimatedSliverWrapper extends StatefulWidget {
  const _AnimatedSliverWrapper({
    required this.expand,
    required this.child,
  });

  final bool expand;
  final Widget child;

  @override
  State<_AnimatedSliverWrapper> createState() => _AnimatedSliverWrapperState();
}

class _AnimatedSliverWrapperState extends State<_AnimatedSliverWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kStateDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
    if (widget.expand) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(final _AnimatedSliverWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expand != oldWidget.expand) {
      if (widget.expand) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    // For SliverToBoxAdapter, extract child and animate it
    if (widget.child is SliverToBoxAdapter) {
      final SliverToBoxAdapter sliver = widget.child as SliverToBoxAdapter;
      return SliverToBoxAdapter(
        child: SizeTransition(
          sizeFactor: _animation,
          child: sliver.child,
        ),
      );
    } else {
      // For other slivers, return as-is (they'll be handled by their parent)
      return widget.child;
    }
  }
}

/// Expandable toolbar widget with icon-only compact mode and expanded view with labels
class _ExpandableToolbar extends StatefulWidget {
  const _ExpandableToolbar({
    required this.files,
    required this.state,
    required this.onExpandAll,
    required this.onCollapseAll,
    required this.onViewModeChanged,
    required this.showTreeView,
  });

  final List<FileElement> files;
  final FileTreeViewState state;
  final VoidCallback onExpandAll;
  final VoidCallback onCollapseAll;
  final ValueChanged<bool> onViewModeChanged;
  final bool showTreeView;

  @override
  State<_ExpandableToolbar> createState() => _ExpandableToolbarState();
}

class _ExpandableToolbarState extends State<_ExpandableToolbar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kStateDuration,
    );
    _heightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _widthAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(final BuildContext context) => HighlightedContainer(
        highlightColor: context.colorScheme.primary,
        size: RadiusSize.small,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (final BuildContext context, final Widget? child) =>
              ClipRect(
            child: AnimatedContainer(
              duration: kStateDuration,
              curve: kStateCurve,
              padding: EdgeInsets.symmetric(
                horizontal: 8 + (_widthAnimation.value * 8),
                vertical: 6 + (_heightAnimation.value * 4),
              ),
              decoration: context.surfaceDecoration(
                RadiusSize.small,
                color: context.colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Main row with icons and prominent action
                  Row(
                    children: <Widget>[
                      // File count (display only)
                      Tooltip(
                        message:
                            '${widget.files.length} ${widget.files.length == 1 ? 'file' : 'files'}',
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            Octicons.file_diff,
                            size: 10,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      context.spacing.tightGap,
                      // Expand All icon
                      _ToolbarIconButton(
                        icon: Icons.unfold_more_rounded,
                        tooltip: 'Expand All',
                        onTap: widget.onExpandAll,
                      ),
                      const SizedBox(width: 2),
                      // Collapse All icon
                      _ToolbarIconButton(
                        icon: Icons.unfold_less_rounded,
                        tooltip: 'Collapse All',
                        onTap: widget.onCollapseAll,
                      ),
                      const SizedBox(width: 2),
                      // View Mode Switch icon
                      _ToolbarIconButton(
                        icon: widget.showTreeView
                            ? Octicons.file_directory
                            : Icons.list,
                        tooltip:
                            widget.showTreeView ? 'Tree View' : 'List View',
                        onTap: () =>
                            widget.onViewModeChanged(!widget.showTreeView),
                      ),
                      const Spacer(),
                      // Expand/Collapse toggle button
                      _ToolbarIconButton(
                        icon: _isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        tooltip: _isExpanded ? 'Collapse' : 'Expand',
                        onTap: _toggleExpanded,
                      ),
                      context.spacing.compactGap,
                      // File count (display only)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Octicons.file_diff,
                              size: 12,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                            context.spacing.tightGap,
                            Text(
                              '${widget.files.length} files',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Expanded content with labels (vertical layout)
                  SizeTransition(
                    sizeFactor: _heightAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        context.spacing.compactGap,
                        // Divider
                        Container(
                          height: 1,
                          color: context.colorScheme.outlineVariant.borderO,
                        ),
                        context.spacing.compactGap,
                        // Actions with labels (vertical stack)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Padding(
                              padding: context.spacing.chipPadding,
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Octicons.file_diff,
                                    size: 10,
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                  context.spacing.itemGap,
                                  Text(
                                    '${widget.files.length} ${widget.files.length == 1 ? 'file' : 'files'}',
                                    style:
                                        context.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color:
                                          context.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _ActionWithLabel(
                              icon: Icons.unfold_more_rounded,
                              label: 'Expand All',
                              onTap: widget.onExpandAll,
                            ),
                            _ActionWithLabel(
                              icon: Icons.unfold_less_rounded,
                              label: 'Collapse All',
                              onTap: widget.onCollapseAll,
                            ),
                            _ActionWithLabel(
                              icon: widget.showTreeView
                                  ? Octicons.file_directory
                                  : Icons.list,
                              label: widget.showTreeView
                                  ? 'Tree View'
                                  : 'List View',
                              onTap: () => widget
                                  .onViewModeChanged(!widget.showTreeView),
                            ),
                          ],
                        ),
                        context.spacing.compactGap,
                        // Divider before prominent actions
                        Container(
                          height: 1,
                          color: context.colorScheme.outlineVariant.borderO,
                        ),
                        context.spacing.compactGap,
                        // File count at bottom (display only)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Octicons.file_diff,
                                size: 12,
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                              context.spacing.itemGap,
                              Text(
                                '${widget.files.length} files',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Icon button for toolbar (compact mode)
class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
    this.customColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  final Color?
      customColor; // For custom colors like Colors.green (issues) or Colors.purple (PRs)

  @override
  Widget build(final BuildContext context) {
    final Color? iconColor = customColor ??
        (color != null && color != context.colorScheme.primary
            ? color
            : context.colorScheme.onSurfaceVariant);

    return TapFeedback(
      onTap: onTap,
      size: RadiusSize.small,
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(
            icon,
            size: 10,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

/// Action with icon and label (expanded mode)
class _ActionWithLabel extends StatelessWidget {
  const _ActionWithLabel({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.customColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color?
      customColor; // For custom colors like Colors.green (issues) or Colors.purple (PRs)

  @override
  Widget build(final BuildContext context) {
    final Color? iconColor = customColor ??
        (color != null && color != context.colorScheme.primary
            ? color
            : context.colorScheme.onSurfaceVariant);

    return TapFeedback(
      onTap: onTap,
      size: RadiusSize.small,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: context.spacing.chipPadding,
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 10,
                color: iconColor,
              ),
              context.spacing.itemGap,
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: iconColor,
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
}

/// Prominent action with icon and text
class _ProminentAction extends StatelessWidget {
  const _ProminentAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.customColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color?
      customColor; // For custom colors like Colors.green (issues) or Colors.purple (PRs)

  @override
  Widget build(final BuildContext context) {
    final Color color = customColor ?? context.colorScheme.primary;

    return TapFeedback(
      onTap: onTap,
      size: RadiusSize.small,
      child: Padding(
        padding: context.spacing.chipPadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 10,
              color: color,
            ),
            context.spacing.compactGap,
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DirectoryNode {
  DirectoryNode(this.name);

  final String name;
  final Map<String, DirectoryNode> children = <String, DirectoryNode>{};
  final List<FileElement> files = <FileElement>[];

  DirectoryNode getOrCreateChild(final String name) =>
      children.putIfAbsent(name, () => DirectoryNode(name));

  int get totalFileCount {
    int count = files.length;
    for (final DirectoryNode child in children.values) {
      count += child.totalFileCount;
    }
    return count;
  }
}
