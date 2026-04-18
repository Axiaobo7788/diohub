import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for [filterDataProvider]: [cacheKey] from [SearchScope.cacheKey],
/// [sectionId] from [FilterSectionDef.id].
typedef FilterDataKey = ({String cacheKey, String sectionId});

/// Normalized list of options for dynamic pickers (labels, assignees, milestones, branches, orgs).
class FilterDataOptions {
  FilterDataOptions(this.options);
  final List<FilterOption> options;
}

/// Loads dynamic options for a filter section (labels, assignees, milestones,
/// branches, orgs). Cached per (contextKey, sectionId). Call with
/// (scope.cacheKey, sectionId).
///
/// Repo context: label → listAvailableLabelsGQL, assignee → listAssignableUsersGQL,
/// milestone → listMilestonesGQL, base/head → fetchBranchListGQL.
/// Home context: org → UserInfoService.getViewerOrgs().
/// User profile context: org → getUserOrganizations(login).
final filterDataProvider =
    FutureProvider.autoDispose.family<FilterDataOptions?, FilterDataKey>(
  (final Ref ref, final FilterDataKey key) => loadFilterData(ref, key),
);

/// Fetches dynamic options for the given (cacheKey, sectionId).
///
/// Repo-scoped pickers (label, assignee, milestone, base, head) are not
/// preloaded here; the filter sheet opens [PaginatedSelectSheet] on tap instead.
Future<FilterDataOptions?> loadFilterData(
    final Ref ref, final FilterDataKey key) async {
  final String cacheKey = key.cacheKey;
  final String sectionId = key.sectionId;
  if (cacheKey.startsWith('repo:')) {
    switch (sectionId) {
      case 'label':
      case 'assignee':
      case 'milestone':
      case 'base':
      case 'head':
        return null;
      default:
        return null;
    }
  }
  if (cacheKey.startsWith('home:')) {
    if (sectionId == 'org') {
      final edges =
          await ref.read(userInfoServiceProvider).getViewerOrgs(refresh: false);
      final List<FilterOption> options = edges
          .whereType<ViewerOrgEdge>()
          .map((e) {
            final node = e.node;
            final login = node?.login ?? '';
            final display =
                (node?.name?.isNotEmpty == true) ? node!.name! : login;
            return FilterOption(display, login);
          })
          .where((o) => o.value.isNotEmpty)
          .toList();
      return FilterDataOptions(options);
    }
    return null;
  }
  if (cacheKey.startsWith('user:')) {
    final String login = cacheKey.substring(5);
    if (sectionId == 'org') {
      final edges = await ref
          .read(userInfoServiceProvider)
          .getUserOrganizations(login, refresh: false);
      final List<FilterOption> options = edges
          .whereType<UserOrgEdge>()
          .map((e) {
            final node = e.node;
            final orgLogin = node?.login ?? '';
            final display =
                (node?.name?.isNotEmpty == true) ? node!.name! : orgLogin;
            return FilterOption(display, orgLogin);
          })
          .where((o) => o.value.isNotEmpty)
          .toList();
      return FilterDataOptions(options);
    }
    return null;
  }
  return null;
}
