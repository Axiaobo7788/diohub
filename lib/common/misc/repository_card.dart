import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/app/settings/card_display.dart';
import 'package:diohub/common/cards/branch_refs.dart';
import 'package:diohub/common/cards/chip_priority.dart';
import 'package:diohub/common/cards/chips/metadata_chips_base.dart';
import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/cards/popup_chip_builders.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/entity_header.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/fragments/repo_card_fields.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/common/cards/chips/activity_pulse_dot.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/lang_colors/get_language_color.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart' show Placement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Star chip backed by full repository data while sharing the lightweight
/// mutation state used by card and profile surfaces.
class RepoStarChipFromProvider extends ConsumerWidget {
  const RepoStarChipFromProvider({
    required this.repoRef,
    super.key,
  });

  final RepoRef repoRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final asyncRepo = ref.watch(repositoryProvider(repoRef));
    return asyncRepo.when(
      data: (final RepoInfoData data) {
        final repo = data.repository;
        if (repo == null)
          return RepoStarChip(
              repo: repoRef, initialStarCount: 0, initialIsStarred: false);
        return RepoStarChipFromData(
          repoRef: repoRef,
          repoNodeId: repo.id,
          initialStarCount: repo.stargazerCount,
          initialIsStarred: repo.viewerHasStarred,
        );
      },
      loading: () => RepoStarChip(
        repo: repoRef,
        initialStarCount: 0,
        initialIsStarred: false,
      ),
      error: (final _, final __) => RepoStarChip(
        repo: repoRef,
        initialStarCount: 0,
        initialIsStarred: false,
      ),
    );
  }
}

/// Star chip seeded by an existing lightweight/full query. Mutations are
/// shared by [RepoRef] and do not initialize [repositoryProvider].
class RepoStarChipFromData extends ConsumerWidget {
  const RepoStarChipFromData({
    required this.repoRef,
    required this.repoNodeId,
    required this.initialStarCount,
    required this.initialIsStarred,
    super.key,
  });

  final RepoRef repoRef;
  final String repoNodeId;
  final int initialStarCount;
  final bool initialIsStarred;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final RepositoryStarState starState = ref.watch(
      repositoryStarProvider(repoRef),
    );
    final result = starState.result;
    final bool isStarred = result?.viewerHasStarred ?? initialIsStarred;
    final int count = result?.stargazerCount ?? initialStarCount;
    final RepositoryStarFeedbackMessages feedbackMessages =
        RepositoryStarFeedbackMessages(
          starred: context.l10n.repoStarredFeedback,
          unstarred: context.l10n.repoUnstarredFeedback,
          updateFailed: context.l10n.repoStarUpdateError,
        );
    return RepoStarChip(
      repo: repoRef,
      initialStarCount: count,
      initialIsStarred: isStarred,
      onTap: starState.isMutating
          ? null
          : () async {
              await ref
                  .read(repositoryStarProvider(repoRef).notifier)
                  .toggle(
                    repoNodeId: repoNodeId,
                    currentIsStarred: isStarred,
                    currentCount: count,
                    feedbackMessages: feedbackMessages,
                  );
            },
    );
  }
}

/// Displays star count and starred state. When [onTap] is non-null, tapping
/// toggles the star (caller is responsible for updating state, e.g. via
/// [repositoryProvider] notifier).
class RepoStarChip extends StatefulWidget {
  const RepoStarChip({
    required this.repo,
    required this.initialStarCount,
    this.initialIsStarred,
    this.onTap,
    super.key,
  });

  final RepoRef repo;
  final int initialStarCount;
  final bool? initialIsStarred;
  final VoidCallback? onTap;

  @override
  State<RepoStarChip> createState() => _RepoStarChipState();
}

class _RepoStarChipState extends State<RepoStarChip> {
  late int _starCount;
  bool? _isStarred;

  @override
  void initState() {
    super.initState();
    _starCount = widget.initialStarCount;
    _isStarred = widget.initialIsStarred;
  }

