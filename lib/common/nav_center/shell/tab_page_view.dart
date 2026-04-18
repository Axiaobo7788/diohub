import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';

/// Swipeable tab body driven by a [ValueNotifier<int>] index.
///
/// Each page corresponds to a [TabConfig] in the [tabs] list.
/// Pages with [TabConfig.keepAlive] = true are kept alive across swipes.
class TabPageView extends StatefulWidget {
  const TabPageView({
    required this.tabs,
    required this.tabIndex,
    super.key,
  });

  final List<TabConfig> tabs;
  final ValueNotifier<int> tabIndex;

  @override
  State<TabPageView> createState() => _TabPageViewState();
}

class _TabPageViewState extends State<TabPageView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final length = widget.tabs.length;
    _pageController = PageController(
      initialPage:
          length > 0 ? widget.tabIndex.value.clamp(0, length - 1) : 0,
    );
    widget.tabIndex.addListener(_onTabIndexChanged);
  }

  @override
  void dispose() {
    widget.tabIndex.removeListener(_onTabIndexChanged);
    _pageController.dispose();
    super.dispose();
  }

  /// Whether a programmatic warp is in progress.
  ///
  /// Suppresses [_onPageChanged] feedback during the jump+animate sequence
  /// so we don't emit intermediate index values.
  bool _warpInProgress = false;

  void _onTabIndexChanged() {
    final targetPage = widget.tabIndex.value;
    if (!_pageController.hasClients) return;

    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage == targetPage) return;

    final distance = (targetPage - currentPage).abs();
    if (distance <= 1) {
      // Adjacent tab – smooth slide as before.
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Non-adjacent tab – jump to the page right next to the destination,
      // then animate one page over. This avoids scrolling through all
      // intermediate tabs.
      _warpToNonAdjacentPage(currentPage, targetPage);
    }
  }

  Future<void> _warpToNonAdjacentPage(int from, int target) async {
    _warpInProgress = true;

    // The "runway" page is one page before the destination in the direction
    // of travel, so the user only sees a single-page slide animation.
    final adjacentPage = target > from ? target - 1 : target + 1;

    _pageController.jumpToPage(adjacentPage);

    await _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _warpInProgress = false;

    // Ensure the notifier is in sync after the warp completes.
    if (mounted && widget.tabIndex.value != target) {
      widget.tabIndex.value = target;
    }
  }

  void _onPageChanged(int page) {
    // During a non-adjacent warp the PageView fires intermediate page changes
    // (e.g. the jump to the "runway" page). Suppress those so the notifier
    // only ever reflects the true destination.
    if (_warpInProgress) return;

    if (widget.tabIndex.value != page) {
      widget.tabIndex.value = page;
    }
  }

  @override
  Widget build(BuildContext context) => _buildPageView();

  Widget _buildPageView() {
    if (widget.tabs.isEmpty) {
      return const _BodyPlaceholder(label: 'No tabs');
    }
    // PageView with an explicit controller does NOT claim PrimaryScrollController,
    // so AppCustomScrollView on each page naturally inherits the
    // ExtendedNestedScrollView's inner coordinator — no wrapping needed.
    //
    // We DO need ExtendedVisibilityDetector around each page so that the
    // ExtendedNestedScrollView coordinator (onlyOneScrollInBody: true) can
    // identify which page is currently visible and drive header collapse from
    // that page's scroll position only.
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: const ClampingScrollPhysics(),
      itemCount: widget.tabs.length,
      itemBuilder: (context, index) {
        final tab = widget.tabs[index];
        return _KeepAlivePage(
          keepAlive: tab.keepAlive,
          child: ExtendedVisibilityDetector(
            uniqueKey: ValueKey<String>('tab_page_$index'),
            child: tab.body,
          ),
        );
      },
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({
    required this.keepAlive,
    required this.child,
  });

  final bool keepAlive;
  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _BodyPlaceholder extends StatelessWidget {
  const _BodyPlaceholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
      ),
    );
  }
}
