import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/support/create_support.graphql.dart';
import 'package:diohub_graphql/queries/support/update_support_preferences.graphql.dart';
import 'package:diohub_models/models/support_result.dart';
import 'package:diohub/services/base/base_service.dart';

final class SupportService extends BaseService {
  const SupportService._(ApiClient client) : super(client);

  factory SupportService(ApiClient client) => SupportService._(client);

  Future<SupportResult> createSupport({
    required String sponsorableId,
    required String tierId,
    bool isRecurring = true,
    Enum$SponsorshipPrivacy privacyLevel = Enum$SponsorshipPrivacy.PUBLIC,
    bool? receiveEmails,
  }) async {
    final response = await gql.mutation(
      documentNodeMutationcreateSupport,
      Variables$Mutation$createSupport(
        sponsorableId: sponsorableId,
        tierId: tierId,
        isRecurring: isRecurring,
        privacyLevel: privacyLevel,
        receiveEmails: receiveEmails,
      ).toJson(),
    );
    if (response.errors != null && response.errors!.isNotEmpty) {
      final msg = response.errors!.first.message.toLowerCase();
      if (msg.contains('billing') ||
          msg.contains('payment') ||
          msg.contains('funding')) {
        return SupportNeedsBilling();
      }
      return SupportError(response.errors!.first.message);
    }
    final data = Mutation$createSupport.fromJson(response.data!);
    final sponsorship = data.createSponsorship?.sponsorship;
    return SupportSuccess(sponsorship);
  }

  Future<SupportResult> updateSupportPreferences({
    required String sponsorableId,
    Enum$SponsorshipPrivacy? privacyLevel,
    bool? receiveEmails,
  }) async {
    final response = await gql.mutation(
      documentNodeMutationupdateSupportPreferences,
      Variables$Mutation$updateSupportPreferences(
        sponsorableId: sponsorableId,
        privacyLevel: privacyLevel,
        receiveEmails: receiveEmails,
      ).toJson(),
    );
    if (response.errors != null && response.errors!.isNotEmpty) {
      return SupportError(response.errors!.first.message);
    }
    final data = Mutation$updateSupportPreferences.fromJson(response.data!);
    final sponsorship = data.updateSponsorshipPreferences?.sponsorship;
    return SupportSuccess(sponsorship);
  }
}
