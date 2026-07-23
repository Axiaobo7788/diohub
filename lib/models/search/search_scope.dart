import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/search_type.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub/models/search/quick_filter.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub_models/models/search/sort_config.dart';
import 'package:diohub_models/models/search/sort_configs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart' show Octicons;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_scope.freezed.dart';

/// Search scope: defines type, hidden qualifiers, quick filters, sort, and filter sheet sections.
@freezed
sealed class SearchScope with _$SearchScope {
  const SearchScope._();

  const factory SearchScope.homeIssues({String? viewerLogin}) = HomeIssuesScope;
  const factory SearchScope.homePulls({String? viewerLogin}) = HomePullsScope;
  const factory SearchScope.repoIssues({
    required RepoRef repo,
    String? viewerLogin,
  }) = RepoIssuesScope;
  const factory SearchScope.repoPulls({
    required RepoRef repo,
    String? viewerLogin,
  }) = RepoPullsScope;
  const factory SearchScope.userRepos({required UserRef user}) = UserReposScope;
  const factory SearchScope.profileIssues({required UserRef user}) =
      ProfileIssuesScope;
  const factory SearchScope.profilePulls({required UserRef user}) =
      ProfilePullsScope;
  const factory SearchScope.typedGlobal({required SearchType searchType}) =
      TypedGlobalSearchScope;
  const factory SearchScope.repoDiscussions({required RepoRef repo}) =
      RepoDiscussionsScope;
  const factory SearchScope.custom({
    required SearchType searchType,
    @Default([]) List<Qualifier> hiddenQualifiers,
    @Default([]) List<QuickFilter> quickFilters,
    @Default([]) List<QuickOption> quickOptions,
    required SortConfig sortConfig,
    @Default([]) List<String> blacklistedQualifiers,
    @Default(false) bool multiType,
    required String tabKey,
    required String cacheKey,
    required List<FilterSectionDef> Function(SearchType) promotedSectionsFn,
    required List<FilterSectionDef> Function(SearchType) moreSectionsFn,
  }) = CustomScope;

  SearchType get searchType => switch (this) {
    HomeIssuesScope() => SearchType.issuesPulls,
    HomePullsScope() => SearchType.issuesPulls,
    RepoIssuesScope() => SearchType.issuesPulls,
    RepoPullsScope() => SearchType.issuesPulls,
    UserReposScope() => SearchType.repositories,
    ProfileIssuesScope() => SearchType.issuesPulls,
    ProfilePullsScope() => SearchType.issuesPulls,
    TypedGlobalSearchScope(:final searchType) => searchType,
    RepoDiscussionsScope() => SearchType.discussions,
    CustomScope(:final searchType) => searchType,
  };

  List<Qualifier> get hiddenQualifiers => switch (this) {
    HomeIssuesScope(:final viewerLogin) => [
      if (viewerLogin != null && viewerLogin.isNotEmpty)
        Qualifier.involves(UserRef(login: viewerLogin)),
      Qualifier.typeIssue(),
    ],
    HomePullsScope(:final viewerLogin) => [
      if (viewerLogin != null && viewerLogin.isNotEmpty)
        Qualifier.involves(UserRef(login: viewerLogin)),
      Qualifier.typePr(),
    ],
    RepoIssuesScope(:final repo) => [
      Qualifier.typeIssue(),
      Qualifier.repo(repo),
    ],
    RepoPullsScope(:final repo) => [Qualifier.typePr(), Qualifier.repo(repo)],
    UserReposScope(:final user) => [Qualifier.user(user)],
    ProfileIssuesScope(:final user) => [
      Qualifier.author(user),
      Qualifier.typeIssue(),
    ],
    ProfilePullsScope(:final user) => [
      Qualifier.author(user),
      Qualifier.typePr(),
    ],
    TypedGlobalSearchScope() => const [],
    RepoDiscussionsScope(:final repo) => [Qualifier.repo(repo)],
    CustomScope(:final hiddenQualifiers) => hiddenQualifiers,
  };

