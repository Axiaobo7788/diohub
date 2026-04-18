import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/common/events/events.dart' show Events;
import 'package:diohub/common/nav_center/models/tab_body.dart';

/// Creates the org activity feed tab body showing public events for the organization.
TabBody createOrgActivityBody(WidgetRef widgetRef, String orgLogin) {
  return SliverBuilderBody(
    sliverBuilder: (ctx, ref) => [
      Events(
        orgLogin: orgLogin,
        privateEvents: false,
      ),
    ],
    refreshFuture: null,
  );
}
