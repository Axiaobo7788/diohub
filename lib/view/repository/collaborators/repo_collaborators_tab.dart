import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/search/search_filter_providers.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/collaborator_item.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart';

/// Wrapper to carry next-page cursor for REST page-based pagination.
class _CollaboratorPageItem {
  _CollaboratorPageItem(this.item, this.nextPageCursor);

  final CollaboratorItem item;
  final String? nextPageCursor;
}

const int _pageSize = 30;

/// Returns a [SliverListBody] for the collaborators list on a repo (admin only).
TabBody createCollaboratorsBody(
  WidgetRef ref,
  RepoRef repoRef, {
  ValueNotifier<String>? queryNotifier,
}) {
  return SliverListBody<_CollaboratorPageItem>.textFilter(
    getCursor: (item) => item?.nextPageCursor,
    queryNotifier: queryNotifier,
    strategy: ref.watch(matchStrategyProvider),
    fields: [(pageItem) => pageItem.item.login],
    fetcher:
        ({String? after, int first = _pageSize, bool refresh = false}) async {
          final int page = refresh
              ? 1
              : (after != null ? int.tryParse(after) ?? 1 : 1);
          final apiClient = ref.read(apiClientProvider);
          final result = await repoRef
              .collaborators(apiClient)
              .listCollaborators(page: page, perPage: first);
          final String? nextCursor =
              result.hasNextPage && result.endCursor != null
              ? result.endCursor
              : null;
          final List<_CollaboratorPageItem> wrapped = <_CollaboratorPageItem>[];
          for (int i = 0; i < result.items.length; i++) {
            wrapped.add(
              _CollaboratorPageItem(
                result.items[i],
                i == result.items.length - 1 ? nextCursor : null,
              ),
            );
          }
          return PaginatedResult<_CollaboratorPageItem>(
            items: wrapped,
            hasNextPage: result.hasNextPage,
            endCursor: nextCursor,
          );
        },
    itemBuilder: (BuildContext context, _CollaboratorPageItem pageItem) {
      final CollaboratorItem item = pageItem.item;
      final UserRef userRef = UserRef(login: item.login);
      return BorderedContainer(
        ref: userRef,
        padding: context.spacing.contentPadding,
        child: Row(
          children: <Widget>[
            UserAvatar(avatarUrl: item.avatarUrl, size: 48),
            SizedBox(width: context.spacing.itemSpacing),
            Expanded(
              child: Text(
                item.login,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            _PermissionChip(permissions: item.permissions),
          ],
        ),
      );
    },
  );
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({required this.permissions});

  final CollaboratorPermissions permissions;

  static String _label(CollaboratorPermissions p) {
    if (p.admin) return 'Admin';
    if (p.maintain) return 'Maintain';
    if (p.push) return 'Write';
    if (p.triage) return 'Triage';
    if (p.pull) return 'Read';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return TintedChip(
      icon: Icons.security_rounded,
      label: _label(permissions),
      color: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}
