import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:riverpod/src/providers/notifier.dart';

/// State for FileTreeView widget
class FileTreeViewState {
  const FileTreeViewState({
    required this.expandedPaths,
    required this.showTreeView,
    required this.files,
  });

  final Set<String> expandedPaths;
  final bool showTreeView;
  final List<FileElement> files;

  FileTreeViewState copyWith({
    final Set<String>? expandedPaths,
    final bool? showTreeView,
    final List<FileElement>? files,
  }) =>
      FileTreeViewState(
        expandedPaths: expandedPaths ?? this.expandedPaths,
        showTreeView: showTreeView ?? this.showTreeView,
        files: files ?? this.files,
      );
}

/// Notifier for managing FileTreeView state
class FileTreeViewNotifier extends Notifier<FileTreeViewState> {
  FileTreeViewNotifier([this._initialFiles]);
  final List<FileElement>? _initialFiles;

  /// Cached directory tree, computed once from files list
  Map<String, dynamic>? _directoryTreeCache;

  @override
  FileTreeViewState build() {
    // Initialize with files if provided, otherwise empty state
    if (_initialFiles != null && _initialFiles.isNotEmpty) {
      final Set<String> expandedPaths = _getAllDirectoryPaths(_initialFiles);
      return FileTreeViewState(
        expandedPaths: expandedPaths,
        showTreeView: true,
        files: _initialFiles,
      );
    }
    return const FileTreeViewState(
      expandedPaths: <String>{},
      showTreeView: true,
      files: <FileElement>[],
    );
  }

  /// Initialize with files and expand all directories by default
  void initializeFiles(final List<FileElement> files) {
    final Set<String> expandedPaths = _getAllDirectoryPaths(files);
    state = state.copyWith(
      files: files,
      expandedPaths: expandedPaths,
    );
  }

  /// Get all directory paths from files
  Set<String> _getAllDirectoryPaths(final List<FileElement> files) {
    final Set<String> paths = <String>{};
    // Use cached tree if available and files match current state
    final Map<String, dynamic> root = _getCachedOrBuildTree(files);
    _collectAllPaths(root, '', paths);
    return paths;
  }

  /// Get cached directory tree or build and cache it
  Map<String, dynamic> _getCachedOrBuildTree(final List<FileElement> files) {
    if (_directoryTreeCache == null || !identical(files, state.files)) {
      _directoryTreeCache = _buildDirectoryTree(files);
    }
    return _directoryTreeCache!;
  }

  /// Build directory tree structure
  Map<String, dynamic> _buildDirectoryTree(final List<FileElement> files) {
    final Map<String, dynamic> root = <String, dynamic>{};

    for (final FileElement file in files) {
      final String filename = file.filename ?? '';
      final List<String> pathParts = filename.split('/');

      if (pathParts.length == 1) {
        // Root level file - skip
        continue;
      }

      // File in a directory
      Map<String, dynamic> current = root;
      for (int i = 0; i < pathParts.length - 1; i++) {
        final String dirName = pathParts[i];
        current = current.putIfAbsent(dirName, () => <String, dynamic>{})
            as Map<String, dynamic>;
      }
    }

    return root;
  }

  /// Collect all directory paths recursively
  void _collectAllPaths(final Map<String, dynamic> node,
      final String currentPath, final Set<String> paths) {
    for (final MapEntry<String, dynamic> entry in node.entries) {
      final String newPath =
          currentPath.isEmpty ? entry.key : '$currentPath/${entry.key}';
      paths.add(newPath);
      if (entry.value is Map) {
        _collectAllPaths(entry.value as Map<String, dynamic>, newPath, paths);
      }
    }
  }

  /// Toggle a single directory's expanded state
  void toggleDirectory(final String path) {
    final Set<String> newExpandedPaths = Set<String>.from(state.expandedPaths);
    if (newExpandedPaths.contains(path)) {
      newExpandedPaths.remove(path);
    } else {
      newExpandedPaths.add(path);
    }
    state = state.copyWith(expandedPaths: newExpandedPaths);
  }

  /// Expand all directories
  void expandAll() {
    final Set<String> expandedPaths = _getAllDirectoryPaths(state.files);
    state = state.copyWith(expandedPaths: expandedPaths);
  }

  /// Collapse all directories
  void collapseAll() {
    state = state.copyWith(expandedPaths: <String>{});
  }

  /// Set view mode (tree vs flat)
  void setViewMode(final bool showTreeView) {
    state = state.copyWith(showTreeView: showTreeView);
  }
}

/// Provider for FileTreeView state
/// Uses a family provider keyed by files list identity
final NotifierProviderFamily<FileTreeViewNotifier, FileTreeViewState,
        List<FileElement>> fileTreeViewProvider =
    NotifierProvider.family<FileTreeViewNotifier, FileTreeViewState,
        List<FileElement>>(
  FileTreeViewNotifier.new,
);
