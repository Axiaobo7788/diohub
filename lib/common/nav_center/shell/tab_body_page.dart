import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/shell/nav_center_refresh_scope.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps a [TabBody] as a [Widget] for [TabConfig.body].
///
/// Owns the body lifecycle: [State.dispose] calls [TabBody.dispose].
/// Builds [AppCustomScrollView] with slivers from [TabBody.buildSliversWithRef]
/// and pull-to-refresh when [TabBody.canRefresh] is true.
class TabBodyPage extends StatefulWidget {
  const TabBodyPage({required this.body, super.key});

  final TabBody body;

  @override
  State<TabBodyPage> createState() => _TabBodyPageState();
}

class _TabBodyPageState extends State<TabBodyPage> {
  @override
  void dispose() {
    widget.body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, _) {
        return AppCustomScrollView(
          slivers: widget.body.buildSliversWithRef(context, ref),
          onRefresh: widget.body.canRefresh
              ? () async {
                  final f = widget.body.performRefresh();
                  if (f == null) return;
                  final scope = NavCenterRefreshScope.of(context);
                  scope?.value = true;
                  try {
                    await f;
                  } finally {
                    scope?.value = false;
                  }
                }
              : null,
        );
      },
    );
  }
}
