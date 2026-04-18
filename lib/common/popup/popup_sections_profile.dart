import 'package:diohub/common/bottom_sheet/confirm_action_sheet.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/nav_center/models/entity_action_defs.dart';
import 'package:diohub/common/nav_center/models/entity_capability.dart';
import 'package:diohub/common/nav_center/models/entity_capability_renderers.dart';
import 'package:diohub/common/popup/entity_popup_menu.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/organizations/org_admin_providers.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
// ignore: no_view_import_in_common
import 'package:diohub/view/profile/widgets/status_editor_sheet.dart';
// ignore: no_view_import_in_common
import 'package:diohub/view/support_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:share_plus/share_plus.dart';

extension UserProfilePopup on UserProfileOwner {
  List<PopupMenuSection> popupSections(
    final BuildContext context,
    final WidgetRef ref,
  ) =>
      buildProfilePopupSections(context, this, ref);
}

List<PopupMenuSection> buildProfilePopupSections(
  final BuildContext context,
  final UserProfileOwner userData,
  final WidgetRef ref,
) {
  final Uri profileUrl = ref.webUrl('/${userData.login}');
  final ClipboardService clipboard = ref.read(clipboardServiceProvider);

  return userData.maybeWhen(
    user: (final UserProfile user) {
      final List<PopupMenuSection> sections = <PopupMenuSection>[];

      if (!user.isViewer) {
        final List<ActionButtonData> primaryActions = <ActionButtonData>[
          ...followActions(
            isFollowing: user.viewerIsFollowing,
            viewerCanFollow: user.viewerCanFollow,
            onToggle: () async {
              await ref
                  .read(userProvider(UserRef(login: userData.login)).notifier)
                  .changeFollowStatus(
                    user.id,
                    follow: !user.viewerIsFollowing,
                  );
            },
            trailing: Text('${user.followers.totalCount}'),
          ),
        ];

        if (primaryActions.isNotEmpty) {
          sections.add(
            PopupMenuSection(
              style: PopupSectionStyle.primary,
              actions: primaryActions,
            ),
          );
        }

        sections.add(
          PopupMenuSection(
            actions: <ActionButtonData>[
              ReactiveActionButton(
                getValue: (final WidgetRef ref) =>
                    ref.watch(blockStateForUserProvider(user.login)),
                builder: (final Object? value) {
                  final AsyncValue<bool> blocked = value is AsyncValue<bool>
                      ? value
                      : const AsyncValue.loading();
                  final bool isBlocked = blocked.value ?? false;
                  final bool isLoading = blocked.isLoading;
                  return blockAction(
                    isBlocked: isBlocked,
                    isLoading: isLoading,
                    onTapWithDismiss: (final void Function() dismiss) async {
                      if (isBlocked) {
                        await ref
                            .read(userProvider(UserRef(login: user.login))
                                .notifier)
                            .toggleBlock();
                        dismiss();
                      } else {
                        final bool? confirm = await showConfirmAction(
                          context,
                          title: 'Block user?',
                          explanation: 'You won\'t see their activity and they '
                              'won\'t be able to see yours.',
                          confirmLabel: 'Block',
                          isDestructive: true,
                        );
                        if (confirm == true && context.mounted) {
                          await ref
                              .read(userProvider(UserRef(login: user.login))
                                  .notifier)
                              .toggleBlock();
                          dismiss();
                        }
                      }
                    },
                  );
                },
              ),
              if (user.hasSponsorsListing)
                MinorActionButton(
                  label: 'Sponsor',
                  icon: Octicons.heart,
                  dismissBehavior: ActionDismissBehavior.immediate,
                  onTap: () => showSupportPickerSheet(
                    context,
                    user.login,
                    sponsorableId: user.id,
                  ),
                ),
            ],
          ),
        );
      }

      if (user.isViewer) {
        sections.add(
          PopupMenuSection(
            actions: <ActionButtonData>[
              SheetActionButton(
                icon: Icons.emoji_emotions_outlined,
                label: 'Set Status',
                sheetBuilder: (final BuildContext ctx,
                        [ScrollController? scrollController]) =>
                    StatusEditorSheet(userRef: UserRef(login: userData.login)),
              ),
            ],
          ),
        );
      }

      sections.add(
        PopupMenuSection(
          style: PopupSectionStyle.utility,
          actions: utilityActions(
            url: profileUrl.toString(),
            copyUrl: () async => clipboard.copy(profileUrl.toString()),
            share: () => Share.share(profileUrl.toString()),
          ),
        ),
      );
      return sections;
    },
    organization: (final OrgProfile org) {
      final List<PopupMenuSection> sections = <PopupMenuSection>[];
      
      // Primary actions (follow)
      final List<ActionButtonData> primaryActions = <ActionButtonData>[
        ...followActions(
          isFollowing: org.viewerIsFollowing,
          viewerCanFollow: true,
          onToggle: () async {
            await ref
                .read(userProvider(UserRef(login: userData.login)).notifier)
                .changeFollowStatus(org.id, follow: !org.viewerIsFollowing);
          },
          trailing: null,
        ),
      ];
      
      if (primaryActions.isNotEmpty) {
        sections.add(
          PopupMenuSection(
            style: PopupSectionStyle.primary,
            actions: primaryActions,
          ),
        );
      }

      // Block actions for org admins (if viewer has permissions)
      // Get current viewer username from account session
      final accountSession = ref.watch(accountProvider).value;
      final viewerUsername = accountSession?.activeAccount;
      
      if (viewerUsername != null) {
        sections.add(
          PopupMenuSection(
            actions: <ActionButtonData>[
              ReactiveActionButton(
                getValue: (final WidgetRef ref) => ref.watch(
                  orgBlockStatusProvider((
                    orgLogin: org.login,
                    username: viewerUsername,
                  )),
                ),
                builder: (final Object? value) {
                  final AsyncValue<bool> blocked = value is AsyncValue<bool>
                      ? value
                      : const AsyncValue.loading();
                  final bool isBlocked = blocked.value ?? false;
                  final bool isLoading = blocked.isLoading;
                  return blockAction(
                    isBlocked: isBlocked,
                    isLoading: isLoading,
                    onTapWithDismiss: (final void Function() dismiss) async {
                      final service = ref.read(orgAdminServiceProvider);
                      if (isBlocked) {
                        await service.unblockUser(org.login, viewerUsername);
                        ref.invalidate(orgBlockStatusProvider((
                          orgLogin: org.login,
                          username: viewerUsername,
                        )));
                        dismiss();
                      } else {
                        final bool? confirm = await showConfirmAction(
                          context,
                          title: 'Block user from organization?',
                          explanation: 'User $viewerUsername will be blocked at the '
                              'organization level. They won\'t be able to '
                              'interact with ${org.login}\'s repositories.',
                          confirmLabel: 'Block',
                          isDestructive: true,
                        );
                        if (confirm == true && context.mounted) {
                          await service.blockUser(org.login, viewerUsername);
                          ref.invalidate(orgBlockStatusProvider((
                            orgLogin: org.login,
                            username: viewerUsername,
                          )));
                          dismiss();
                        }
                      }
                    },
                  );
                },
              ),
            ],
          ),
        );
      }

      // Utility actions (share, copy URL)
      sections.add(
        PopupMenuSection(
          style: PopupSectionStyle.utility,
          actions: utilityActions(
            url: profileUrl.toString(),
            copyUrl: () => clipboard.copy(profileUrl.toString()),
            share: () => Share.share(profileUrl.toString()),
          ),
        ),
      );

      return sections;
    },
    orElse: () => buildPopupFromCapabilities(
      <EntityCapability>[
        Utility(
          url: profileUrl.toString(),
          copyUrl: () => clipboard.copy(profileUrl.toString()),
          share: () => Share.share(profileUrl.toString()),
        ),
      ],
    ),
  );
}
