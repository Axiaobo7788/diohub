import 'package:diohub/app/app_logger.dart';
import 'package:diohub/view/issues_pulls/widgets/suggested_reviewers_section.dart'
    show SuggestedReviewerData;

List<SuggestedReviewerData> mapSuggestedReviewers(Iterable<dynamic> raw) {
  final List<SuggestedReviewerData> result = <SuggestedReviewerData>[];
  for (final s in raw) {
    try {
      final r = s.reviewer as dynamic;
      result.add(
        SuggestedReviewerData(
          id: r.id as String,
          login: r.login as String,
          avatarUrl: r.avatarUrl.toString(),
          name: r.name as String?,
          isAuthor: s.isAuthor as bool? ?? false,
          isCommenter: s.isCommenter as bool? ?? false,
        ),
      );
    } catch (e) {
      AppLogger.warning(
        'Malformed participant entry skipped',
        error: e,
        tag: 'PR',
      );
    }
  }
  return result;
}
