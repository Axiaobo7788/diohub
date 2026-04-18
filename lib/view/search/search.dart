import 'package:auto_route/annotations.dart';
import 'package:diohub/common/nav_center/shell/nav_center_shell.dart';
import 'package:diohub/providers/search/search_session_provider.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/view/search/search_screen_config.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends ConsumerState<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  late final ValueNotifier<Future<void> Function()?> reposRefreshRegistrar =
      ValueNotifier<Future<void> Function()?>(null);

  @override
  bool get wantKeepAlive => true;

  @override
  void deactivate() {
    ref.read(searchSessionProvider.notifier).clear();
    super.deactivate();
  }

  @override
  void dispose() {
    reposRefreshRegistrar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final initialQuery = widget.initialQuery;
    if (initialQuery != null &&
        initialQuery.isNotEmpty &&
        ref.read(pendingSearchInitialQueryProvider) == null) {
      ref.read(pendingSearchInitialQueryProvider.notifier).set(initialQuery);
    }
    final config = buildSearchScreenConfig(
      context,
      ref,
      reposRefreshRegistrar: reposRefreshRegistrar,
    );
    final tabs = config.visibleTabs;
    int initialIndex = 0;
    if (tabs.isNotEmpty && config.initialTabPath != null) {
      final found =
          tabs.indexWhere((p) => p.deeplinkPath == config.initialTabPath);
      if (found >= 0) initialIndex = found;
    }
    final clampedIndex =
        tabs.isEmpty ? 0 : initialIndex.clamp(0, tabs.length - 1);
    return NavCenterShell(
      config: config,
      initialTabIndex: clampedIndex,
    );
  }
}
