import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub_graphql/queries/support/support_typedefs.dart';
import 'package:diohub_graphql/queries/support/support_listing_tiers.graphql.dart';
import 'package:diohub_graphql/queries/support/support_for_viewer.graphql.dart';
import 'package:diohub_models/models/support_result.dart';
import 'package:diohub/services/support_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supportServiceProvider =
    Provider<SupportService>((ref) => SupportService(ref.read(apiClientProvider)));

final listingStateProvider =
    FutureProvider.autoDispose.family<SupportListing?, String>(
  (ref, login) async {
    final variables = Variables$Query$supportListingTiers(login: login);
    final response = await ref.read(apiClientProvider).gql.query(
          documentNodeQuerysupportListingTiers,
          variables.toJson(),
        );
    final data = Query$supportListingTiers.fromJson(response.data!);
    return data.user?.sponsorsListing;
  },
);

final viewerSupportStatusProvider =
    FutureProvider.autoDispose.family<SupportForViewerSponsorship?, String>(
  (ref, login) async {
    final variables = Variables$Query$supportForViewer(login: login);
    final response = await ref.read(apiClientProvider).gql.query(
          documentNodeQuerysupportForViewer,
          variables.toJson(),
        );
    final data = Query$supportForViewer.fromJson(response.data!);
    return data.user?.sponsorshipForViewerAsSponsor;
  },
);

/// Notifier that performs createSupport and invalidates support state from inside (no UI invalidate).
final createSupportMutationProvider = NotifierProvider<
    CreateSupportMutationNotifier, MutationState<SupportResult>>(
  CreateSupportMutationNotifier.new,
);

class CreateSupportMutationNotifier
    extends Notifier<MutationState<SupportResult>>
    with MutationNotifierMixin<SupportResult> {
  @override
  MutationState<SupportResult> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  /// Calls support service then invalidates [viewerSupportStatusProvider] and [listingStateProvider] on success.
  Future<SupportResult> submit(
    final String login, {
    required final String sponsorableId,
    required final String tierId,
    final bool isRecurring = true,
    final SponsorshipPrivacy privacyLevel = SponsorshipPrivacy.PUBLIC,
    final bool? receiveEmails,
  }) async {
    final result = await runMutation(() async {
      final result = await ref.read(supportServiceProvider).createSupport(
            sponsorableId: sponsorableId,
            tierId: tierId,
            isRecurring: isRecurring,
            privacyLevel: privacyLevel,
            receiveEmails: receiveEmails,
          );
      if (result is SupportSuccess) {
        ref.invalidate(viewerSupportStatusProvider(login));
        ref.invalidate(listingStateProvider(login));
      }
      return result;
    });
    return result ?? SupportError('Mutation was cancelled or already running');
  }
}
