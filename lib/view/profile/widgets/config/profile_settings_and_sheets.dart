import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/nav_center/settings/settings_section.dart';
import 'package:diohub/common/nav_center/settings/settings_sheet_action_row.dart';
import 'package:diohub/common/nav_center/settings/settings_text_field_row.dart';
import 'package:diohub/common/nav_center/settings/settings_toggle_row.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/profile/widgets/email_management_sheet.dart';

import 'package:diohub_graphql/queries/users/user_typedefs.dart';

List<Widget> profileSettingsSections(
  BuildContext context,
  WidgetRef ref,
  UserRef profileUserRef,
) {
  const Widget deferredRow = ListTile(
    title: Text('Coming soon'),
    enabled: false,
  );
  final viewer = ref.watch(currentUserProvider).value;
  final bool isViewer = viewer?.login == profileUserRef.login;
  final AsyncValue<UserProfileData> profileAsync =
      ref.watch(userProvider(profileUserRef));

  if (!isViewer) {
    return [
      SettingsSection(
        title: 'Profile',
        icon: Icons.person_outline_rounded,
        children: const [deferredRow],
      ),
      SettingsSection(
        title: 'Social',
        icon: Icons.people_outline_rounded,
        children: const [deferredRow],
      ),
    ];
  }

  return profileAsync.maybeWhen(
    loading: () => [
      SettingsSection(
        title: 'Profile',
        icon: Icons.person_outline_rounded,
        children: const [deferredRow],
      ),
      SettingsSection(
        title: 'Social',
        icon: Icons.people_outline_rounded,
        children: const [deferredRow],
      ),
    ],
    error: (_, __) => [
      SettingsSection(
        title: 'Profile',
        icon: Icons.person_outline_rounded,
        children: const [deferredRow],
      ),
      SettingsSection(
        title: 'Social',
        icon: Icons.people_outline_rounded,
        children: const [deferredRow],
      ),
    ],
    data: (UserProfileData profile) {
      final UserProfileOwner owner = profile.owner;
      final UserProfile? user = owner.maybeWhen(
        user: (UserProfile u) => u,
        organization: (_) => null,
        orElse: () => null,
      );
      if (user == null) {
        return [
          SettingsSection(
            title: 'Profile',
            icon: Icons.person_outline_rounded,
            children: const [deferredRow],
          ),
          SettingsSection(
            title: 'Social',
            icon: Icons.people_outline_rounded,
            children: const [deferredRow],
          ),
        ];
      }
      final UserProfileNotifier notifier =
          ref.read(userProvider(profileUserRef).notifier);
      final List<Widget> profileRows = <Widget>[
        SettingsTextFieldRow(
          label: 'Name',
          value: user.name ?? '',
          onMutate: (String v) => notifier.updateProfileField('name', v),
        ),
        SettingsTextFieldRow(
          label: 'Bio',
          value: user.bio ?? '',
          maxLines: 3,
          onMutate: (String v) => notifier.updateProfileField('bio', v),
        ),
        SettingsTextFieldRow(
          label: 'Company',
          value: user.company ?? '',
          onMutate: (String v) => notifier.updateProfileField('company', v),
        ),
        SettingsTextFieldRow(
          label: 'Location',
          value: user.location ?? '',
          onMutate: (String v) => notifier.updateProfileField('location', v),
        ),
        SettingsTextFieldRow(
          label: 'Blog',
          value: user.websiteUrl?.toString() ?? '',
          onMutate: (String v) => notifier.updateProfileField('blog', v),
        ),
        SettingsTextFieldRow(
          label: 'Twitter',
          value: user.twitterUsername ?? '',
          onMutate: (String v) =>
              notifier.updateProfileField('twitter_username', v),
        ),
        SettingsTextFieldRow(
          label: 'Email',
          value: user.email,
          onMutate: (String v) => notifier.updateProfileField('email', v),
        ),
        SettingsToggleRow(
          label: 'Hireable',
          value: user.isHireable,
          onMutate: (bool v) => notifier.updateProfileField('hireable', v),
        ),
      ];
      final bool canEdit = isViewer;
      final ThemeData theme = Theme.of(context);
      final List<Widget> socialRows = <Widget>[
        SettingsTextFieldRow(
          label: 'Twitter',
          value: user.twitterUsername ?? '',
          onMutate: canEdit
              ? (String v) => notifier.updateProfileField('twitter_username', v)
              : (_) async {},
        ),
        SettingsTextFieldRow(
          label: 'Website',
          value: user.websiteUrl?.toString() ?? '',
          onMutate: canEdit
              ? (String v) => notifier.updateProfileField('blog', v)
              : (_) async {},
        ),
        ListTile(
          title: const Text('Sponsoring'),
          trailing: Text(
            '${user.sponsoring.totalCount}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ListTile(
          title: const Text('Sponsors'),
          trailing: Text(
            '${user.sponsors.totalCount}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
      return [
        SettingsSection(
          title: 'Profile',
          icon: Icons.person_outline_rounded,
          children: profileRows,
        ),
        SettingsSection(
          title: 'Email Addresses',
          icon: Icons.email_outlined,
          children: [
            SettingsSheetActionRow(
              label: 'Manage emails',
              onTap: () =>
                  showEmailManagementSheet(context, ref, userRef: profileUserRef),
            ),
          ],
        ),
        SettingsSection(
          title: 'Social',
          icon: Icons.people_outline_rounded,
          children: socialRows,
        ),
      ];
    },
    orElse: () => [
      SettingsSection(
        title: 'Profile',
        icon: Icons.person_outline_rounded,
        children: const [deferredRow],
      ),
    ],
  );
}
