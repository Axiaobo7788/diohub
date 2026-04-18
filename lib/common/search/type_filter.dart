import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';

/// Creates a [FilterFn] that retains only items of type [T].
///
/// Replaces 6 identical closures:
/// ```dart
/// filterFn: (List<dynamic> data) => data.whereType<IssueResult>().toList()
/// ```
/// With:
/// ```dart
/// filterFn: typeFilter<IssueResult>()
/// ```
FilterFn typeFilter<T extends Object>() =>
    (List<Object> items) => items.whereType<T>().toList().cast<Object>();
