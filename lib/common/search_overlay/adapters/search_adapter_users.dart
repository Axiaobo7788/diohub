import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/misc/profile_card.dart';
import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/profile_card_input.dart';
import 'package:diohub/services/global_services.dart';
import 'package:flutter/material.dart';
import 'package:diohub/utils/timeline/timeline_node_id.dart';

final class UserSearchAdapter extends SearchTypeAdapter<ProfileCardInput> {
  UserSearchAdapter(super.ref);

  String? _cursor;
  bool _hasNextPage = true;

  @override
  Future<PageSlice<ProfileCardInput>> fetchSlice({
    required String query,
    required int count,
    void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    if (!_hasNextPage) {
      return const PageSlice<ProfileCardInput>(
          items: <ProfileCardInput>[], hasNextPage: false);
    }
    final page = await ref.read(globalServicesProvider).search.searchUsers(
      query,
      first: count,
      after: _cursor,
      onRawResponse: onRawResponse,
    );
    _cursor = page.endCursor;
    _hasNextPage = page.hasNextPage;
    return PageSlice<ProfileCardInput>(
      items: page.items,
      hasNextPage: page.hasNextPage,
    );
  }

  @override
  void resetState() {
    _cursor = null;
    _hasNextPage = true;
  }

  @override
  Widget buildItem(BuildContext context, ProfileCardInput item, int index) {
    return BorderedContainer(
      ref: UserRef(login: item.login),
      child: ProfileCard(item),
    );
  }

  @override
  Widget buildLoadingShimmer(BuildContext context) =>
      ListLoadingShimmers.userList(context);

  @override
  String itemId(ProfileCardInput item) => timelineNodeIdOf(item) ?? item.login;
}