  String get _quickFilterLogin => switch (this) {
    HomeIssuesScope(:final viewerLogin) => viewerLogin ?? '',
    HomePullsScope(:final viewerLogin) => viewerLogin ?? '',
    RepoIssuesScope(:final viewerLogin) => viewerLogin ?? '',
    RepoPullsScope(:final viewerLogin) => viewerLogin ?? '',
    ProfileIssuesScope(:final user) => user.login,
    ProfilePullsScope(:final user) => user.login,
    _ => '',
  };

  List<QuickFilter> get quickFilters => switch (this) {
    HomeIssuesScope() ||
    HomePullsScope() ||
    ProfileIssuesScope() ||
    ProfilePullsScope() => [
      QuickFilter(
        qualifier: QualifierExpression(
          Qualifier.assignee(UserRef(login: _quickFilterLogin)),
        ),
        displayLabel: 'Assigned',
      ),
      QuickFilter(
        qualifier: QualifierExpression(
          Qualifier.author(UserRef(login: _quickFilterLogin)),
        ),
        displayLabel: 'Created',
      ),
      QuickFilter(
        qualifier: QualifierExpression(
          Qualifier.mentions(UserRef(login: _quickFilterLogin)),
        ),
        displayLabel: 'Mentioned',
      ),
    ],
    RepoIssuesScope() => [
      QuickFilter(
        qualifier: QualifierExpression(
          Qualifier.assignee(UserRef(login: _quickFilterLogin)),
        ),
        displayLabel: 'Assigned',
        aliasKey: 'assignedToYou',
      ),
      QuickFilter(
        qualifier: QualifierExpression(
          Qualifier.author(UserRef(login: _quickFilterLogin)),
        ),
        displayLabel: 'Created',
        aliasKey: 'yourIssues',
      ),
      QuickFilter(
        qualifier: QualifierExpression(
          Qualifier.mentions(UserRef(login: _quickFilterLogin)),
        ),
        displayLabel: 'Mentioned',
        aliasKey: 'mentionsYou',
      ),
    ],
    RepoPullsScope() => [
      QuickFilter(
        qualifier: QualifierExpression(
          Qualifier.assignee(UserRef(login: _quickFilterLogin)),
        ),
        displayLabel: 'Assigned',
        aliasKey: 'assignedToYou',
      ),
      QuickFilter(
        qualifier: QualifierExpression(
          Qualifier.author(UserRef(login: _quickFilterLogin)),
        ),
        displayLabel: 'Created',
        aliasKey: 'yourPullRequests',
      ),
      QuickFilter(
        qualifier: QualifierExpression(
          Qualifier.mentions(UserRef(login: _quickFilterLogin)),
        ),
        displayLabel: 'Mentioned',
        aliasKey: 'mentionsYou',
      ),
    ],
    UserReposScope() => [
      QuickFilter(
        qualifier: QualifierExpression(Qualifier.isPublic),
        displayLabel: 'Public',
      ),
      QuickFilter(
        qualifier: QualifierExpression(Qualifier.isPrivate),
        displayLabel: 'Private',
      ),
      QuickFilter(
        qualifier: QualifierExpression(Qualifier.archived(true)),
        displayLabel: 'Archived',
      ),
      QuickFilter(
        qualifier: QualifierExpression(Qualifier.mirror(true)),
        displayLabel: 'Mirrors',
      ),
      QuickFilter(
        qualifier: QualifierExpression(Qualifier.forkOnly()),
        displayLabel: 'Forks only',
      ),
    ],
    TypedGlobalSearchScope() => const [],
    RepoDiscussionsScope() => [
      QuickFilter(
        qualifier: QualifierExpression(Qualifier.isAnswered),
        displayLabel: 'Answered',
      ),
      QuickFilter(
        qualifier: QualifierExpression(Qualifier.isUnanswered),
        displayLabel: 'Unanswered',
      ),
      QuickFilter(
        qualifier: QualifierExpression(Qualifier.isOpen),
        displayLabel: 'Open',
      ),
      QuickFilter(
        qualifier: QualifierExpression(Qualifier.isClosed),
        displayLabel: 'Closed',
      ),
    ],
    CustomScope(:final quickFilters) => quickFilters,
  };

