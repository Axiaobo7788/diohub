import 'package:diohub/common/search_overlay/search_type.dart';

/// Shared regex helpers used by [SearchQueries].
abstract class SearchFilterRegex {
  static const String ch = r'[\w!><=@#$&()\-`.+,/]';
  static const String chNoSlash = r'[\w!><=@#$&()\-`.+,]';

  static String optionalQuotes(
    final String string, {
    final bool allowSpace = false,
    final String? spacedRegex,
  }) {
    if (allowSpace) {
      return '(?:(?:")$spacedRegex(?:")|$string)';
    }
    return '(?:(?:")$string(?:")|$string)';
  }

  static String rangeRegExp(final String string) =>
      '(?:$string\\.\\.$string|$string\\.\\.\\*|\\*\\.\\.$string|[><]=?$string|$string)';
}

class SearchQueryStrings {
  static const String archived = 'archived';
  static const String assignee = 'assignee';
  static const String author = 'author';
  static const String authorName = 'author-name';
  static const String authorEmail = 'author-email';
  static const String authorDate = 'author-date';
  static const String base = 'base';
  static const String closed = 'closed';
  static const String category = 'category';
  static const String commenter = 'commenter';
  static const String comments = 'comments';
  static const String committer = 'committer';
  static const String committerName = 'committer-name';
  static const String committerEmail = 'committer-email';
  static const String committerDate = 'committer-date';
  static const String created = 'created';
  static const String draft = 'draft';
  static const String extension = 'extension';
  static const String filename = 'filename';
  static const String followers = 'followers';
  static const String fork = 'fork';
  static const String forks = 'forks';
  static const String fullName = 'fullname';
  static const String goodFirstIssues = 'good-first-issues';
  static const String hash = 'hash';
  static const String head = 'head';
  static const String helpWantedIssues = 'help-wanted-issues';
  static const String iN = 'in';
  static const String interactions = 'interactions';
  static const String involves = 'involves';
  static const String iS = 'is';
  static const String label = 'label';
  static const String language = 'language';
  static const String license = 'license';
  static const String linked = 'linked';
  static const String location = 'location';
  static const String merge = 'merge';
  static const String merged = 'merged';
  static const String mentions = 'mentions';
  static const String milestone = 'milestone';
  static const String mirror = 'mirror';
  static const String no = 'no';
  static const String org = 'org';
  static const String parent = 'parent';
  static const String path = 'path';
  static const String project = 'project';
  static const String pushed = 'pushed';
  static const String reactions = 'reactions';
  static const String repo = 'repo';
  static const String repos = 'repos';
  static const String repositories = 'repositories';
  static const String review = 'review';
  static const String reviewedBy = 'reviewed-by';
  static const String reviewRequested = 'review-requested';
  static const String teamReviewRequested = 'team-review-requested';
  static const String size = 'size';
  static const String sort = 'sort';
  static const String stars = 'stars';
  static const String state = 'state';
  static const String status = 'status';
  static const String team = 'team';
  static const String topic = 'topic';
  static const String topics = 'topics';
  static const String tree = 'tree';
  static const String type = 'type';
  static const String updated = 'updated';
  static const String user = 'user';

  static const List<String> allQueries = <String>[
    archived,
    assignee,
    author,
    authorName,
    authorEmail,
    authorDate,
    base,
    closed,
    category,
    commenter,
    comments,
    committer,
    committerName,
    committerEmail,
    committerDate,
    created,
    draft,
    extension,
    filename,
    followers,
    fork,
    forks,
    fullName,
    goodFirstIssues,
    hash,
    head,
    helpWantedIssues,
    iN,
    interactions,
    involves,
    iS,
    label,
    language,
    license,
    linked,
    location,
    merge,
    merged,
    mentions,
    milestone,
    mirror,
    no,
    org,
    parent,
    path,
    project,
    pushed,
    reactions,
    repo,
    repos,
    repositories,
    review,
    reviewedBy,
    reviewRequested,
    teamReviewRequested,
    size,
    sort,
    stars,
    state,
    status,
    team,
    topic,
    topics,
    tree,
    type,
    updated,
    user,
  ];
}

class SearchQuery {
  SearchQuery(
    this.query, {
    this.description,
    this.options,
    this.customRegex,
    final QueryType? type,
    this.qualifierQuery = true,
  }) : type =
            type ?? (customRegex != null ? QueryType.custom : QueryType.basic) {
    if (type == QueryType.bool && options == null) {
      options = <String, String>{'true': '', 'false': ''};
    }
  }
  final String query;
  final String? description;
  final String? customRegex;
  final bool qualifierQuery;
  Map<String, String>? options;
  final QueryType type;

