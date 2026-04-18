import 'package:diohub/providers/users/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current primary email visibility (public vs private). Fetches from API on build.
/// Use [EmailVisibilityNotifier.toggle] for optimistic update with rollback on failure.
final emailVisibilityProvider =
    AsyncNotifierProvider.autoDispose<EmailVisibilityNotifier, bool>(
  EmailVisibilityNotifier.new,
);

class EmailVisibilityNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return ref.read(viewerSettingsServiceProvider).getEmailVisibility();
  }

  /// Toggles visibility (public <-> private) with optimistic update. Reverts on API failure.
  Future<void> toggle() async {
    final bool current = state.hasValue ? state.value! : false;
    final next = !current;
    state = AsyncData<bool>(next);
    try {
      await ref.read(viewerSettingsServiceProvider).setEmailVisibility(
            next ? 'public' : 'private',
          );
    } catch (e, _) {
      state = AsyncData<bool>(current);
      rethrow;
    }
  }
}
