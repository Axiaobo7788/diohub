import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/l10n/relative_time.dart';
import 'package:diohub/models/repository_document.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/repository/repository_document_provider.dart';
import 'package:diohub/providers/repository/repository_document_resource.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:diohub/view/repository/md3/repository_tab_scaffold.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_models/models/repositories/code_scanning_alert_item.dart';
import 'package:diohub_models/models/repositories/secret_scanning_alert.dart';
import 'package:diohub_models/models/repositories/vulnerability_alert_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

part 'repository_security_widgets.dart';

enum _SecuritySection { overview, dependabot, codeScanning, secretScanning }

class RepositorySecurityMd3Page extends ConsumerStatefulWidget {
  const RepositorySecurityMd3Page({
    required this.repoRef,
    required this.signedIn,
    required this.onRefreshReady,
    this.defaultBranch,
    super.key,
  });

  final RepoRef repoRef;
  final bool signedIn;
  final ValueChanged<Future<void> Function()?> onRefreshReady;
  final String? defaultBranch;

  @override
  ConsumerState<RepositorySecurityMd3Page> createState() =>
      _RepositorySecurityMd3PageState();
}

class _RepositorySecurityMd3PageState
    extends ConsumerState<RepositorySecurityMd3Page> {
  late final PaginationController<
    VulnerabilityAlertEdge,
    VulnerabilityAlertEdge
  >
  _dependabot;
  late final PaginationController<CodeScanningAlertItem, CodeScanningAlertItem>
  _codeScanning;
  late final PaginationController<SecretScanningAlert, SecretScanningAlert>
  _secretScanning;
  _SecuritySection _section = _SecuritySection.overview;

  @override
  void initState() {
    super.initState();
    _dependabot =
        PaginationController<VulnerabilityAlertEdge, VulnerabilityAlertEdge>(
          source: CursorForwardSource<VulnerabilityAlertEdge>(
            fetch: ({required final int first, final String? after}) async {
              final result = await widget.repoRef
                  .stats(ref.read(apiClientProvider))
                  .fetchVulnerabilityAlerts(first: first, after: after);
              return PaginatedResult<VulnerabilityAlertEdge>(
                items: result.items,
                hasNextPage: result.hasNextPage,
                endCursor: result.endCursor,
              );
            },
          ),
          idOf: (final VulnerabilityAlertEdge alert) => alert.node.id,
          pageSize: 30,
          autoFetch: widget.signedIn,
        );
    _codeScanning =
        PaginationController<CodeScanningAlertItem, CodeScanningAlertItem>(
          source: PageNumberForwardSource<CodeScanningAlertItem>(
            fetch:
                ({required final int page, required final int perPage}) async {
                  final result = await widget.repoRef
                      .stats(ref.read(apiClientProvider))
                      .listCodeScanningAlerts(page: page, perPage: perPage);
                  return result.items;
                },
          ),
          idOf: (final CodeScanningAlertItem alert) => '${alert.number}',
          pageSize: 30,
          autoFetch: widget.signedIn,
        );
    _secretScanning =
        PaginationController<SecretScanningAlert, SecretScanningAlert>(
          source: PageNumberForwardSource<SecretScanningAlert>(
            fetch:
                ({required final int page, required final int perPage}) async {
                  return widget.repoRef
                      .services(ref.read(apiClientProvider))
                      .listSecretScanningAlerts(page: page, perPage: perPage);
                },
          ),
          idOf: (final SecretScanningAlert alert) => '${alert.number}',
          pageSize: 30,
          autoFetch: widget.signedIn,
        );
    widget.onRefreshReady(widget.signedIn ? _refresh : null);
  }

  @override
  void didUpdateWidget(final RepositorySecurityMd3Page oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signedIn == widget.signedIn) return;
    widget.onRefreshReady(widget.signedIn ? _refresh : null);
    if (widget.signedIn) {
      unawaited(_refresh(retainItems: false));
    }
  }

  @override
  void dispose() {
    widget.onRefreshReady(null);
    _dependabot.dispose();
    _codeScanning.dispose();
    _secretScanning.dispose();
    super.dispose();
  }

  Future<void> _refresh({final bool retainItems = true}) async {
    final String? defaultBranch = widget.defaultBranch;
    Future<void>? policyRefresh;
    if (_section == _SecuritySection.overview &&
        defaultBranch != null &&
        defaultBranch.isNotEmpty) {
      final RepositoryDocumentRequest request = (
        key: (
          repoRef: widget.repoRef,
          branch: defaultBranch,
          kind: RepositoryDocumentKind.security,
        ),
        consumer: RepositoryDocumentConsumer.security,
      );
      policyRefresh = ref
          .read(repositoryDocumentProvider(request).notifier)
          .refreshResource();
    }
    await switch (_section) {
      _SecuritySection.overview => Future.wait<void>(<Future<void>>[
        if (policyRefresh != null) policyRefresh,
        _dependabot.refresh(retainItems: retainItems),
        _codeScanning.refresh(retainItems: retainItems),
        _secretScanning.refresh(retainItems: retainItems),
      ]),
      _SecuritySection.dependabot => _dependabot.refresh(
        retainItems: retainItems,
      ),
      _SecuritySection.codeScanning => _codeScanning.refresh(
        retainItems: retainItems,
      ),
      _SecuritySection.secretScanning => _secretScanning.refresh(
        retainItems: retainItems,
      ),
    };
  }

  @override
  Widget build(final BuildContext context) {
    if (!widget.signedIn) {
      return RepositoryTabScaffold(
        title: context.l10n.repoSecurity,
        slivers: <Widget>[
          SliverPadding(
            padding: RepositoryMd3Layout.pagePaddingFor(
              RepositoryWindowClass.compact,
            ),
            sliver: SliverToBoxAdapter(
              child: RepositoryTabSignInState(
                onSignIn: () =>
                    unawaited(context.router.push<void>(const AuthRoute())),
              ),
            ),
          ),
        ],
      );
    }
    final List<RepositoryTabNavigationDestination> destinations =
        <RepositoryTabNavigationDestination>[
          RepositoryTabNavigationDestination(
            icon: Icons.shield_outlined,
            label: context.l10n.repoSecurityOverview,
          ),
          RepositoryTabNavigationDestination(
            icon: Icons.inventory_2_outlined,
            label: context.l10n.repoDependabot,
          ),
          RepositoryTabNavigationDestination(
            icon: Icons.rule_folder_outlined,
            label: context.l10n.repoCodeScanning,
          ),
          RepositoryTabNavigationDestination(
            icon: Icons.key_outlined,
            label: context.l10n.repoSecretScanning,
          ),
        ];
    return RepositoryTabScaffold(
      title: destinations[_section.index].label,
      onRefresh: _refresh,
      navigation: RepositoryTabNavigation(
        title: context.l10n.repoSecurity,
        destinations: destinations,
        selectedIndex: _section.index,
        onSelected: _selectSection,
      ),
      compactNavigation: DropdownButtonFormField<_SecuritySection>(
        isExpanded: true,
        initialValue: _section,
        decoration: InputDecoration(
          labelText: context.l10n.repoSecurity,
          prefixIcon: const Icon(Icons.shield_outlined),
        ),
        items: <DropdownMenuItem<_SecuritySection>>[
          for (final _SecuritySection section in _SecuritySection.values)
            DropdownMenuItem<_SecuritySection>(
              value: section,
              child: Text(destinations[section.index].label),
            ),
        ],
        onChanged: (final _SecuritySection? section) {
          if (section != null) _selectSection(section.index);
        },
      ),
      actions: <Widget>[
        IconButton.outlined(
          tooltip: context.l10n.activityRefresh,
          onPressed: () => unawaited(_refresh()),
          icon: const Icon(Icons.refresh),
        ),
      ],
      slivers: _buildSection(),
    );
  }

  void _selectSection(final int index) {
    final _SecuritySection next = _SecuritySection.values[index];
    if (next == _section) return;
    setState(() => _section = next);
  }

  List<Widget> _buildSection() => switch (_section) {
    _SecuritySection.overview => <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          RepositoryMd3Layout.regularPageInset,
          0,
          RepositoryMd3Layout.regularPageInset,
          RepositoryMd3Layout.regularPageInset,
        ),
        sliver: SliverToBoxAdapter(child: _buildOverview()),
      ),
    ],
    _SecuritySection.dependabot => <Widget>[
      _securityListPadding(
        PaginatedSliverList<VulnerabilityAlertEdge>(
          controller: _dependabot,
          itemBuilder:
              (
                final BuildContext context,
                final VulnerabilityAlertEdge edge,
                final int index,
              ) => _SecurityAlertRow(
                icon: Icons.inventory_2_outlined,
                title: edge.node.summary ?? edge.node.packageName,
                subtitle: <String>[
                  edge.node.packageName,
                  edge.node.ecosystem,
                  edge.node.vulnerableVersionRange ?? '',
                ].where((final String value) => value.isNotEmpty).join(' · '),
                severity: edge.node.severity,
                state: edge.node.state,
                url: edge.node.permalink,
                first: index == 0,
              ),
          emptyBuilder: (final BuildContext context) => _empty(
            context,
            Icons.inventory_2_outlined,
            context.l10n.repoNoDependabotAlerts,
          ),
          errorBuilder: _error,
        ),
      ),
    ],
    _SecuritySection.codeScanning => <Widget>[
      _securityListPadding(
        PaginatedSliverList<CodeScanningAlertItem>(
          controller: _codeScanning,
          itemBuilder:
              (
                final BuildContext context,
                final CodeScanningAlertItem alert,
                final int index,
              ) => _SecurityAlertRow(
                icon: Icons.rule_folder_outlined,
                title: alert.ruleName.isEmpty
                    ? alert.ruleDescription
                    : alert.ruleName,
                subtitle:
                    '${alert.toolName} · ${alert.mostRecentInstancePath ?? context.l10n.repoUnknownLocation}',
                severity: alert.securitySeverityLevel ?? alert.severity,
                state: alert.state,
                url: alert.htmlUrl,
                first: index == 0,
              ),
          emptyBuilder: (final BuildContext context) => _empty(
            context,
            Icons.rule_folder_outlined,
            context.l10n.repoNoCodeScanningAlerts,
          ),
          errorBuilder: _error,
        ),
      ),
    ],
    _SecuritySection.secretScanning => <Widget>[
      _securityListPadding(
        PaginatedSliverList<SecretScanningAlert>(
          controller: _secretScanning,
          itemBuilder:
              (
                final BuildContext context,
                final SecretScanningAlert alert,
                final int index,
              ) => _SecurityAlertRow(
                icon: Icons.key_outlined,
                title: alert.secretTypeDisplayName,
                subtitle: formatRelativeTime(context, alert.createdAt),
                severity: context.l10n.repoSecret,
                state: alert.state,
                url: alert.htmlUrl,
                first: index == 0,
              ),
          emptyBuilder: (final BuildContext context) => _empty(
            context,
            Icons.key_outlined,
            context.l10n.repoNoSecretScanningAlerts,
          ),
          errorBuilder: _error,
        ),
      ),
    ],
  };

  Widget _buildOverview() {
    final String? defaultBranch = widget.defaultBranch;
    final AsyncValue<RepositoryDocumentArtifact?>? policy =
        defaultBranch == null || defaultBranch.isEmpty
        ? null
        : ref.watch(
            repositoryDocumentProvider((
              key: (
                repoRef: widget.repoRef,
                branch: defaultBranch,
                kind: RepositoryDocumentKind.security,
              ),
              consumer: RepositoryDocumentConsumer.security,
            )),
          );
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final double width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - RepositoryMd3Layout.space16) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: RepositoryMd3Layout.space16,
          runSpacing: RepositoryMd3Layout.space16,
          children: <Widget>[
            SizedBox(
              width: constraints.maxWidth,
              child: _SecurityPolicyCard(
                value: policy,
                waitingForRepository: defaultBranch == null,
              ),
            ),
            SizedBox(
              width: width,
              child: _SecuritySummaryCard(
                controller: _dependabot,
                icon: Icons.inventory_2_outlined,
                title: context.l10n.repoDependabot,
                onTap: () => _selectSection(_SecuritySection.dependabot.index),
              ),
            ),
            SizedBox(
              width: width,
              child: _SecuritySummaryCard(
                controller: _codeScanning,
                icon: Icons.rule_folder_outlined,
                title: context.l10n.repoCodeScanning,
                onTap: () =>
                    _selectSection(_SecuritySection.codeScanning.index),
              ),
            ),
            SizedBox(
              width: width,
              child: _SecuritySummaryCard(
                controller: _secretScanning,
                icon: Icons.key_outlined,
                title: context.l10n.repoSecretScanning,
                onTap: () =>
                    _selectSection(_SecuritySection.secretScanning.index),
              ),
            ),
          ],
        );
      },
    );
  }

  SliverPadding _securityListPadding(final Widget sliver) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      RepositoryMd3Layout.regularPageInset,
      0,
      RepositoryMd3Layout.regularPageInset,
      RepositoryMd3Layout.regularPageInset,
    ),
    sliver: sliver,
  );

  Widget _empty(
    final BuildContext context,
    final IconData icon,
    final String title,
  ) => RepositoryTabStateCard(
    icon: icon,
    title: title,
    message: context.l10n.repoSecurityNoAlertsBody,
  );

  Widget _error(
    final BuildContext context,
    final Object error,
    final VoidCallback retry,
  ) => RepositoryTabStateCard(
    icon: Icons.lock_outline,
    title: context.l10n.repoSecurityDataUnavailable,
    message: context.l10n.repoSecurityPermissionBody('$error'),
    action: OutlinedButton.icon(
      onPressed: retry,
      icon: const Icon(Icons.refresh),
      label: Text(context.l10n.commonRetry),
    ),
  );
}