  List<QuickOption> get quickOptions => switch (this) {
    HomeIssuesScope() ||
    HomePullsScope() ||
    RepoIssuesScope() ||
    RepoPullsScope() ||
    ProfileIssuesScope() ||
    ProfilePullsScope() => [
      const QuickOption(
        qualifier: QualifierExpression(Qualifier.isOpen),
        displayLabel: 'Open Only',
      ),
    ],
    UserReposScope() => [
      QuickOption(
        qualifier: QualifierExpression(Qualifier.forkInclude()),
        displayLabel: 'Include forks',
      ),
    ],
    TypedGlobalSearchScope() || RepoDiscussionsScope() => const [],
    CustomScope(:final quickOptions) => quickOptions,
  };

  SortConfig get sortConfig => switch (this) {
    HomeIssuesScope() ||
    HomePullsScope() ||
    RepoIssuesScope() ||
    RepoPullsScope() ||
    ProfileIssuesScope() ||
    ProfilePullsScope() => SearchSortConfigs.issuesPullsSort,
    UserReposScope() => SearchSortConfigs.repositoriesSort,
    TypedGlobalSearchScope(:final searchType) => switch (searchType) {
      SearchType.repositories => SortConfig(const [
        SortOption(key: 'best', displayName: 'Best Match'),
        SortOption(key: 'stars-desc', displayName: 'Most stars'),
        SortOption(key: 'updated-desc', displayName: 'Recently updated'),
      ]),
      SearchType.issuesPulls => SortConfig(const [
        SortOption(key: 'best', displayName: 'Best Match'),
        SortOption(key: 'created-desc', displayName: 'Newest'),
        SortOption(key: 'created-asc', displayName: 'Oldest'),
        SortOption(key: 'comments-desc', displayName: 'Most comments'),
        SortOption(key: 'updated-desc', displayName: 'Recently updated'),
      ]),
      SearchType.users => SortConfig(const [
        SortOption(key: 'best', displayName: 'Best Match'),
        SortOption(key: 'followers-desc', displayName: 'Most followers'),
        SortOption(key: 'repositories-desc', displayName: 'Most repos'),
        SortOption(key: 'joined-desc', displayName: 'Newest'),
      ]),
      SearchType.discussions => SortConfig(const [
        SortOption(key: 'best', displayName: 'Best Match'),
        SortOption(key: 'created-desc', displayName: 'Newest'),
        SortOption(key: 'updated-desc', displayName: 'Recently updated'),
      ]),
      _ => SortConfig(const [
        SortOption(key: 'best', displayName: 'Best Match'),
      ]),
    },
    RepoDiscussionsScope() => SortConfig(const [
      SortOption(key: 'best', displayName: 'Best Match'),
      SortOption(key: 'created-desc', displayName: 'Newest'),
      SortOption(key: 'created-asc', displayName: 'Oldest'),
      SortOption(key: 'updated-desc', displayName: 'Recently updated'),
      SortOption(key: 'comments-desc', displayName: 'Most comments'),
    ]),
    CustomScope(:final sortConfig) => sortConfig,
  };

  List<String> get blacklistedQualifiers => switch (this) {
    CustomScope(:final blacklistedQualifiers) => blacklistedQualifiers,
    _ => const [],
  };

  bool get multiType => switch (this) {
    TypedGlobalSearchScope() => true,
    CustomScope(:final multiType) => multiType,
    _ => false,
  };

  String get tabKey => switch (this) {
    HomeIssuesScope() => 'issues',
    HomePullsScope() => 'pulls',
    RepoIssuesScope() => 'repo_issues',
    RepoPullsScope() => 'repo_pulls',
    UserReposScope() => 'user_repos',
    ProfileIssuesScope() => 'profile_issues',
    ProfilePullsScope() => 'profile_pulls',
    TypedGlobalSearchScope() => 'global',
    RepoDiscussionsScope() => 'repo_discussions',
    CustomScope(:final tabKey) => tabKey,
  };

