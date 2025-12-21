import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/users/user_contributions_provider.dart';
import 'package:diohub/view/profile/about/widgets/tabbed_contribution_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// About screen that includes user details, contribution graph, and pinned repos
class UserAboutScreen extends ConsumerStatefulWidget {
  const UserAboutScreen(
    this.userData, {
    this.selectedYear,
    this.customFromDate,
    this.customToDate,
    this.useCustomRange = false,
    this.onYearChanged,
    this.onCustomRangeChanged,
    super.key,
  });

  final GuserInfoData_user userData;
  final int? selectedYear;
  final DateTime? customFromDate;
  final DateTime? customToDate;
  final bool useCustomRange;
  final void Function(int)? onYearChanged;
  final void Function(DateTime?, DateTime?)? onCustomRangeChanged;

  @override
  ConsumerState<UserAboutScreen> createState() => _UserAboutScreenState();
}

class _UserAboutScreenState extends ConsumerState<UserAboutScreen> {
  /// Builds a typed provider key based on selected year or custom date range
  /// Only recalculates when date range changes, not on every build
  ContributionQueryKey _getProviderKey() {
    if (widget.useCustomRange &&
        widget.customFromDate != null &&
        widget.customToDate != null) {
      // Normalize dates to day level for stable keys
      final from = DateTime(widget.customFromDate!.year,
          widget.customFromDate!.month, widget.customFromDate!.day);
      final to = DateTime(widget.customToDate!.year, widget.customToDate!.month,
          widget.customToDate!.day);
      return ContributionQueryKey.customRange(
        userName: widget.userData.login,
        from: from,
        to: to,
      );
    }

    final selectedYear = widget.selectedYear;
    if (selectedYear == null) {
      // Default: last year from today
      return ContributionQueryKey.lastYear(widget.userData.login);
    } else {
      // Specific year
      return ContributionQueryKey.year(widget.userData.login, selectedYear);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch contributions data using Riverpod with typed key
    // Key only changes when date range changes, preventing unnecessary rebuilds
    final providerKey = _getProviderKey();

    final contributionsAsync = ref.watch(
      userContributionsProvider(providerKey),
    );

    return contributionsAsync.when(
      data: (result) {
        return TabbedContributionSection(
          contributionResult: result,
          userName: widget.userData.login,
          selectedYear: widget.selectedYear,
          customFromDate: widget.customFromDate,
          customToDate: widget.customToDate,
          useCustomRange: widget.useCustomRange,
          createdAt: widget.userData.createdAt,
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Error loading contribution data: $error');
          debugPrint('Stack trace: $stackTrace');
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load contribution data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

