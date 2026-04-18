import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/organizations/org_admin_providers.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/organizations/pat_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';

const int _pageSize = 30;

/// Returns a [SliverListBody] for PAT requests on an org profile.
TabBody createPatRequestsBody(WidgetRef ref, UserRef orgRef) {
  return SliverListBody<PatRequest>(
    getCursor: (item) => item?.id.toString(),
    fetcher: ({
      String? after,
      int first = _pageSize,
      bool refresh = false,
    }) async {
      final int page = after != null ? int.tryParse(after) ?? 1 : 1;
      final result = await ref.read(orgAdminServiceProvider).listPatRequests(
            orgRef.login,
            page: page,
            perPage: first,
            state: 'pending',
          );
      return result;
    },
    itemBuilder: (BuildContext context, PatRequest item) {
      return BorderedContainer(
        ref: null,
        child: PatRequestCard(item: item, orgLogin: orgRef.login),
      );
    },
  );
}

class PatRequestCard extends ConsumerStatefulWidget {
  const PatRequestCard({
    required this.item,
    required this.orgLogin,
    super.key,
  });

  final PatRequest item;
  final String orgLogin;

  @override
  ConsumerState<PatRequestCard> createState() => _PatRequestCardState();
}

class _PatRequestCardState extends ConsumerState<PatRequestCard> {
  bool _isProcessing = false;

  Future<void> _handleApprove() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await ref.read(orgAdminServiceProvider).approvePatRequest(
            widget.orgLogin,
            widget.item.id,
          );
      
      if (mounted) {
        ref.read(notificationServiceProvider).success(
              'Approved PAT request from ${widget.item.owner}',
            );
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider).error('Failed to approve: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleDeny() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await ref.read(orgAdminServiceProvider).denyPatRequest(
            widget.orgLogin,
            widget.item.id,
          );
      
      if (mounted) {
        ref.read(notificationServiceProvider).success(
              'Denied PAT request from ${widget.item.owner}',
            );
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider).error('Failed to deny: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.item.ownerAvatarUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    widget.item.ownerAvatarUrl!,
                    width: 32,
                    height: 32,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.owner,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.item.tokenName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Created: ${dateFormat.format(widget.item.createdAt)}',
            style: theme.textTheme.bodySmall,
          ),
          if (widget.item.tokenLastUsedAt != null)
            Text(
              'Last used: ${dateFormat.format(widget.item.tokenLastUsedAt!)}',
              style: theme.textTheme.bodySmall,
            ),
          if (widget.item.permissions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Permissions: ${widget.item.permissions.entries.map((e) => '${e.key}:${e.value}').join(', ')}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (widget.item.repositories != null && widget.item.repositories!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Repositories: ${widget.item.repositories!.length}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (widget.item.reason != null && widget.item.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${widget.item.reason}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _isProcessing ? null : _handleDeny,
                icon: _isProcessing
                    ? const ButtonSpinner(size: 16)
                    : const Icon(Octicons.x, size: 16),
                label: const Text('Deny'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isProcessing ? null : _handleApprove,
                icon: _isProcessing
                    ? const ButtonSpinner(size: 16)
                    : const Icon(Octicons.check, size: 16),
                label: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