  String toQueryString(final String data) =>
      data.contains(' ') ? '$query:"$data"' : '$query:$data';

  void addOptions(final Map<String, String> options) {
    if (this.options == null) {
      this.options = <String, String>{};
    }

    this.options!.addAll(options);
  }
}

class SearchQueries {
  static final String _teamRegex =
      '(?:-)?(?:${SearchQueryStrings.team}:)${SearchFilterRegex.optionalQuotes('${SearchFilterRegex.chNoSlash}+/${SearchFilterRegex.ch}+')}(?=(?:\\s))';
  static final String _authorRegex =
      '(?:-)?(?:${SearchQueryStrings.author}:)${SearchFilterRegex.optionalQuotes('(?:app/)?${SearchFilterRegex.chNoSlash}+')}(?=(?:\\s))';

  static final String _projectRegex =
      '(?:-)?(?:${SearchQueryStrings.project}:)${SearchFilterRegex.optionalQuotes('${SearchFilterRegex.chNoSlash}+(?:/${SearchFilterRegex.ch}+){1,2}')}(?=(?:\\s))';

  static final String _repoRegex =
      '(?:-)?(?:${SearchQueryStrings.repo}:)${SearchFilterRegex.optionalQuotes('${SearchFilterRegex.chNoSlash}+/${SearchFilterRegex.ch}+')}(?=(?:\\s))';

