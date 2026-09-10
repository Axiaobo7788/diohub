part of '../notifications_md3_screen.dart';

typedef NotificationSelectionChanged =
    void Function(Thread thread, {required bool selected});

@RoutePage()
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<AccountSession?> accountState = ref.watch(accountProvider);
    final bool accountResolved = accountState.hasValue;
    final AccountModel? account = accountResolved
        ? accountState.value?.activeAccountModel
        : null;
    final ViewerInfo? viewerCandidate = account == null
        ? null
        : ref.watch(currentUserProvider).value;
    final ViewerInfo? viewer = viewerCandidate?.id == account?.nodeId
        ? viewerCandidate
        : null;
    final AsyncValue<List<HomeRepositoryItem>> topRepositories = account == null
        ? const AsyncData<List<HomeRepositoryItem>>(<HomeRepositoryItem>[])
        : ref.watch(
            homeTopRepositoriesProvider((
              accountKey: account.accountKey,
              login: account.username,
            )),
          );

    final Widget body;
    if (!accountResolved && accountState.hasError) {
      body = _NotificationsAccountErrorState(
        onRetry: () => ref.invalidate(accountProvider),
      );
    } else if (!accountResolved) {
      body = const _NotificationsAccountLoadingState();
    } else if (account == null) {
      body = const _NotificationsSignInState();
    } else {
      body = NotificationsMd3Page(scope: resourceScopeForAccount(account));
    }

    return AppChrome(
      title: GlobalHeaderTitle(title: context.l10n.homeNotifications),
      account: account,
      accountLoading: !accountResolved,
      topRepositories: topRepositories,
      statusEmoji: viewer?.status?.emoji,
      statusMessage: viewer?.status?.message,
      body: body,
    );
  }
}

class NotificationsMd3Page extends ConsumerStatefulWidget {
  const NotificationsMd3Page({required this.scope, super.key});

  final ResourceScope scope;

  @override
  ConsumerState<NotificationsMd3Page> createState() =>
      _NotificationsMd3PageState();
}
