import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/user_contributions_provider.dart';
import 'package:diohub/view/profile/about/widgets/chip_detail_bottom_sheet.dart';
import 'package:diohub/view/profile/about/widgets/tabbed_contribution_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// About screen that includes user details, contribution graph, and pinned repos
class UserAboutScreen extends ConsumerStatefulWidget {
  const UserAboutScreen(
    this.userData, {
    required this.contributionQueryKey,
    required this.selectedTab,
    this.onYearChanged,
    this.onCustomRangeChanged,
    super.key,
  });

  final UserProfileOwner userData;
  final ContributionQueryKey contributionQueryKey;
  final ContributionTab selectedTab;
  final void Function(int)? onYearChanged;
  final void Function(DateTime?, DateTime?)? onCustomRangeChanged;

  @override
  ConsumerState<UserAboutScreen> createState() => _UserAboutScreenState();
}

class _UserAboutScreenState extends ConsumerState<UserAboutScreen> {
  /// Handles chip tap to show bottom sheet with details
  void _handleChipTap(
    final BuildContext context,
    final ContributionChipType chipType,
    final ContributionQueryKey queryKey,
    final ContributionCollectionResult result,
  ) {
    AppSheet.scrollable<void>(
      context,
      header: AppSheetHeader.text(
        ChipDetailBottomSheet.titleForChipType(chipType),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bodyBuilder: (final BuildContext context, StateSetter setState,
              ScrollController scrollController) =>
          ChipDetailBottomSheet(
        chipType: chipType,
        queryKey: queryKey,
        contributionResult: result,
        scrollController: scrollController,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    // Fetch contributions data using Riverpod with typed key
    // Key only changes when date range changes, preventing unnecessary rebuilds
    final ContributionQueryKey providerKey = widget.contributionQueryKey;

    final AsyncValue<ContributionCollectionResult> contributionsAsync =
        ref.watch(
      userContributionsProvider(providerKey),
    );

    if (kDebugMode) {
      contributionsAsync.maybeWhen(
        data: (final ContributionCollectionResult data) {},
        loading: () {},
        error: (final Object error, final StackTrace stack) {},
        orElse: () {},
      );
    }

    // Always render TabbedContributionSection so dropdown remains visible
    // Pass async state so it can handle loading/error internally
    final UserRef userRef = UserRef(login: widget.userData.login);
    final List<RepoCardData> pinnedRepos = widget.userData.maybeWhen(
      user: (final u) => (u.pinnedItems.edges?.toList() ?? [])
          .map((final e) => e?.node)
          .whereType<RepoCardData>()
          .toList(),
      organization: (final o) => (o.pinnedItems.edges?.toList() ?? [])
          .map((final e) => e?.node)
          .whereType<RepoCardData>()
          .toList(),
      orElse: () => <RepoCardData>[],
    );
    return _WrappedTabbedContributionSection(
      contributionsAsync: contributionsAsync,
      userRef: userRef,
      createdAt: widget.userData.maybeWhen(
        user: (final UserProfile u) => u.createdAt,
        organization: (final OrgProfile o) => o.createdAt,
        orElse: DateTime.now,
      ),
      providerKey: providerKey,
      selectedTab: widget.selectedTab,
      pinnedRepos: pinnedRepos,
      onChipTap: (final ContributionChipType chipType) {
        contributionsAsync
            .whenData((final ContributionCollectionResult result) {
          _handleChipTap(
            context,
            chipType,
            providerKey,
            result,
          );
        });
      },
    );
  }
}

/// Wrapper for TabbedContributionSection that integrates with expandable scroll wrapper
class _WrappedTabbedContributionSection extends StatelessWidget {
  const _WrappedTabbedContributionSection({
    required this.contributionsAsync,
    required this.userRef,
    required this.createdAt,
    required this.providerKey,
    required this.selectedTab,
    this.pinnedRepos,
    this.onChipTap,
  });

  final AsyncValue<ContributionCollectionResult> contributionsAsync;
  final UserRef userRef;
  final DateTime? createdAt;
  final ContributionQueryKey providerKey;
  final ContributionTab selectedTab;
  final List<RepoCardData>? pinnedRepos;
  final void Function(ContributionChipType chipType)? onChipTap;

  @override
  Widget build(final BuildContext context) => TabbedContributionSection(
        contributionsAsync: contributionsAsync,
        userRef: userRef,
        createdAt: createdAt,
        providerKey: providerKey,
        selectedTab: selectedTab,
        pinnedRepos: pinnedRepos,
        onChipTap: onChipTap,
      );
}