  String get cacheKey => switch (this) {
    HomeIssuesScope(:final viewerLogin) => 'home:${viewerLogin ?? ''}',
    HomePullsScope(:final viewerLogin) => 'home:${viewerLogin ?? ''}',
    RepoIssuesScope(:final repo) => 'repo:${repo.fullName}',
    RepoPullsScope(:final repo) => 'repo:${repo.fullName}',
    UserReposScope(:final user) => 'user:${user.login}',
    ProfileIssuesScope(:final user) => 'user:${user.login}',
    ProfilePullsScope(:final user) => 'user:${user.login}',
    TypedGlobalSearchScope() => 'global',
    RepoDiscussionsScope(:final repo) => 'repo:${repo.fullName}',
    CustomScope(:final cacheKey) => cacheKey,
  };

  List<FilterSectionDef> promotedSections(SearchType type) => switch (this) {
    HomeIssuesScope() || HomePullsScope() => _homePromotedSections(type),
    RepoIssuesScope(:final repo) => _repoIssuesPromotedSections(type, repo),
    RepoPullsScope(:final repo) => _repoPullsPromotedSections(type, repo),
    UserReposScope() => _userReposPromotedSections(type),
    ProfileIssuesScope() ||
    ProfilePullsScope() => _profileIssuesPullsPromotedSections(type),
    TypedGlobalSearchScope() => _globalPromotedSections(type, sortConfig.asMap),
    RepoDiscussionsScope(:final repo) => _repoDiscussionsPromotedSections(
      type,
      repo,
    ),
    CustomScope(:final promotedSectionsFn) => promotedSectionsFn(type),
  };

  List<FilterSectionDef> moreSections(SearchType type) => switch (this) {
    HomeIssuesScope() || HomePullsScope() => _homeMoreSections(type),
    RepoIssuesScope(:final repo) => _repoIssuesMoreSections(type, repo),
    RepoPullsScope(:final repo) => _repoPullsMoreSections(type, repo),
    UserReposScope() => _userReposMoreSections(type),
    ProfileIssuesScope() ||
    ProfilePullsScope() => _profileIssuesPullsMoreSections(type),
    TypedGlobalSearchScope() => _globalMoreSections(type),
    RepoDiscussionsScope(:final repo) => _repoDiscussionsMoreSections(
      type,
      repo,
    ),
    CustomScope(:final moreSectionsFn) => moreSectionsFn(type),
  };

  SearchScope resolveViewerLogin(String login) => switch (this) {
    HomeIssuesScope() => SearchScope.homeIssues(viewerLogin: login),
    HomePullsScope() => SearchScope.homePulls(viewerLogin: login),
    RepoIssuesScope(:final repo) => SearchScope.repoIssues(
      repo: repo,
      viewerLogin: login,
    ),
    RepoPullsScope(:final repo) => SearchScope.repoPulls(
      repo: repo,
      viewerLogin: login,
    ),
    ProfileIssuesScope() || ProfilePullsScope() => this,
    _ => this,
  };
}

// ─── Home sections ───
List<FilterSectionDef> _homePromotedSections(SearchType type) {
  if (type != SearchType.issuesPulls) return [];
  return [
    StaticFilterSection(
      id: 'status',
      displayName: 'Status',
      icon: Octicons.issue_opened,
      options: kIssuesPullsStatusOptions,
    ),
    StaticFilterSection(
      id: 'sort',
      displayName: 'Sort',
      icon: Octicons.sort_asc,
      options: SearchSortConfigs.issuesPullsSort.asMap,
    ),
  ];
}

List<FilterSectionDef> _homeMoreSections(SearchType type) {
  if (type != SearchType.issuesPulls) return [];
  return [
    const PreloadedFilterSection(
      id: 'org',
      displayName: 'Organization',
      icon: Octicons.organization,
    ),
    const TextFilterSection(
      id: 'repo',
      displayName: 'Repository',
      icon: Octicons.repo,
    ),
    const TextFilterSection(
      id: 'label',
      displayName: 'Label',
      icon: Octicons.tag,
    ),
    const TextFilterSection(
      id: 'language',
      displayName: 'Language',
      icon: Octicons.code,
    ),
    const DateFilterSection(
      id: 'created',
      displayName: 'Created',
      icon: Octicons.calendar,
    ),
  ];
}

