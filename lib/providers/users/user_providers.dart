import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/misc/profile_card.dart' show ProfileCardLoading;
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/common/riverpod/mutation_error.dart';
import 'package:diohub/common/riverpod/optimistic_notifier.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart' as gql;
import 'package:diohub_graphql/queries/users/user_typedefs.dart';

import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/profile_card_input.dart';
import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/database_providers.dart'
    show authServiceProvider, apiClientProvider;
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:diohub/services/users/user_activity_service.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub/services/users/viewer_settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/async_notifier.dart';

export 'package:diohub/services/users/user_info_service.dart'
    show UserProfileData;

/// Single [UserInfoService] instance. Use this in widgets and notifiers instead of static calls.
final Provider<UserInfoService> userInfoServiceProvider =
    Provider<UserInfoService>((ref) => UserInfoService(ref.read(apiClientProvider)));

/// Single [UserActivityService] instance. Use from providers instead of static calls.
final Provider<UserActivityService> userActivityServiceProvider =
    Provider<UserActivityService>((ref) => UserActivityService(ref.read(apiClientProvider)));

/// User card fragment by login (for profile card from login-only context, e.g. events).
/// Use [ProfileCard]([ProfileCardInputUser]([FragmentUser](data))) when data is non-null.
final userCardByLoginProvider =
    FutureProvider.autoDispose.family<gql.UserCardData?, String>(
  (final Ref ref, final String login) =>
      ref.read(userInfoServiceProvider).getUserCardByLogin(login),
);

/// Single [ViewerSettingsService] instance for viewer-only settings (keys, gists, profile, blocks).
final Provider<ViewerSettingsService> viewerSettingsServiceProvider =
    Provider<ViewerSettingsService>((ref) => ViewerSettingsService(ref.read(apiClientProvider)));

final AsyncNotifierProvider<CurrentUserNotifier, ViewerInfo?>
    currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, ViewerInfo?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends AsyncNotifier<ViewerInfo?> {
  @override
  Future<ViewerInfo?> build() async {
    final AsyncValue<AccountSession?> accountAsync = ref.watch(accountProvider);

    if (accountAsync.hasError) {
      return null;
    }

    final AccountSession? session =
        accountAsync.hasValue ? accountAsync.value : null;
    if (session != null && session.activeAccount != null) {
      // We already have account; use cached viewer if present and only reconcile profile
      final ViewerInfo? existing = state.value;
      if (existing != null) {
        _reconcileAccountProfile(session.activeAccountModel, existing);
        return existing;
      }
      final ViewerInfo? viewer =
          await ref.read(userInfoServiceProvider).getViewerInfo();
      if (viewer != null) {
        _reconcileAccountProfile(session.activeAccountModel, viewer);
      }
      return viewer;
    }

    // Account loading or no session: load viewer in parallel with account load
    final AuthRepository authRepo = ref.read(authServiceProvider);
    final String? activeUsername = await authRepo.getActiveAccount();
    if (activeUsername == null) {
      final ViewerInfo? previousValue = state.value;
      return previousValue;
    }
    final ViewerInfo? viewer =
        await ref.read(userInfoServiceProvider).getViewerInfo();
    return viewer;
  }

  void _reconcileAccountProfile(
    AccountModel? account,
    ViewerInfo viewer,
  ) {
    if (account == null ||
        account.nodeId != viewer.id ||
        (account.username == viewer.login &&
            account.displayName == viewer.name &&
            account.avatarUrl == viewer.avatarUrl.toString())) {
      return;
    }
    ref.read(accountProvider.notifier).updateAccountProfile(
          nodeId: account.nodeId,
          serverId: account.serverConfig.id,
          username: viewer.login,
          displayName: viewer.name,
          avatarUrl: viewer.avatarUrl.toString(),
        );
  }
}

final userProvider = AsyncNotifierProvider.autoDispose
    .family<UserProfileNotifier, UserProfileData, UserRef>(
  UserProfileNotifier.new,
);