  @override
  void didUpdateWidget(covariant final RepoStarChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repo != widget.repo) {
      _starCount = widget.initialStarCount;
      _isStarred = widget.initialIsStarred;
    } else if (oldWidget.initialStarCount != widget.initialStarCount) {
      _starCount = widget.initialStarCount;
    }
    if (oldWidget.initialIsStarred != widget.initialIsStarred) {
      _isStarred = widget.initialIsStarred;
    }
  }

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final bool isStarred = _isStarred ?? false;
    final Color accent = isStarred
        ? const Color(0xFFFFC107)
        : context.colorScheme.onSurfaceVariant;
    final Color foreground =
        isStarred ? accent : context.colorScheme.onSurface.secondary;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: context.radius(RadiusSize.small),
        child: Container(
          padding: spacing.chipPadding,
          decoration: BoxDecoration(
            color: isStarred ? accent.tintMedium : Colors.transparent,
            borderRadius: context.radius(RadiusSize.small),
            border: Border.all(
              color: isStarred
                  ? Colors.transparent
                  : context.colorScheme.onSurfaceVariant.tintMedium,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContentSwitcher(
                transition: AnimationTransition.fadeScale,
                duration: kMicroDuration,
                child: Icon(
                  isStarred ? Octicons.star_fill : Octicons.star,
                  key: ValueKey<bool>(isStarred),
                  size: 12,
                  color: foreground,
                ),
              ),
              spacing.tightGap,
              AnimatedContentSwitcher(
                transition: AnimationTransition.fade,
                duration: kMicroDuration,
                child: Text(
                  _starCount.toShortenedStr(),
                  key: ValueKey<int>(_starCount),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RepositoryCard extends ConsumerWidget {
  const RepositoryCard(
    this.repo, {
    this.showOwner = true,
    this.starChip,
    super.key,
  });

  final RepoCardData repo;

  final bool showOwner;

  /// When non-null, this widget is used for the star chip instead of
  /// [RepoStarChip] with initial values from [repo]. Use [RepoStarChipFromProvider]
  /// when the card is backed by [repositoryProvider].
  final Widget? starChip;

  Widget repoUnthemedWidget(final BuildContext context, final WidgetRef ref) {
    final settings = ref.watch(cardDisplayProvider);
    final RepoCardData r = repo;
    
    // Extract owner info
    final String ownerLogin = r.owner.when(
      organization: (o) => o.login,
      user: (u) => u.login,
      orElse: () => '',
    );
    
    final String ownerAvatarUrl = r.owner.when(
      organization: (o) => o.avatarUrl.toString(),
      user: (u) => u.avatarUrl.toString(),
      orElse: () => '',
    );
    
    final RepoRef repoRef = RepoRef(owner: ownerLogin, name: r.name);
    
    // Build title: EntityHeader with owner/name on separate lines
    final Widget title = EntityHeader(
      avatarUrl: ownerAvatarUrl,
      title: r.name,
      subtitle: showOwner ? ownerLogin : null,
      showAvatar: showOwner,
      onTap: () => repoRef.navigate(context, ref),
    );
    
    // Build titlePrefix: activity pulse dot (coexists with avatar in EntityHeader)
    Widget? titlePrefix;
    if (settings.showActivityPulse) {
      titlePrefix = ActivityPulseDot(
        pushedAt: r.pushedAt,
        isArchived: r.isArchived,
      );
    }
    
    // Build trailing: star chip
    final Widget trailing = starChip ??
        RepoStarChip(
          repo: repoRef,
          initialStarCount: r.stargazerCount,
          initialIsStarred: r.viewerHasStarred,
        );
    
    // Build chips with priority
    final allChips = _buildPrioritizedChips(context, ref, r, settings, repoRef);
    final maxVisible = settings.effectiveMaxChips;
    final chips = buildChipSection(
      chips: allChips,
      maxVisible: maxVisible,
    );
    
    // Build supplementary: description + topics
    Widget? supplementary;
    final hasDescription = r.description != null && r.description!.isNotEmpty;
    final List<String> topicNames = <String>[];
    for (final e in r.repositoryTopics.edges ?? <RepoCardTopicEdge?>[]) {
      final name = e?.node?.topic.name;
      if (name != null) topicNames.add(name);
    }
    final hasTopics = settings.showTopics && topicNames.isNotEmpty;
    
    if (hasDescription || hasTopics) {
      supplementary = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDescription)
            Text(
              r.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.9),
              ),
            ),
          if (hasTopics) ...[
            if (hasDescription) SizedBox(height: context.spacing.tightSpacing),
            Wrap(
              spacing: context.spacing.chipGap,
              runSpacing: context.spacing.chipGap,
              children: _buildTopicChips(context, ref, topicNames),
            ),
          ],
        ],
      );
    }
    
    return EntityCardLayout(
      titlePrefix: titlePrefix,
      title: title,
      trailing: trailing,
      chips: chips.isNotEmpty ? chips : null,
      supplementary: supplementary,
    );
  }
  
  List<PrioritizedChip> _buildPrioritizedChips(
    BuildContext context,
    WidgetRef ref,
    RepoCardData r,
    CardDisplaySettings settings,
    RepoRef repoRef,
  ) {
    final String? language = r.primaryLanguage?.name;
    final bool hasLanguage = language != null && language.isNotEmpty;
    final bool hasLicense = r.licenseInfo?.spdxId != null;
    final int openIssues = r.issues.totalCount;
    final int openPRs = r.pullRequests.totalCount;
    final int watcherCount = r.watchers.totalCount;
    final String? defaultBranchName = r.defaultBranchRef?.name;
    final bool showDefaultBranch = defaultBranchName != null &&
        defaultBranchName != 'main' &&
        defaultBranchName != 'master';
    final bool showCreated =
        r.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)));
    
    final List<LanguageBarItem> languageBarItems = [
      for (final RepoCardLanguageEdge e
          in (r.languages?.edges ?? const <RepoCardLanguageEdge?>[])
              .whereType<RepoCardLanguageEdge>())
        LanguageBarItem(
          name: e.node.name,
          colorHex: e.node.color,
          size: e.size,
        ),
    ];
    final bool hasLanguages = languageBarItems.isNotEmpty;
    
    // Extract topic names (for supplementary section, not chips)
    final List<String> topicNames = <String>[];
    for (final e in r.repositoryTopics.edges ?? <RepoCardTopicEdge?>[]) {
      final name = e?.node?.topic.name;
      if (name != null) topicNames.add(name);
    }
    
    return [
      // Critical: Language
      if (settings.showRepoLanguage && hasLanguage)
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: hasLanguages
              ? PopupButton(
                  placement: Placement.bottom,
                  buttonBuilder: (context, showMenu) => GestureDetector(
                    onTap: showMenu,
                    child: _languageChip(context, language),
                  ),
                  popupBuilder: (context, onDismiss) =>
                      buildLanguagePopupContent(
                    context,
                    onDismiss: onDismiss,
                    languages: languageBarItems,
                  ),
                )
              : _languageChip(context, language),
        ),
      
      // High: Fork source
      if (r.isFork && r.parent != null)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (context, showMenu) => GestureDetector(
              onTap: showMenu,
              child: _statusChip(
                context,
                icon: Octicons.repo_forked,
                label: r.parent!.nameWithOwner,
              ),
            ),
            popupBuilder: (context, onDismiss) => buildForkSourcePopupContent(
              context,
              onDismiss: onDismiss,
              repoName: r.parent!.name,
              ownerLogin: r.parent!.owner.login,
              description: r.parent!.description,
              starCount: r.parent!.stargazerCount,
              onViewRepository: () {
                onDismiss();
                RepoRef(owner: r.parent!.owner.login, name: r.parent!.name)
                    .navigate(context, ref);
              },
            ),
          ),
        ),
      
      // High: Last push
      if (r.pushedAt != null)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: _statusChip(
            context,
            icon: Octicons.git_commit,
            label: r.pushedAt!.toRelativeDate(shorten: true),
          ),
        ),
      
      // Medium: Stats
      if (settings.showRepoStats && r.forkCount > 0)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: _statusChip(
            context,
            icon: Octicons.repo_forked,
            label: NumberFormat.compact().format(r.forkCount),
          ),
        ),
      if (settings.showRepoStats && openIssues > 0)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: _statusChip(
            context,
            icon: Octicons.issue_opened,
            label: NumberFormat.compact().format(openIssues),
          ),
        ),
      if (settings.showRepoStats && openPRs > 0)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: _statusChip(
            context,
            icon: Octicons.git_pull_request,
            label: NumberFormat.compact().format(openPRs),
          ),
        ),
      if (settings.showRepoStats && watcherCount > 0)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: _statusChip(
            context,
            icon: Octicons.eye,
            label: NumberFormat.compact().format(watcherCount),
          ),
        ),
      
      // Medium: License
      if (hasLicense)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (context, showMenu) => GestureDetector(
              onTap: showMenu,
              child: _statusChip(
                context,
                icon: Octicons.law,
                label: r.licenseInfo!.spdxId,
              ),
            ),
            popupBuilder: (context, onDismiss) => buildLicensePopupContent(
              context,
              onDismiss: onDismiss,
              spdxId: r.licenseInfo!.spdxId!,
              fullName: r.licenseInfo!.name,
              description: r.licenseInfo!.description,
              permissions: r.licenseInfo!.permissions
                  .whereType<RepoCardLicensePermission>()
                  .map((e) => (key: e.key, label: e.label))
                  .toList(),
              conditions: r.licenseInfo!.conditions
                  .whereType<RepoCardLicenseCondition>()
                  .map((e) => (key: e.key, label: e.label))
                  .toList(),
              limitations: r.licenseInfo!.limitations
                  .whereType<RepoCardLicenseLimitation>()
                  .map((e) => (key: e.key, label: e.label))
                  .toList(),
            ),
          ),
        ),
      
      // Low: Status badges
      if (r.isPrivate)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: _statusChip(context, icon: Octicons.lock),
        ),
      if (r.isArchived)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: _statusChip(context, icon: Octicons.archive, label: 'Archived'),
        ),
      if (r.isMirror)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: _statusChip(context, icon: Octicons.mirror, label: 'Mirror'),
        ),
      if (r.isTemplate)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: _statusChip(context, icon: Octicons.repo_template, label: 'Template'),
        ),
      
      // Low: Homepage
      if (r.homepageUrl != null)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: _homepageChip(context, r.homepageUrl!),
        ),
      
      // Low: Default branch
      if (settings.showDefaultBranch && showDefaultBranch)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: BranchRefPill(branchName: defaultBranchName),
        ),
      
      // Low: Created date
      if (showCreated)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: _statusChip(
            context,
            icon: Octicons.calendar,
            label: 'Created ${r.createdAt.toRelativeDate(shorten: true)}',
          ),
        ),
    ];
  }
  
  Widget _homepageChip(final BuildContext context, final Uri homepageUrl) {
    final String host =
        homepageUrl.host.isNotEmpty ? homepageUrl.host : homepageUrl.toString();
    return GestureDetector(
      onTap: () => launchUrl(homepageUrl),
      child: _statusChip(
        context,
        icon: Octicons.link_external,
        label: host,
      ),
    );
  }

  Widget _languageChip(final BuildContext context, final String language) {
    final Color languageColor = Color(getLangColor(language));
    return _metaChip(
      context,
      leading: Container(
        height: 8,
        width: 8,
        decoration: BoxDecoration(
          color: languageColor,
          shape: BoxShape.circle,
        ),
      ),
      label: language,
      accentColor: languageColor,
    );
  }



  Widget _statusChip(
    final BuildContext context, {
    required final IconData icon,
    final String? label,
  }) =>
      _metaChip(
        context,
        leading: Icon(
          icon,
          size: 12,
          color: context.colorScheme.onSurfaceVariant,
        ),
        label: label,
      );

  Widget _metaChip(
    final BuildContext context, {
    required final Widget leading,
    final String? label,
    final Color? accentColor,
  }) =>
      MetadataChip(
        leading: leading,
        label: label,
        accentColor: accentColor,
      );

  List<Widget> _buildTopicChips(
    final BuildContext context,
    final WidgetRef ref,
    final List<String> topicNames,
  ) =>
      topicNames
          .map(
            (topic) => GestureDetector(
              onTap: () => TopicRef(name: topic).navigate(context, ref),
              child: _metaChip(
                context,
                leading: Icon(
                  Octicons.hash,
                  size: 12,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                label: topic,
              ),
            ),
          )
          .toList();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) =>
      repoUnthemedWidget(context, ref);
}