// ─── Repo issues sections ───
List<FilterSectionDef> _repoIssuesPromotedSections(
  SearchType type,
  RepoRef repo,
) {
  if (type != SearchType.issuesPulls) return [];
  return [
    StaticFilterSection(
      id: 'status',
      displayName: 'Status',
      icon: Octicons.issue_opened,
      options: kIssueStatusOptions,
    ),
    PaginatedFilterSection(
      id: 'label',
      displayName: 'Labels',
      icon: Octicons.tag,
      repo: repo,
      multiSelect: true,
      searchable: true,
      searchHint: 'Search labels…',
    ),
    PaginatedFilterSection(
      id: 'assignee',
      displayName: 'Assignees',
      icon: Octicons.person,
      repo: repo,
      multiSelect: true,
      searchable: true,
      searchHint: 'Search assignees…',
    ),
    PaginatedFilterSection(
      id: 'milestone',
      displayName: 'Milestone',
      icon: Octicons.milestone,
      repo: repo,
      searchable: false,
    ),
    StaticFilterSection(
      id: 'sort',
      displayName: 'Sort',
      icon: Octicons.sort_asc,
      options: SearchSortConfigs.issuesPullsSort.asMap,
    ),
  ];
}

List<FilterSectionDef> _repoIssuesMoreSections(SearchType type, RepoRef repo) {
  if (type != SearchType.issuesPulls) return [];
  return [
    const UserSearchFilterSection(
      id: 'author',
      displayName: 'Author',
      icon: Octicons.pencil,
    ),
    const DateFilterSection(
      id: 'created',
      displayName: 'Created',
      icon: Octicons.calendar,
    ),
    const NumberFilterSection(
      id: 'comments',
      displayName: 'Comments',
      icon: Octicons.number,
    ),
    const NumberFilterSection(
      id: 'reactions',
      displayName: 'Reactions',
      icon: Octicons.number,
    ),
    const StaticFilterSection(
      id: 'linked',
      displayName: 'Linked',
      icon: Octicons.link,
      options: <String, String>{
        'pr': 'Has linked PR',
        'issue': 'Has linked issue',
      },
    ),
    const StaticFilterSection(
      id: 'no',
      displayName: 'Exclude',
      icon: Octicons.skip,
      options: <String, String>{
        'label': 'No labels',
        'milestone': 'No milestone',
        'assignee': 'No assignee',
      },
    ),
    const DateFilterSection(
      id: 'closed',
      displayName: 'Closed',
      icon: Octicons.calendar,
    ),
  ];
}

// ─── Repo pulls sections ───
List<FilterSectionDef> _repoPullsPromotedSections(
  SearchType type,
  RepoRef repo,
) {
  if (type != SearchType.issuesPulls) return [];
  return [
    StaticFilterSection(
      id: 'status',
      displayName: 'Status',
      icon: Octicons.issue_opened,
      options: kPullRequestStatusOptions,
    ),
    PaginatedFilterSection(
      id: 'label',
      displayName: 'Labels',
      icon: Octicons.tag,
      repo: repo,
      multiSelect: true,
      searchable: true,
      searchHint: 'Search labels…',
    ),
    PaginatedFilterSection(
      id: 'assignee',
      displayName: 'Assignees',
      icon: Octicons.person,
      repo: repo,
      multiSelect: true,
      searchable: true,
      searchHint: 'Search assignees…',
    ),
    PaginatedFilterSection(
      id: 'milestone',
      displayName: 'Milestone',
      icon: Octicons.milestone,
      repo: repo,
      searchable: false,
    ),
    StaticFilterSection(
      id: 'sort',
      displayName: 'Sort',
      icon: Octicons.sort_asc,
      options: SearchSortConfigs.issuesPullsSort.asMap,
    ),
  ];
}

