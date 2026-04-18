import 'package:diohub_graphql/schema.graphql.dart';

/// Ordered list of repository permissions from lowest to highest.
const List<Enum$RepositoryPermission> _permissionOrder = <Enum$RepositoryPermission>[
  Enum$RepositoryPermission.READ,
  Enum$RepositoryPermission.TRIAGE,
  Enum$RepositoryPermission.WRITE,
  Enum$RepositoryPermission.MAINTAIN,
  Enum$RepositoryPermission.ADMIN,
];

/// Returns `true` if [current] is at least [minimum] permission level.
///
/// Returns `false` if [current] is null (viewer has no access).
///
/// Permission hierarchy: READ < TRIAGE < WRITE < MAINTAIN < ADMIN
bool isAtLeast(
    final Enum$RepositoryPermission? current, final Enum$RepositoryPermission minimum) {
  if (current == null) return false;
  return _permissionOrder.indexOf(current) >= _permissionOrder.indexOf(minimum);
}
