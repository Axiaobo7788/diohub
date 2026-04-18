import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/organizations/org_admin_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for [OrgAdminService].
final Provider<OrgAdminService> orgAdminServiceProvider =
    Provider<OrgAdminService>((final Ref ref) {
  return OrgAdminService(ref.watch(apiClientProvider));
});

/// Parameter type for org block status provider.
typedef OrgBlockStatusParams = ({String orgLogin, String username});

/// Block status for a user at org level. Used in org profile popup menus.
/// Takes (orgLogin, username) as parameter. AutoDispose so it refreshes when popup reopens.
final orgBlockStatusProvider = FutureProvider.autoDispose.family<bool, OrgBlockStatusParams>(
  (final Ref ref, final OrgBlockStatusParams params) async {
    return ref.read(orgAdminServiceProvider).isUserBlocked(
          params.orgLogin,
          params.username,
        );
  },
);