List<FilterSectionDef> _repoPullsMoreSections(SearchType type, RepoRef repo) {
  if (type != SearchType.issuesPulls) return [];
  return [
    const UserSearchFilterSection(
      id: 'author',
      displayName: 'Author',
      icon: Octicons.pencil,
    ),
    PaginatedFilterSection(
      id: 'base',
      displayName: 'Base branch',
      icon: Octicons.git_branch,
      repo: repo,
      searchable: true,
      searchHint: 'Search branches…',
    ),
    PaginatedFilterSection(
      id: 'head',
      displayName: 'Head branch',
      icon: Octicons.git_branch,
      repo: repo,
      searchable: true,
      searchHint: 'Search branches…',
    ),
    const StaticFilterSection(
      id: 'review',
      displayName: 'Review status',
      icon: Octicons.code_review,
      options: <String, String>{
        'none': 'No review',
        'required': 'Review required',
        'approved': 'Approved',
        'changes_requested': 'Changes requested',
      },
    ),
    const StaticFilterSection(
      id: 'draft',
      displayName: 'Draft',
      icon: Octicons.git_pull_request_draft,
      options: <String, String>{
        'true': 'Draft only',
        'false': 'Non-draft only',
      },
    ),
    const DateFilterSection(
      id: 'created',
      displayName: 'Created',
      icon: Octicons.calendar,
    ),
    const NumberFilterSection(
      id: 'comments',
      displayName: 'Comments',
      icon: Octicons.number,
    ),
    const NumberFilterSection(
      id: 'reactions',
      displayName: 'Reactions',
      icon: Octicons.number,
    ),
    const DateFilterSection(
      id: 'merged',
      displayName: 'Merged',
      icon: Octicons.calendar,
    ),
    const DateFilterSection(
      id: 'closed',
      displayName: 'Closed',
      icon: Octicons.calendar,
    ),
  ];
}

// ─── User repos sections ───
List<FilterSectionDef> _userReposPromotedSections(SearchType type) {
  if (type != SearchType.repositories) return [];
  return [
    const StaticFilterSection(
      id: 'status',
      displayName: 'Status',
      icon: Octicons.repo,
      options: <String, String>{'public': 'Public', 'private': 'Private'},
    ),
    StaticFilterSection(
      id: 'sort',
      displayName: 'Sort',
      icon: Octicons.sort_asc,
      options: SearchSortConfigs.repositoriesSort.asMap,
    ),
  ];
}

List<FilterSectionDef> _userReposMoreSections(SearchType type) {
  if (type != SearchType.repositories) return [];
  return [
    const TextFilterSection(
      id: 'language',
      displayName: 'Language',
      icon: Octicons.code,
    ),
    const NumberFilterSection(
      id: 'stars',
      displayName: 'Stars',
      icon: Octicons.number,
    ),
    const NumberFilterSection(
      id: 'forks',
      displayName: 'Forks',
      icon: Octicons.number,
    ),
  ];
}

// ─── Profile issues/pulls sections ───
List<FilterSectionDef> _profileIssuesPullsPromotedSections(SearchType type) {
  if (type != SearchType.issuesPulls) return [];
  return [
    StaticFilterSection(
      id: 'status',
      displayName: 'Status',
      icon: Octicons.issue_opened,
      options: kIssuesPullsStatusOptions,
    ),
    StaticFilterSection(
      id: 'sort',
      displayName: 'Sort',
      icon: Octicons.sort_asc,
      options: SearchSortConfigs.issuesPullsSort.asMap,
    ),
  ];
}

List<FilterSectionDef> _profileIssuesPullsMoreSections(SearchType type) {
  if (type != SearchType.issuesPulls) return [];
  return [
    const PreloadedFilterSection(
      id: 'org',
      displayName: 'Organization',
      icon: Octicons.organization,
    ),
    const TextFilterSection(
      id: 'repo',
      displayName: 'Repository',
      icon: Octicons.repo,
    ),
    const TextFilterSection(
      id: 'label',
      displayName: 'Label',
      icon: Octicons.tag,
    ),
    const TextFilterSection(
      id: 'language',
      displayName: 'Language',
      icon: Octicons.code,
    ),
    const DateFilterSection(
      id: 'created',
      displayName: 'Created',
      icon: Octicons.calendar,
    ),
  ];
}