/// Block state for the block/unblock button. Reads [UserProfileNotifier.checkBlocked]; refreshes when popup reopens (autoDispose).
final blockStateForUserProvider = FutureProvider.autoDispose
    .family<bool, String>((final Ref ref, final String login) =>
        ref.read(userProvider(UserRef(login: login)).notifier).checkBlocked());

class UserProfileNotifier extends AsyncNotifier<UserProfileData>
    with OptimisticFamilyAsyncNotifier<UserProfileData> {
  UserProfileNotifier(this.userRef);
  final UserRef userRef;

  /// Cached block state (REST-only; not in GQL User type).
  bool? _isBlocked;

  @override
  Future<UserProfileData> build() async {
    keepAliveFor(ref);
    return ref.read(userInfoServiceProvider).getUserInfoGraphQL(userRef.login);
  }

  /// Sets the viewer's status. Patches state from mutation response (no invalidate).
  Future<void> setStatus({
    final String? emoji,
    final String? message,
    final bool limitedAvailability = false,
    final DateTime? expiresAt,
  }) async {
    final ChangedUserStatus? newStatus =
        await ref.read(viewerSettingsServiceProvider).changeStatus(
              emoji: emoji,
              message: message,
              limitedAvailability: limitedAvailability,
              expiresAt: expiresAt,
            );
    if (newStatus != null) _applyStatusFromResponse(newStatus);
  }

  /// Clears the viewer's status. Patches state (no invalidate).
  Future<void> clearStatus() async {
    await ref.read(viewerSettingsServiceProvider).clearStatus();
    _applyStatusFromResponse(null);
  }

  void _applyStatusFromResponse(
    ChangedUserStatus? status,
  ) {
    final UserProfileData? current =
        state.whenOrNull(data: (final UserProfileData v) => v);
    if (current == null) return;
    final UserProfileOwner newOwner = current.owner.maybeWhen(
      user: (final UserProfile u) {
        final UserStatus? newStatusBuilt = status == null
            ? null
            : UserStatus(
                message: status.message,
                emoji: status.emoji,
                indicatesLimitedAvailability:
                    status.indicatesLimitedAvailability,
              );
        return u.copyWith(
          status: newStatusBuilt,
        );
      },
      organization: (_) => current.owner,
      orElse: () => current.owner,
    );
    state = AsyncValue.data(
      UserProfileData(
        owner: newOwner,
        repoCount: current.repoCount,
        hasProfileReadme: current.hasProfileReadme,
      ),
    );
  }

  /// Updates a single profile field via REST PATCH /user. Optimistic update with rollback on error.
  Future<void> updateProfileField(final String field, final dynamic value) =>
      optimistic(
        transform: (final UserProfileData profile) =>
            _applyProfileField(profile, field, value),
        mutation: () => ref
            .read(viewerSettingsServiceProvider)
            .updateProfile({field: value}),
        errorMessage: (_, __) => "Couldn't update $field",
      );

  static UserProfileData _applyProfileField(
      final UserProfileData profile, final String field, final dynamic value) {
    final UserProfileOwner newOwner = profile.owner.maybeWhen(
      user: (final UserProfile u) {
        switch (field) {
          case 'name':
            return u.copyWith(name: value as String?);
          case 'bio':
            return u.copyWith(bio: value as String?);
          case 'company':
            return u.copyWith(company: value as String?);
          case 'location':
            return u.copyWith(location: value as String?);
          case 'blog':
            return u.copyWith(
                websiteUrl: value == null || value == ''
                    ? null
                    : Uri.tryParse(value as String));
          case 'twitter_username':
            return u.copyWith(twitterUsername: value as String?);
          case 'email':
            return u.copyWith(email: (value as String?) ?? '');
          case 'hireable':
            return u.copyWith(isHireable: value as bool);
          default:
            return u as UserProfileOwner;
        }
      },
      organization: (_) => profile.owner,
      orElse: () => profile.owner,
    );
    return UserProfileData(
      owner: newOwner,
      repoCount: profile.repoCount,
      hasProfileReadme: profile.hasProfileReadme,
    );
  }

  /// Patches state from follow/unfollow mutation response (no refetch).
  void updateFollowFromMutation(
      final bool viewerIsFollowing, final int followersCount) {
    final UserProfileData? current =
        state.whenOrNull(data: (final UserProfileData v) => v);
    if (current == null) return;
    final UserProfileOwner newOwner = current.owner.maybeWhen(
      user: (final UserProfile u) {
        final UserFollowers newFollowers =
            u.followers.copyWith(totalCount: followersCount);
        return u.copyWith(
          viewerIsFollowing: viewerIsFollowing,
          followers: newFollowers,
        );
      },
      organization: (final OrgProfile o) =>
          o.copyWith(viewerIsFollowing: viewerIsFollowing),
      orElse: () => current.owner,
    );
    state = AsyncValue.data(
      UserProfileData(
        owner: newOwner,
        repoCount: current.repoCount,
        hasProfileReadme: current.hasProfileReadme,
      ),
    );
  }

  /// Check whether the viewer has blocked this user (REST). Caches in [_isBlocked].
  Future<bool> checkBlocked() async {
    final bool result = await ref
        .read(viewerSettingsServiceProvider)
        .isUserBlocked(userRef.login);
    _isBlocked = result;
    return result;
  }

  /// Block or unblock this user. Uses [_isBlocked]; call [checkBlocked] first if null.
  /// Not optimistic; throws on error.
  Future<void> toggleBlock() async {
    final bool? current = _isBlocked;
    final bool wasBlocked = current ?? await checkBlocked();
    if (wasBlocked) {
      await ref.read(viewerSettingsServiceProvider).unblockUser(userRef.login);
    } else {
      await ref.read(viewerSettingsServiceProvider).blockUser(userRef.login);
    }
    _isBlocked = !wasBlocked;
  }

  /// Follow or unfollow this user or organization. Patches state from mutation response (no refetch).
  Future<void> changeFollowStatus(final String nodeId,
      {required final bool follow, final bool isOrg = false}) async {
    try {
      final ({int followersCount, bool viewerIsFollowing})? result = await ref
          .read(userInfoServiceProvider)
          .changeFollowStatus(nodeId, follow: follow, isOrg: isOrg);
      if (result != null) {
        updateFollowFromMutation(
          result.viewerIsFollowing,
          result.followersCount,
        );
      }
    } catch (e, st) {
      AppLogger.warning(
        'Update follow status failed',
        error: e,
        stackTrace: st,
        tag: 'UserProviders',
      );
      showMutationError(ref, "Couldn't update follow status", error: e, stackTrace: st);
      rethrow;
    }
  }
}

