import 'package:diohub/app/global.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/contributions/contribution_chip_type.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
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
    this.onYearChanged,
    this.onCustomRangeChanged,
    super.key,
  });

  final GuserInfoData_user userData;
  final ContributionQueryKey contributionQueryKey;
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final BuildContext context) => ChipDetailBottomSheet(
        chipType: chipType,
        queryKey: queryKey,
        contributionResult: result,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    // Fetch contributions data using Riverpod with typed key
    // Key only changes when date range changes, preventing unnecessary rebuilds
    final ContributionQueryKey providerKey = widget.contributionQueryKey;

    if (kDebugMode) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final (from, to) = providerKey.dateRange.dates;
      log.d(
          '[UserAboutScreen] 🔄 build() called at $timestamp - widget.userData.login: "${widget.userData.login}", providerKey.userName: "${providerKey.userName}", dateRange: ${providerKey.dateRange.runtimeType}, from: ${from.toIso8601String()}, to: ${to.toIso8601String()}');
      log.d(
          '[UserAboutScreen] Watching userContributionsProvider with key hashCode: ${providerKey.hashCode}');
      if (widget.userData.login != providerKey.userName) {
        log.w(
            '[UserAboutScreen] ⚠️ MISMATCH: widget.userData.login ("${widget.userData.login}") != providerKey.userName ("${providerKey.userName}")');
      }
    }

    final AsyncValue<ContributionCollectionResult> contributionsAsync =
        ref.watch(
      userContributionsProvider(providerKey),
    );

    if (kDebugMode) {
      contributionsAsync.when(
        data: (data) {
          log.d(
              '[UserAboutScreen] Provider returned data for "${providerKey.userName}"');
        },
        loading: () {
          log.d(
              '[UserAboutScreen] Provider loading for "${providerKey.userName}"');
        },
        error: (error, stack) {
          log.e(
              '[UserAboutScreen] Provider error for "${providerKey.userName}"',
              error: error,
              stackTrace: stack);
        },
      );
    }

    // Always render TabbedContributionSection so dropdown remains visible
    // Pass async state so it can handle loading/error internally
    return _WrappedTabbedContributionSection(
      contributionsAsync: contributionsAsync,
      userName: widget.userData.login,
      createdAt: widget.userData.createdAt,
      providerKey: providerKey,
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
    required this.userName,
    required this.createdAt,
    required this.providerKey,
    this.onChipTap,
  });

  final AsyncValue<ContributionCollectionResult> contributionsAsync;
  final String userName;
  final DateTime? createdAt;
  final ContributionQueryKey providerKey;
  final void Function(ContributionChipType chipType)? onChipTap;

  @override
  Widget build(final BuildContext context) => TabbedContributionSection(
        contributionsAsync: contributionsAsync,
        userName: userName,
        createdAt: createdAt,
        providerKey: providerKey,
        onChipTap: onChipTap,
      );
}
