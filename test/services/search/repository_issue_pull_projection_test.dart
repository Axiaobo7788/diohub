import 'package:diohub_graphql/queries/search/search_repository_issue_pulls.graphql.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gql/language.dart';

void main() {
  test('Repository Issues/PR query contains only list projection fields', () {
    final String query = printNode(documentNodeQuerysearchRepositoryIssuePulls);

    expect(query, contains('issueCount'));
    expect(query, contains('comments'));
    expect(query, contains('labels(first: 5)'));
    expect(query, isNot(contains('body')));
    expect(query, isNot(contains('assignees')));
    expect(query, isNot(contains('projectItems')));
    expect(query, isNot(contains('reactionGroups')));
    expect(query, isNot(contains('latestOpinionatedReviews')));
    expect(query, isNot(contains('statusCheckRollup')));
  });
}