/// Converts [UserProfileData] from [userProvider] to [ProfileCardInput].
/// Use for peek/popup when resolving profile by login via GQL.
ProfileCardInput userProfileDataToProfileCardInput(
        final UserProfileData data) =>
    data.owner.maybeWhen(
      user: (final UserProfile u) => ProfileCardInputUser(FullUser(u)),
      organization: (final OrgProfile o) => ProfileCardInputOrg(FullOrg(o)),
      orElse: () => throw StateError('Unknown repository owner type'),
    );

/// Converts [UserProfileData] from [userProvider] to [UserInfoModel].
///
/// **Do not use for profile cards.** Profile card path uses [ProfileCardInput]
/// (built from [UserProfileData.owner] via `.maybeWhen()` at the call site, e.g.
/// [ProfileCardLoading]). Use this only for non–profile-card consumers (e.g.
/// assignee list, repo assignees).
UserInfoModel userProfileDataToUserInfoModel(final UserProfileData data) {
  final UserProfileOwner owner = data.owner;
  return owner.maybeWhen(
    user: (final UserProfile u) => UserInfoModel(
      login: u.login,
      avatarUrl: u.avatarUrl.toString(),
      name: u.name,
      bio: u.bio,
    ),
    organization: (final OrgProfile o) => UserInfoModel(
      login: o.login,
      avatarUrl: o.avatarUrl.toString(),
      name: o.name,
      bio: o.description,
    ),
    orElse: () => throw StateError('Unknown repository owner type'),
  );
}
