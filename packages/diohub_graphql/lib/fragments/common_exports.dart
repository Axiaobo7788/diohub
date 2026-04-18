/// Barrel export for the split fragment types.
///
/// Previously all three fragments lived in `common.graphql`.
/// They have been split into individual files so each query only includes
/// the fragments it actually uses (GitHub's API rejects unused fragments).
///
/// Hand-written Dart code can import this single file to get all three types.
library;

export 'actor.graphql.dart';
export 'label.graphql.dart';
export 'reaction_groups.graphql.dart';