// ─── Repo discussions sections ───
List<FilterSectionDef> _repoDiscussionsPromotedSections(
  SearchType type,
  RepoRef repo,
) {
  if (type != SearchType.discussions) return [];
  return [
    const StaticFilterSection(
      id: 'status',
      displayName: 'Status',
      icon: Octicons.issue_opened,
      options: <String, String>{
        'open': 'Open',
        'closed': 'Closed',
        'answered': 'Answered',
        'unanswered': 'Unanswered',
      },
    ),
    PaginatedFilterSection(
      id: 'label',
      displayName: 'Labels',
      icon: Octicons.tag,
      repo: repo,
      multiSelect: true,
      searchable: true,
      searchHint: 'Search labels…',
    ),
    StaticFilterSection(
      id: 'sort',
      displayName: 'Sort',
      icon: Octicons.sort_asc,
      options: SortConfig(const [
        SortOption(key: 'best', displayName: 'Best Match'),
        SortOption(key: 'created-desc', displayName: 'Newest'),
        SortOption(key: 'created-asc', displayName: 'Oldest'),
        SortOption(key: 'updated-desc', displayName: 'Recently updated'),
        SortOption(key: 'comments-desc', displayName: 'Most comments'),
      ]).asMap,
    ),
  ];
}

List<FilterSectionDef> _repoDiscussionsMoreSections(
  SearchType type,
  RepoRef repo,
) {
  if (type != SearchType.discussions) return [];
  return [
    const UserSearchFilterSection(
      id: 'author',
      displayName: 'Author',
      icon: Octicons.pencil,
    ),
    const DateFilterSection(
      id: 'created',
      displayName: 'Created',
      icon: Octicons.calendar,
    ),
    const NumberFilterSection(
      id: 'comments',
      displayName: 'Comments',
      icon: Octicons.number,
    ),
    const NumberFilterSection(
      id: 'reactions',
      displayName: 'Reactions',
      icon: Octicons.number,
    ),
  ];
}

List<FilterSectionDef> _globalPromotedSections(
  SearchType type,
  Map<String, String> sortOptions,
) {
  switch (type) {
    case SearchType.repositories:
      return [
        const TextFilterSection(
          id: 'language',
          displayName: 'Language',
          icon: Octicons.code,
        ),
        const NumberFilterSection(
          id: 'stars',
          displayName: 'Stars',
          icon: Octicons.number,
        ),
        StaticFilterSection(
          id: 'sort',
          displayName: 'Sort',
          icon: Octicons.sort_asc,
          options: sortOptions,
        ),
      ];
    case SearchType.issuesPulls:
    case SearchType.discussions:
      return [
        StaticFilterSection(
          id: 'status',
          displayName: 'Status',
          icon: Octicons.issue_opened,
          options: kIssuesPullsStatusOptions,
        ),
        const TextFilterSection(
          id: 'issue-type',
          displayName: 'Issue Type',
          icon: Octicons.issue_opened,
        ),
        const UserSearchFilterSection(
          id: 'author',
          displayName: 'Author',
          icon: Octicons.pencil,
        ),
        const TextFilterSection(
          id: 'language',
          displayName: 'Language',
          icon: Octicons.code,
        ),
        StaticFilterSection(
          id: 'sort',
          displayName: 'Sort',
          icon: Octicons.sort_asc,
          options: sortOptions,
        ),
      ];
    case SearchType.code:
      return [
        const TextFilterSection(
          id: 'language',
          displayName: 'Language',
          icon: Octicons.code,
        ),
        const TextFilterSection(
          id: 'repo',
          displayName: 'Repository',
          icon: Octicons.repo,
        ),
        StaticFilterSection(
          id: 'sort',
          displayName: 'Sort',
          icon: Octicons.sort_asc,
          options: sortOptions,
        ),
      ];
    case SearchType.commits:
      return [
        const UserSearchFilterSection(
          id: 'author',
          displayName: 'Author',
          icon: Octicons.pencil,
        ),
        const TextFilterSection(
          id: 'repo',
          displayName: 'Repository',
          icon: Octicons.repo,
        ),
        StaticFilterSection(
          id: 'sort',
          displayName: 'Sort',
          icon: Octicons.sort_asc,
          options: sortOptions,
        ),
      ];
    case SearchType.users:
      return [
        StaticFilterSection(
          id: 'sort',
          displayName: 'Sort',
          icon: Octicons.sort_asc,
          options: sortOptions,
        ),
      ];
    case SearchType.topics:
      return [
        StaticFilterSection(
          id: 'sort',
          displayName: 'Sort',
          icon: Octicons.sort_asc,
          options: sortOptions,
        ),
      ];
    case SearchType.packages:
    case SearchType.wiki:
      return [
        StaticFilterSection(
          id: 'sort',
          displayName: 'Sort',
          icon: Octicons.sort_asc,
          options: sortOptions,
        ),
      ];
  }
}