  SearchQuery archived =
      SearchQuery(SearchQueryStrings.archived, type: QueryType.bool);
  SearchQuery assignee =
      SearchQuery(SearchQueryStrings.assignee, type: QueryType.user);
  SearchQuery author = SearchQuery(
    SearchQueryStrings.author,
    customRegex: _authorRegex,
    type: QueryType.user,
  );
  SearchQuery authorName = SearchQuery(SearchQueryStrings.authorName);
  SearchQuery authorEmail = SearchQuery(SearchQueryStrings.authorEmail);
  SearchQuery authorDate = SearchQuery(SearchQueryStrings.authorDate);
  SearchQuery base = SearchQuery(SearchQueryStrings.base);
  SearchQuery closed =
      SearchQuery(SearchQueryStrings.closed, type: QueryType.date);
  SearchQuery category = SearchQuery(SearchQueryStrings.category);
  SearchQuery commenter =
      SearchQuery(SearchQueryStrings.commenter, type: QueryType.user);
  SearchQuery comments =
      SearchQuery(SearchQueryStrings.comments, type: QueryType.number);
  SearchQuery committer =
      SearchQuery(SearchQueryStrings.committer, type: QueryType.user);
  SearchQuery committerName = SearchQuery(SearchQueryStrings.committerName);
  SearchQuery committerEmail = SearchQuery(SearchQueryStrings.committerEmail);
  SearchQuery committerDate = SearchQuery(SearchQueryStrings.committerDate);
  SearchQuery created =
      SearchQuery(SearchQueryStrings.created, type: QueryType.date);
  SearchQuery draft =
      SearchQuery(SearchQueryStrings.draft, type: QueryType.bool);
  SearchQuery extension = SearchQuery(SearchQueryStrings.extension);
  SearchQuery filename = SearchQuery(SearchQueryStrings.filename);
  SearchQuery followers =
      SearchQuery(SearchQueryStrings.followers, type: QueryType.number);
  SearchQuery fork = SearchQuery(
    SearchQueryStrings.fork,
    options: <String, String>{
      'true': 'Include forks.',
      'only': 'Only show forks.',
    },
    qualifierQuery: false,
  );
  SearchQuery forks =
      SearchQuery(SearchQueryStrings.forks, type: QueryType.number);
  SearchQuery fullName =
      SearchQuery(SearchQueryStrings.fullName, type: QueryType.spacedString);
  SearchQuery goodFirstIssues =
      SearchQuery(SearchQueryStrings.goodFirstIssues, type: QueryType.number);
  SearchQuery hash = SearchQuery(SearchQueryStrings.hash);
  SearchQuery head = SearchQuery(SearchQueryStrings.head);
  SearchQuery helpWantedIssues =
      SearchQuery(SearchQueryStrings.helpWantedIssues, type: QueryType.number);
  SearchQuery iN = SearchQuery(SearchQueryStrings.iN, qualifierQuery: false);
  SearchQuery interactions =
      SearchQuery(SearchQueryStrings.interactions, type: QueryType.number);
  SearchQuery involves =
      SearchQuery(SearchQueryStrings.involves, type: QueryType.user);
  SearchQuery iS = SearchQuery(SearchQueryStrings.iS);
  SearchQuery label =
      SearchQuery(SearchQueryStrings.label, type: QueryType.spacedString);
  SearchQuery language = SearchQuery(SearchQueryStrings.language);
  SearchQuery license = SearchQuery(SearchQueryStrings.license);
  SearchQuery linked = SearchQuery(SearchQueryStrings.linked);
  SearchQuery location =
      SearchQuery(SearchQueryStrings.location, type: QueryType.spacedString);
  SearchQuery merge = SearchQuery(SearchQueryStrings.merge);
  SearchQuery merged =
      SearchQuery(SearchQueryStrings.merged, type: QueryType.date);
  SearchQuery mentions =
      SearchQuery(SearchQueryStrings.mentions, type: QueryType.user);
  SearchQuery milestone =
      SearchQuery(SearchQueryStrings.milestone, type: QueryType.spacedString);
  SearchQuery mirror =
      SearchQuery(SearchQueryStrings.mirror, type: QueryType.bool);
  SearchQuery no = SearchQuery(SearchQueryStrings.no);
  SearchQuery org = SearchQuery(SearchQueryStrings.org, type: QueryType.org);
  SearchQuery parent = SearchQuery(SearchQueryStrings.parent);
  SearchQuery path = SearchQuery(SearchQueryStrings.path);
  SearchQuery project =
      SearchQuery(SearchQueryStrings.project, customRegex: _projectRegex);
  SearchQuery pushed =
      SearchQuery(SearchQueryStrings.pushed, type: QueryType.date);
  SearchQuery reactions =
      SearchQuery(SearchQueryStrings.reactions, type: QueryType.number);
  SearchQuery repo =
      SearchQuery(SearchQueryStrings.repo, customRegex: _repoRegex);
  SearchQuery repos =
      SearchQuery(SearchQueryStrings.repos, type: QueryType.number);
  SearchQuery repositories = SearchQuery(SearchQueryStrings.repositories);
  SearchQuery review = SearchQuery(SearchQueryStrings.review);
  SearchQuery reviewedBy =
      SearchQuery(SearchQueryStrings.reviewedBy, type: QueryType.user);
  SearchQuery reviewRequested =
      SearchQuery(SearchQueryStrings.reviewRequested, type: QueryType.user);
  SearchQuery size =
      SearchQuery(SearchQueryStrings.size, type: QueryType.number);
  SearchQuery sort = SearchQuery(SearchQueryStrings.sort);
  SearchQuery stars =
      SearchQuery(SearchQueryStrings.stars, type: QueryType.number);
  SearchQuery state = SearchQuery(SearchQueryStrings.state);
  SearchQuery status = SearchQuery(SearchQueryStrings.status);
  SearchQuery team =
      SearchQuery(SearchQueryStrings.team, customRegex: _teamRegex);
  SearchQuery teamReviewRequested = SearchQuery(
    SearchQueryStrings.teamReviewRequested,
    customRegex: _teamRegex,
  );
  SearchQuery topic =
      SearchQuery(SearchQueryStrings.topic, type: QueryType.spacedString);
  SearchQuery topics =
      SearchQuery(SearchQueryStrings.topics, type: QueryType.number);
  SearchQuery tree = SearchQuery(SearchQueryStrings.tree);
  SearchQuery type =
      SearchQuery(SearchQueryStrings.type, qualifierQuery: false);
  SearchQuery updated = SearchQuery(SearchQueryStrings.updated);
  SearchQuery user = SearchQuery(SearchQueryStrings.user, type: QueryType.user);

  List<SearchQuery> get allQueries => <SearchQuery>[
        archived,
        assignee,
        author,
        authorName,
        authorEmail,
        authorDate,
        base,
        closed,
        category,
        commenter,
        comments,
        committer,
        committerName,
        committerEmail,
        committerDate,
        created,
        draft,
        extension,
        filename,
        followers,
        fork,
        forks,
        fullName,
        goodFirstIssues,
        hash,
        head,
        helpWantedIssues,
        iN,
        interactions,
        involves,
        iS,
        label,
        language,
        license,
        linked,
        location,
        merge,
        merged,
        mentions,
        milestone,
        mirror,
        no,
        org,
        parent,
        path,
        project,
        pushed,
        reactions,
        repo,
        repos,
        repositories,
        review,
        reviewedBy,
        reviewRequested,
        teamReviewRequested,
        size,
        sort,
        stars,
        state,
        status,
        team,
        topic,
        topics,
        tree,
        type,
        updated,
        user,
      ];
}
