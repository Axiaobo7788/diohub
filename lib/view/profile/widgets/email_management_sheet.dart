import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/settings_toggle.dart';
import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub/common/bottom_sheet/paginated_list_sheet.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/pagination/item_patch.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/riverpod/delete_confirm_mutation_icon.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/models/users/email_item.dart';
import 'package:diohub/providers/profile/delete_email_mutation_provider.dart'
    show addEmailMutationProvider, deleteEmailMutationProvider;
import 'package:diohub/providers/users/email_visibility_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showEmailManagementSheet(
  BuildContext context,
  WidgetRef ref, {
  required UserRef userRef,
}) async {
  await AppSheet.scrollable<void>(
    context,
    header: AppSheetHeader.text('Email Addresses'),
    bodyBuilder: (ctx, setState, scrollController) =>
        PaginatedListSheetBody<EmailItem>(
      scrollController: scrollController,
      createController: () {
        int page = 1;
        return PaginationController<EmailItem, EmailItem>(
          source: SliceForwardSource<EmailItem>(
            fetch: (int count) async {
              final result = await ref
                  .read(viewerSettingsServiceProvider)
                  .listEmails(
                page: page,
                perPage: count,
              );
              page++;
              return PageSlice<EmailItem>(
                items: result.items,
                hasNextPage: result.hasNextPage,
              );
            },
            resetState: () => page = 1,
          ),
          idOf: (EmailItem e) => e.email,
          pageSize: 20,
        );
      },
      itemBuilder: (context, ref, email, index, applyPatch) {
        final spacing = context.spacing;
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(bottom: spacing.itemSpacing),
          child: BorderedContainer(
            padding: spacing.cardContentPadding,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email.email,
                        style: theme.textTheme.titleSmall,
                      ),
                      SizedBox(height: spacing.tightSpacing),
                      Wrap(
                        spacing: spacing.compactSpacing,
                        runSpacing: spacing.tightSpacing,
                        children: [
                          if (email.primary)
                            TintedChip(
                              label: 'Primary',
                              color: theme.colorScheme.primary,
                            ),
                          if (email.verified)
                            TintedChip(
                              label: 'Verified',
                              color: theme.colorScheme.primary,
                              icon: Icons.verified_rounded,
                            )
                          else
                            TintedChip(
                              label: 'Unverified',
                              color: theme.colorScheme.error,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!email.primary)
                  DeleteConfirmMutationIcon(
                    mutation: ref.watch(deleteEmailMutationProvider(
                        (user: userRef, email: email.email))),
                    onDelete: () {
                      ref
                          .read(deleteEmailMutationProvider(
                                  (user: userRef, email: email.email))
                              .notifier)
                          .delete(
                            onSuccess: () =>
                                applyPatch(PatchDeleted(email.email)),
                          );
                    },
                    confirmTitle: 'Remove email',
                  ),
              ],
            ),
          ),
        );
      },
      emptyBuilder: (context) {
        final spacing = context.spacing;
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(top: spacing.sectionSpacing),
          child: Text(
            'No emails yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
      trailingBuilder: (refresh) =>
          _AddEmailForm(userRef: userRef, onAdded: refresh),
    ),
  );
}

class _AddEmailForm extends ConsumerStatefulWidget {
  const _AddEmailForm({
    required this.userRef,
    required this.onAdded,
  });

  final UserRef userRef;
  final VoidCallback onAdded;

  @override
  ConsumerState<_AddEmailForm> createState() => _AddEmailFormState();
}

class _AddEmailFormState extends ConsumerState<_AddEmailForm> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _controller.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter an email address');
      return;
    }
    setState(() => _error = null);
    await ref.read(addEmailMutationProvider(widget.userRef).notifier).add(
          email,
          onSuccess: () {
            if (mounted) {
              widget.onAdded();
              _controller.clear();
            }
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final emailVisibility = ref.watch(emailVisibilityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        emailVisibility.when(
          data: (final bool isPublic) => SettingsToggle(
            title: 'Public email',
            value: isPublic,
            onChanged: (_) =>
                ref.read(emailVisibilityProvider.notifier).toggle(),
            icon: Icons.visibility,
            subtitle: 'Show your primary email on your profile',
          ),
          loading: () => const ListTile(
            title: Text('Public email'),
            trailing: CircularProgressIndicator.adaptive(),
          ),
          error: (final Object e, final _) => ListTile(
            title: const Text('Public email'),
            subtitle: Text('Failed to load: $e'),
          ),
        ),
        SizedBox(height: spacing.sectionSpacing),
        Text('Add email', style: theme.textTheme.titleSmall),
        SizedBox(height: spacing.tightSpacing),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) ...[
          SizedBox(height: spacing.tightSpacing),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        SizedBox(height: spacing.itemSpacing),
        SubmitButton(
          onSubmit: _submit,
          onSuccess: () {
            widget.onAdded();
            _controller.clear();
          },
          onError: (e) => setState(() => _error = e.toString()),
          label: (isSubmitting) =>
              Text(isSubmitting ? 'Adding...' : 'Add email'),
        ),
      ],
    );
  }
}