List<FilterSectionDef> _globalMoreSections(SearchType type) {
  switch (type) {
    case SearchType.repositories:
      return [
        const NumberFilterSection(
          id: 'forks',
          displayName: 'Forks',
          icon: Octicons.number,
        ),
        const DateFilterSection(
          id: 'created',
          displayName: 'Created',
          icon: Octicons.calendar,
        ),
        const DateFilterSection(
          id: 'pushed',
          displayName: 'Pushed',
          icon: Octicons.calendar,
        ),
        const TextFilterSection(
          id: 'topic',
          displayName: 'Topic',
          icon: Octicons.hash,
        ),
        const TextFilterSection(
          id: 'license',
          displayName: 'License',
          icon: Octicons.law,
        ),
        const StaticFilterSection(
          id: 'archived',
          displayName: 'Archived',
          icon: Octicons.archive,
          options: <String, String>{
            'true': 'Archived only',
            'false': 'Non-archived only',
          },
        ),
      ];
    case SearchType.issuesPulls:
    case SearchType.discussions:
      return [
        const PreloadedFilterSection(
          id: 'org',
          displayName: 'Organization',
          icon: Octicons.organization,
        ),
        const TextFilterSection(
          id: 'repo',
          displayName: 'Repository',
          icon: Octicons.repo,
        ),
        const DateFilterSection(
          id: 'created',
          displayName: 'Created',
          icon: Octicons.calendar,
        ),
        const NumberFilterSection(
          id: 'comments',
          displayName: 'Comments',
          icon: Octicons.number,
        ),
        const NumberFilterSection(
          id: 'reactions',
          displayName: 'Reactions',
          icon: Octicons.number,
        ),
      ];
    case SearchType.code:
      return [
        const PreloadedFilterSection(
          id: 'org',
          displayName: 'Organization',
          icon: Octicons.organization,
        ),
        const TextFilterSection(
          id: 'path',
          displayName: 'Path',
          icon: Octicons.file,
        ),
        const TextFilterSection(
          id: 'filename',
          displayName: 'Filename',
          icon: Octicons.file,
        ),
        const NumberFilterSection(
          id: 'size',
          displayName: 'Size',
          icon: Octicons.number,
        ),
      ];
    case SearchType.commits:
      return [
        const DateFilterSection(
          id: 'author-date',
          displayName: 'Author date',
          icon: Octicons.calendar,
        ),
        const DateFilterSection(
          id: 'committer-date',
          displayName: 'Committer date',
          icon: Octicons.calendar,
        ),
      ];
    case SearchType.users:
      return [
        const NumberFilterSection(
          id: 'followers',
          displayName: 'Followers',
          icon: Octicons.number,
        ),
        const NumberFilterSection(
          id: 'repos',
          displayName: 'Repos',
          icon: Octicons.number,
        ),
        const DateFilterSection(
          id: 'created',
          displayName: 'Created',
          icon: Octicons.calendar,
        ),
      ];
    case SearchType.topics:
      return [
        const NumberFilterSection(
          id: 'repositories',
          displayName: 'Repositories',
          icon: Octicons.number,
        ),
        const DateFilterSection(
          id: 'created',
          displayName: 'Created',
          icon: Octicons.calendar,
        ),
      ];
    default:
      return [];
  }
}

/// Extension to build GQL variable map for quick filter count aliases.
extension SearchScopeCountQueries on SearchScope {
  Map<String, String> buildCountVariables(String viewer) {
    final result = <String, String>{};
    for (final filter in quickFilters) {
      final bound = filter.withViewer(viewer).boundTo(this);
      result['${bound.aliasKeyForScope(this)}Q'] = bound.toCountQuery();
    }
    return result;
  }
}
