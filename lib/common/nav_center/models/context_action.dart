import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/search_overlay/search_filter_sheet.dart';
import 'package:diohub/models/search/search_scope.dart';

/// A single action displayed in the context bar.
///
/// Actions are categorized by rendering style:
/// - [isPrimary] = `true` → pill-shaped button with icon + label
/// - [isPrimary] = `false`, [isOverflow] = `false` → icon-only button
/// - [isOverflow] = `true` → hidden in ⋯ overflow menu
@immutable
class ContextAction {
  const ContextAction({
    required this.icon,
    this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isPill = false,
    this.isDestructive = false,
    this.isPositive = false,
    this.isDeferred = false,
    this.isOverflow = false,
    this.expandedOnly = false,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isPill;
  final bool isDestructive;
  final bool isPositive;
  final bool isDeferred;
  final bool isOverflow;
  final bool expandedOnly;

  factory ContextAction.primary(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool isDeferred = false,
    bool isPositive = false,
    bool isDestructive = false,
  }) => ContextAction(
    icon: icon,
    label: label,
    onTap: onTap,
    isPrimary: true,
    isDeferred: isDeferred,
    isPositive: isPositive,
    isDestructive: isDestructive,
  );

  factory ContextAction.icon(
    IconData icon, {
    required VoidCallback onTap,
    String? tooltip,
    bool expandedOnly = false,
    bool isDeferred = false,
  }) => ContextAction(
    icon: icon,
    label: tooltip,
    onTap: onTap,
    expandedOnly: expandedOnly,
    isDeferred: isDeferred,
  );

  factory ContextAction.overflow(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool isDeferred = false,
    bool isDestructive = false,
  }) => ContextAction(
    icon: icon,
    label: label,
    onTap: onTap,
    isOverflow: true,
    isDeferred: isDeferred,
    isDestructive: isDestructive,
  );

  factory ContextAction.pill(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool isDeferred = false,
  }) => ContextAction(
    icon: icon,
    label: label,
    onTap: onTap,
    isPill: true,
    isDeferred: isDeferred,
  );
}

List<ContextAction> searchFilterSortActions(
  SearchScope scope,
  WidgetRef ref,
  BuildContext context,
) {
  return <ContextAction>[
    ContextAction.pill(
      Icons.search_rounded,
      'Search',
      onTap: () => _openFilterSheet(scope, ref, context),
    ),
    ContextAction.pill(
      Icons.filter_list_rounded,
      'Filter',
      onTap: () => _openFilterSheet(scope, ref, context),
    ),
    ContextAction.pill(
      Icons.sort_rounded,
      'Sort',
      onTap: () => _openFilterSheet(scope, ref, context),
    ),
  ];
}

void _openFilterSheet(SearchScope scope, WidgetRef ref, BuildContext context) {
  unawaited(
    AppSheet.scrollable<void>(
      context,
      headerBuilder: (BuildContext ctx, StateSetter setState) =>
          SearchFilterSheet.buildHeader(ctx, scope, ref),
      bodyBuilder:
          (
            BuildContext ctx,
            StateSetter setState,
            ScrollController scrollController,
          ) => SearchFilterSheet(
            scope: scope,
            scrollController: scrollController,
          ),
    ),
  );
}

List<ContextAction> searchOnlyAction(
  SearchScope scope,
  WidgetRef ref,
  BuildContext context,
) {
  return <ContextAction>[
    ContextAction.pill(
      Icons.search_rounded,
      'Search',
      onTap: () => _openFilterSheet(scope, ref, context),
    ),
  ];
}

List<ContextAction> sortOnlyAction(
  SearchScope scope,
  WidgetRef ref,
  BuildContext context,
) {
  return <ContextAction>[
    ContextAction.pill(
      Icons.sort_rounded,
      'Sort',
      onTap: () => _openFilterSheet(scope, ref, context),
    ),
  ];
}

List<ContextAction> branchSelectorAction(VoidCallback showBranchPicker) {
  return <ContextAction>[
    ContextAction.primary(
      Icons.fork_right_rounded,
      'Branch',
      onTap: showBranchPicker,
    ),
  ];
}

ContextAction addCommentAction(VoidCallback focusComposeBar) {
  return ContextAction.primary(
    Icons.chat_bubble_outline_rounded,
    'Add Comment',
    onTap: focusComposeBar,
  );
}

ContextAction creationAction(
  String label,
  VoidCallback onTap, {
  bool isDeferred = false,
}) {
  return ContextAction.primary(
    Icons.add_rounded,
    label,
    onTap: onTap,
    isDeferred: isDeferred,
    isPositive: true,
  );
}
