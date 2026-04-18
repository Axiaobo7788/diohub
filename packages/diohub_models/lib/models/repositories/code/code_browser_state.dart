import 'package:freezed_annotation/freezed_annotation.dart';

part 'code_browser_state.freezed.dart';

/// In-memory navigation state for the code browser (path-based flat list).
@freezed
abstract class CodeBrowserState with _$CodeBrowserState {
  const factory CodeBrowserState({
    @Default('') String currentPath,
    @Default([]) List<String> pathStack,
    @Default('') String searchQuery,
  }) = _CodeBrowserState;
}
