import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:diohub/common/nav_center/settings/settings_enum_row.dart';
import 'package:diohub/common/nav_center/settings/settings_section.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';

List<Widget> repoSettingsSections(
  BuildContext context,
  WidgetRef ref,
  RepoRef repoRef,
  RepoInfo repo,
) {
  final notifier = ref.read(repositoryProvider(repoRef).notifier);

  return [
    if (repo.viewerCanSubscribe == true)
      SettingsSection(
        title: 'Notifications',
        icon: Octicons.bell,
        children: <Widget>[
          SettingsEnumRow<SubscriptionState>(
            label: 'Watch',
            leadingIcon: Octicons.bell,
            value: repo.viewerSubscription ?? SubscriptionState.UNSUBSCRIBED,
            options: SubscriptionState.values
                .map(
                  (SubscriptionState s) => EnumOption<SubscriptionState>(
                    value: s,
                    label: switch (s) {
                      SubscriptionState.SUBSCRIBED => 'All Activity',
                      SubscriptionState.IGNORED => 'Ignore',
                      _ => 'Participating',
                    },
                    icon: switch (s) {
                      SubscriptionState.SUBSCRIBED => Octicons.bell_fill,
                      SubscriptionState.IGNORED => Octicons.bell_slash,
                      _ => Octicons.bell,
                    },
                  ),
                )
                .toList(),
            onMutate: (SubscriptionState s) => notifier.toggleWatch(s),
          ),
        ],
      ),
  ];
}
