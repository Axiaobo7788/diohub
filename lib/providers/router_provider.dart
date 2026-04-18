import 'package:flutter_riverpod/flutter_riverpod.dart';

class _PendingDeepLinkNotifier extends Notifier<Uri?> {
  @override
  Uri? build() => null;
}

/// Pending deep link (cold start or in-app). Set when app is launched via
/// deep link or when a link is received while app is running. Consumed by
/// [RootApp] and cleared after navigation.
final pendingDeepLinkProvider =
    NotifierProvider<_PendingDeepLinkNotifier, Uri?>(
  _PendingDeepLinkNotifier.new,
);
