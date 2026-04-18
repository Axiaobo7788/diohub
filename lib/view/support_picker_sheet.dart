import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/support/support_typedefs.dart';
import 'package:diohub_models/models/support_result.dart';
import 'package:diohub/providers/listing_state_provider.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Formats a tier price in USD using the device locale (number format and
/// grouping). Amount is always USD; only formatting follows the user's locale.
String? _formatTierPrice(
    Locale locale, int monthlyPriceInDollars, int monthlyPriceInCents) {
  final amount = monthlyPriceInDollars + monthlyPriceInCents / 100;
  if (amount <= 0) return null;
  final format = NumberFormat.currency(
    locale: locale.toString(),
    name: 'USD',
    symbol: '\$',
    decimalDigits: monthlyPriceInCents % 100 == 0 ? 0 : 2,
  );
  return '${format.format(amount)}/mo';
}

/// Shows a bottom sheet to choose a support tier for [login] and optionally
/// create a sponsorship. When [sponsorableId] is null, only "View on GitHub"
/// is offered. Sheet content is a [ConsumerWidget] so [ref] is not needed.
Future<void> showSupportPickerSheet(
  BuildContext context,
  String login, {
  String? sponsorableId,
}) async {
  await AppSheet.scrollable<void>(
    context,
    initialChildSize: 0.5,
    minChildSize: 0.25,
    maxChildSize: 0.9,
    bodyBuilder: (BuildContext context, StateSetter setState,
            ScrollController scrollController) =>
        _SupportPickerSheetContent(
      login: login,
      sponsorableId: sponsorableId,
      scrollController: scrollController,
    ),
  );
}

class _SupportPickerSheetContent extends ConsumerWidget {
  const _SupportPickerSheetContent({
    required this.login,
    this.sponsorableId,
    required this.scrollController,
  });

  final String login;
  final String? sponsorableId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingStateProvider(login));
    final viewerStatusAsync = ref.watch(viewerSupportStatusProvider(login));
    return listingAsync.when(
      data: (listing) {
        if (listing == null) {
          return _buildMessage(
            context,
            'No support listing',
            onOpenUrl: () => _openSponsorsUrl(ref, login),
          );
        }
        final nodes = listing.tiers?.nodes;
        final tiers = nodes != null
            ? (nodes as Iterable<
                    SupportTierNode?>)
                .toList()
            : <SupportTierNode?>[];
        if (tiers.isEmpty) {
          return _buildMessage(
            context,
            'No tiers available',
            onOpenUrl: () => _openSponsorsUrl(ref, login),
          );
        }
        return _SupportPickerList(
          login: login,
          sponsorableId: sponsorableId,
          listing: listing,
          viewerStatus: viewerStatusAsync.when(
            data: (d) => d,
            loading: () => null,
            error: (_, __) => null,
          ),
          scrollController: scrollController,
        );
      },
      loading: () => const CenteredSpinner(),
      error: (e, _) => _buildMessage(
        context,
        'Unable to load: $e',
        onOpenUrl: () => _openSponsorsUrl(ref, login),
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context,
    String text, {
    VoidCallback? onOpenUrl,
  }) {
    return Padding(
      padding: context.spacing.spaciousPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
          if (onOpenUrl != null) ...[
            context.spacing.sectionGap,
            FilledButton(
              onPressed: onOpenUrl,
              child: const Text('View on GitHub'),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> _openSponsorsUrl(WidgetRef ref, String login) async {
    final url = ref.webUrl('/sponsors/$login');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _SupportPickerList extends ConsumerStatefulWidget {
  const _SupportPickerList({
    required this.login,
    this.sponsorableId,
    required this.listing,
    required this.viewerStatus,
    required this.scrollController,
  });

  final String login;
  final String? sponsorableId;
  final SupportListing listing;
  final dynamic viewerStatus;
  final ScrollController scrollController;

  @override
  ConsumerState<_SupportPickerList> createState() => _SupportPickerListState();
}

class _SupportPickerListState extends ConsumerState<_SupportPickerList> {
  SupportTierNode? _selectedTier;
  bool _isSubmitting = false;
  String? _error;

  /// Set when we showed billing fallback once; on second NeedsBilling we open sponsors page.
  bool _billingFallbackShown = false;
  static const String _billingErrorMessage =
      'Add a payment method on GitHub to continue.';

  @override
  Widget build(BuildContext context) {
    final rawNodes = widget.listing.tiers?.nodes;
    final tiers = (rawNodes != null
        ? rawNodes.toList()
        : <SupportTierNode?>[]);
    final canCreate = widget.sponsorableId != null && _selectedTier != null;
    return Padding(
      padding: EdgeInsets.only(
        left: context.spacing.screenPadding.left,
        right: context.spacing.screenPadding.right,
        top: context.spacing.contentPadding.top,
        bottom: context.spacing.contentPadding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.listing.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (widget.listing.shortDescription.toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.listing.shortDescription,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          context.spacing.sectionGap,
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: tiers.length,
              itemBuilder: (context, index) {
                final tier = tiers[index];
                if (tier == null) return const SizedBox.shrink();
                final isSelected = _selectedTier?.id == tier.id;
                final desc = tier.description;
                final locale = Localizations.localeOf(context);
                final priceText = _formatTierPrice(locale,
                    tier.monthlyPriceInDollars, tier.monthlyPriceInCents);
                return ListTile(
                  title: Text(tier.name),
                  subtitle: desc.isNotEmpty ? Text(desc) : null,
                  trailing: priceText != null ? Text(priceText) : null,
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedTier = tier;
                      _error = null;
                    });
                  },
                );
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  if (_error == _billingErrorMessage) ...[
                    context.spacing.itemGap,
                    TextButton.icon(
                      onPressed: _isSubmitting ? null : _submitSupport,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry after adding payment'),
                    ),
                  ],
                ],
              ),
            ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _openSponsorsUrl(),
                child: const Text('View on GitHub'),
              ),
              context.spacing.contentGap,
              if (canCreate)
                FilledButton(
                  onPressed: _isSubmitting ? null : _submitSupport,
                  child: _isSubmitting
                      ? const ButtonSpinner(size: 20)
                      : const Text('Support'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openSponsorsUrl() async {
    final url = ref.webUrl('/sponsors/${widget.login}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submitSupport() async {
    final sid = widget.sponsorableId;
    final tier = _selectedTier;
    if (sid == null || tier == null) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final result =
        await ref.read(createSupportMutationProvider.notifier).submit(
              widget.login,
              sponsorableId: sid,
              tierId: tier.id,
              isRecurring: !(tier.isOneTime == true),
              privacyLevel: SponsorshipPrivacy.PUBLIC,
            );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result is SupportSuccess) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (result is SupportNeedsBilling) {
      final wasAlreadyShown = _billingFallbackShown;
      setState(() {
        _error = _billingErrorMessage;
        _billingFallbackShown = true;
      });
      if (!wasAlreadyShown) {
        final url = ref.webUrl('/settings/billing/payment_information');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else {
        // Retry still failed: open sponsors page so they can complete there.
        final url = ref.webUrl('/sponsors/${widget.login}/sponsorships');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
      return;
    }
    if (result is SupportError) {
      if (!mounted) return;
      setState(() => _error = result.message);
    }
  }
}