/// Fetches a repository by [RepoRef] via [repoCardProvider] and renders
/// it as a tappable card. Uses lightweight card-only query instead of full repo info.
class RepoCardLoading extends ConsumerWidget {
  const RepoCardLoading(
    this.repo, {
    this.refresh = false,
    super.key,
  });

  final RepoRef repo;

  final bool refresh;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final asyncRepo = ref.watch(repoCardProvider(repo));
    return AsyncValueBuilder<RepoCardData>(
      value: asyncRepo,
      skeleton: (final _) => const ShimmerScope(
        child: BorderedContainer(
          child: RepositoryCardSkeleton(),
        ),
      ),
      error: (final Object err, final _) => BorderedContainer(
        child: Padding(
          padding: context.spacing.pagePadding,
          child: Text(
            'Failed to load repository',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ),
      data: (final RepoCardData repoData) {
        return BorderedContainer(
          ref: RepoRef.fromRepoCardFields(repoData),
          child: RepositoryCard(
            repoData,
            starChip: RepoStarChipFromData(
              repoRef: repo,
              repoNodeId: repoData.id,
              initialStarCount: repoData.stargazerCount,
              initialIsStarred: repoData.viewerHasStarred,
            ),
          ),
        );
      },
    );
  }
}

/// Standard loading placeholder for a RepositoryCard.
///
/// Uses EntityCardLayoutSkeleton to match the actual RepositoryCard layout.
class RepositoryCardSkeleton extends StatelessWidget {
  const RepositoryCardSkeleton({super.key});

  @override
  Widget build(final BuildContext context) {
    return const EntityCardLayoutSkeleton(
      showPrefix: true,
      showTrailing: true,
      showChips: 4,
      showSupplementary: true,
    );
  }
}
