import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/code_browser_state.dart';
import 'package:diohub/models/repositories/repository_initial_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory navigation state for the code browser.
/// Keyed by [RepoRef] so each repo has independent navigation.
final codeBrowserStateProvider = NotifierProvider.family<
    CodeBrowserStateNotifier, CodeBrowserState, RepoRef>(
  CodeBrowserStateNotifier.new,
);

class CodeBrowserStateNotifier extends Notifier<CodeBrowserState> {
  CodeBrowserStateNotifier(this._repoRef);
  final RepoRef _repoRef;

  @override
  CodeBrowserState build() {
    final String? codePath = resolveRepoLocation(_repoRef.location).codePath;
    if (codePath == null || codePath.isEmpty) {
      return const CodeBrowserState();
    }
    final List<String> segments =
        codePath.split('/').where((String s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return const CodeBrowserState();
    // If path looks like a file, show its parent directory (same as former slivers logic).
    final String targetPath = segments.length > 1 &&
            segments.last.contains('.') &&
            segments.last != '.'
        ? segments.sublist(0, segments.length - 1).join('/')
        : segments.join('/');
    final List<String> targetSegments =
        targetPath.split('/').where((String s) => s.isNotEmpty).toList();
    final List<String> newStack = <String>[''];
    for (int i = 0; i < targetSegments.length - 1; i++) {
      newStack.add(targetSegments.sublist(0, i + 1).join('/'));
    }
    return CodeBrowserState(
      currentPath: targetPath,
      pathStack: newStack,
      searchQuery: '',
    );
  }

  /// Navigate into a subdirectory.
  void pushDirectory(String directoryPath) {
    state = state.copyWith(
      currentPath: directoryPath,
      pathStack: [...state.pathStack, state.currentPath],
      searchQuery: '',
    );
  }

  /// Navigate back one level. Returns false if already at root.
  bool popDirectory() {
    if (state.pathStack.isEmpty) return false;
    final List<String> stack = List<String>.from(state.pathStack);
    final String parent = stack.removeLast();
    state = state.copyWith(
      currentPath: parent,
      pathStack: stack,
      searchQuery: '',
    );
    return true;
  }

  /// Jump to a specific breadcrumb index. [index] -1 = root.
  void jumpToPathIndex(int index) {
    final List<String> segments =
        state.currentPath.split('/').where((String s) => s.isNotEmpty).toList();
    if (index < 0) {
      state = const CodeBrowserState();
      return;
    }
    if (index >= segments.length) return;
    final String targetPath = segments.sublist(0, index + 1).join('/');
    final List<String> newStack = <String>[''];
    for (int i = 0; i < index; i++) {
      newStack.add(segments.sublist(0, i + 1).join('/'));
    }
    state = state.copyWith(
      currentPath: targetPath,
      pathStack: newStack,
      searchQuery: '',
    );
  }

  /// Navigate to a deep path (e.g. deep link "src/lib/main.dart").
  /// Builds the full path stack. If the last segment is a file, pass the parent directory path.
  void navigateToPath(String fullPath) {
    final List<String> segments =
        fullPath.split('/').where((String s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return;
    final List<String> newStack = <String>[''];
    for (int i = 0; i < segments.length - 1; i++) {
      newStack.add(segments.sublist(0, i + 1).join('/'));
    }
    state = state.copyWith(
      currentPath: segments.join('/'),
      pathStack: newStack,
      searchQuery: '',
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
