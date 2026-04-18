import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/search_ranges.dart';

/// Typed qualifier for GitHub search (no raw string keys).
/// Every qualifier key is a named constructor or static factory.
sealed class Qualifier {
  const Qualifier();
  String toQueryString();

  // ─── is: qualifiers ───
  static const Qualifier isOpen = IsQualifier(IsOption.open);
  static const Qualifier isClosed = IsQualifier(IsOption.closed);
  static const Qualifier isMerged = IsQualifier(IsOption.merged);
  static const Qualifier isUnmerged = IsQualifier(IsOption.unmerged);
  static const Qualifier isPublic = IsQualifier(IsOption.public_);
  static const Qualifier isPrivate = IsQualifier(IsOption.private_);
  static const Qualifier isInternal = IsQualifier(IsOption.internal_);
  static const Qualifier isLocked = IsQualifier(IsOption.locked);
  static const Qualifier isUnlocked = IsQualifier(IsOption.unlocked);
  static const Qualifier isAnswered = IsQualifier(IsOption.answered);
  static const Qualifier isUnanswered = IsQualifier(IsOption.unanswered);
  static const Qualifier isCurated = IsQualifier(IsOption.curated);
  static const Qualifier isFeatured = IsQualifier(IsOption.featured);
  static const Qualifier isSponsorable = IsQualifier(IsOption.sponsorable);
  static const Qualifier isQueued = IsQualifier(IsOption.queued);

  static Qualifier stateOpen() => const StateQualifier(StateOption.open);
  static Qualifier stateClosed() => const StateQualifier(StateOption.closed);
  static Qualifier typeIssue() => const TypeQualifier(TypeOption.issue);
  static Qualifier typePr() => const TypeQualifier(TypeOption.pr);
  static Qualifier reviewNone() => const ReviewQualifier(ReviewOption.none);
  static Qualifier reviewApproved() =>
      const ReviewQualifier(ReviewOption.approved);
  static Qualifier reviewChangesRequested() =>
      const ReviewQualifier(ReviewOption.changesRequested);
  static Qualifier reasonCompleted() =>
      const CloseReasonQualifier(CloseReason.completed);
  static Qualifier reasonNotPlanned() =>
      const CloseReasonQualifier(CloseReason.notPlanned);
  static Qualifier reasonReopened() =>
      const CloseReasonQualifier(CloseReason.reopened);

  static Qualifier draft(bool v) => BoolQualifier._('draft', v);
  static Qualifier archived(bool v) => BoolQualifier._('archived', v);
  static Qualifier mirror(bool v) => BoolQualifier._('mirror', v);
  static Qualifier template(bool v) => BoolQualifier._('template', v);

  static Qualifier author(UserRef u) => UserQualifier._('author', u);
  static Qualifier assignee(UserRef u) => UserQualifier._('assignee', u);
  static Qualifier involves(UserRef u) => UserQualifier._('involves', u);
  static Qualifier mentions(UserRef u) => UserQualifier._('mentions', u);
  static Qualifier commenter(UserRef u) => UserQualifier._('commenter', u);
  static Qualifier reviewRequested(UserRef u) =>
      UserQualifier._('review-requested', u);
  static Qualifier reviewedBy(UserRef u) => UserQualifier._('reviewed-by', u);
  static Qualifier answeredBy(UserRef u) => UserQualifier._('answered-by', u);
  static Qualifier user(UserRef u) => UserQualifier._('user', u);

  static Qualifier repo(RepoRef r) => RepoQualifier(r);
  static Qualifier org(String login) => OrgQualifier(login);

  static Qualifier label(String v) => TextQualifier._('label', v);
  static Qualifier milestone(String v) => TextQualifier._('milestone', v);
  static Qualifier language(String v) => TextQualifier._('language', v);
  static Qualifier topic(String v) => TextQualifier._('topic', v);
  static Qualifier license(String v) => TextQualifier._('license', v);
  static Qualifier base(String v) => TextQualifier._('base', v);
  static Qualifier head(String v) => TextQualifier._('head', v);
  static Qualifier category(String v) => TextQualifier._('category', v);
  static Qualifier path(String v) => TextQualifier._('path', v);
  static Qualifier filename(String v) => TextQualifier._('filename', v);
  static Qualifier extension_(String v) => TextQualifier._('extension', v);
  static Qualifier symbol(String v) => TextQualifier._('symbol', v);
  static Qualifier content(String v) => TextQualifier._('content', v);

  static Qualifier stars(NumericRange r) => NumericQualifier._('stars', r);
  static Qualifier forks(NumericRange r) => NumericQualifier._('forks', r);
  static Qualifier comments(NumericRange r) =>
      NumericQualifier._('comments', r);
  static Qualifier reactions(NumericRange r) =>
      NumericQualifier._('reactions', r);
  static Qualifier interactions(NumericRange r) =>
      NumericQualifier._('interactions', r);
  static Qualifier size(NumericRange r) => NumericQualifier._('size', r);
  static Qualifier followers(NumericRange r) =>
      NumericQualifier._('followers', r);

  static Qualifier created(DateRange r) => DateQualifier._('created', r);
  static Qualifier updated(DateRange r) => DateQualifier._('updated', r);
  static Qualifier pushed(DateRange r) => DateQualifier._('pushed', r);
  static Qualifier closed(DateRange r) => DateQualifier._('closed', r);
  static Qualifier merged(DateRange r) => DateQualifier._('merged', r);

  static Qualifier team(String orgSlashTeam) =>
      TeamQualifier._('team', orgSlashTeam);
  static Qualifier teamReviewRequested(String v) =>
      TeamQualifier._('team-review-requested', v);
  static Qualifier project(String path) => ProjectQualifier(path);
  static Qualifier forkInclude() => const ForkQualifier(ForkOption.include);
  static Qualifier forkOnly() => const ForkQualifier(ForkOption.only);

  /// Returns a copy with viewer login substituted when qualifier uses empty login.
  /// Used when building count query variables; other qualifiers return this.
  Qualifier withViewer(String viewer) => this;

  /// Serializes for CustomFilter persistence. Subclasses implement.
  Map<String, dynamic> toJson() => <String, dynamic>{};

  /// Deserializes from JSON. Uses [type] key to dispatch.
  static Qualifier fromJson(Map<String, dynamic> json) {
    final String type = json['type'] as String? ?? '';
    switch (type) {
      case 'is':
        return IsQualifier(
          IsOption.values.byName(json['value'] as String? ?? 'open'),
        );
      case 'state':
        return StateQualifier(
          StateOption.values.byName(json['value'] as String? ?? 'open'),
        );
      case 'type':
        return TypeQualifier(
          TypeOption.values.byName(json['value'] as String? ?? 'issue'),
        );
      case 'user':
        return UserQualifier._(
          json['key'] as String? ?? 'author',
          UserRef(login: json['login'] as String? ?? ''),
        );
      case 'repo':
        return RepoQualifier(RepoRef(
          owner: json['owner'] as String? ?? '',
          name: json['name'] as String? ?? '',
        ));
      case 'text':
        return TextQualifier._(
          json['key'] as String? ?? 'label',
          json['value'] as String? ?? '',
        );
      case 'bool':
        return BoolQualifier._(
          json['key'] as String? ?? 'draft',
          json['value'] as bool? ?? false,
        );
      default:
        throw ArgumentError('Unknown Qualifier type: $type');
    }
  }
}

// ─── is: option enums ───
enum IsOption {
  open,
  closed,
  merged,
  unmerged,
  public_,
  private_,
  internal_,
  locked,
  unlocked,
  answered,
  unanswered,
  curated,
  featured,
  sponsorable,
  queued;

  String get queryValue => switch (this) {
        IsOption.public_ => 'public',
        IsOption.private_ => 'private',
        IsOption.internal_ => 'internal',
        _ => name,
      };
}

enum StateOption { open, closed }

enum TypeOption { issue, pr, user, org }

enum ReviewOption { none, required_, approved, changesRequested }

enum CloseReason { completed, notPlanned, reopened }

enum NoOption { label, milestone, assignee, project }

enum LinkedOption { pr, issue }

enum ForkOption { include, only }

enum InOption {
  title,
  body,
  comments,
  name,
  description,
  readme,
  login,
  email,
  file,
  path,
}

// ─── is: qualifiers ───
final class IsQualifier extends Qualifier {
  const IsQualifier(this.option);
  final IsOption option;
  @override
  String toQueryString() => 'is:${option.queryValue}';
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'type': 'is', 'value': option.name};
}

final class StateQualifier extends Qualifier {
  const StateQualifier(this.option);
  final StateOption option;
  @override
  String toQueryString() => 'state:${option.name}';
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'type': 'state', 'value': option.name};
}

final class TypeQualifier extends Qualifier {
  const TypeQualifier(this.option);
  final TypeOption option;
  @override
  String toQueryString() => 'type:${option.name}';
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'type': 'type', 'value': option.name};
}

final class ReviewQualifier extends Qualifier {
  const ReviewQualifier(this.option);
  final ReviewOption option;
  @override
  String toQueryString() =>
      'review:${option == ReviewOption.required_ ? 'required' : option.name}';
}

final class CloseReasonQualifier extends Qualifier {
  const CloseReasonQualifier(this.reason);
  final CloseReason reason;
  @override
  String toQueryString() =>
      'reason:${reason == CloseReason.notPlanned ? '"not planned"' : reason.name}';
}

final class BoolQualifier extends Qualifier {
  const BoolQualifier._(this.key, this.value);
  final String key;
  final bool value;
  @override
  String toQueryString() => '$key:$value';
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'type': 'bool', 'key': key, 'value': value};
}

final class UserQualifier extends Qualifier {
  const UserQualifier._(this.key, this.user);
  final String key;
  final UserRef user;
  @override
  String toQueryString() => '$key:${user.login}';
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'type': 'user', 'key': key, 'login': user.login};
  @override
  Qualifier withViewer(String viewer) => UserQualifier._(
        key,
        user.login.isEmpty ? UserRef(login: viewer) : user,
      );
}

final class RepoQualifier extends Qualifier {
  const RepoQualifier(this.repo);
  final RepoRef repo;
  @override
  String toQueryString() => 'repo:${repo.fullName}';
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'repo',
        'owner': repo.owner,
        'name': repo.name,
      };
}

final class OrgQualifier extends Qualifier {
  const OrgQualifier(this.orgLogin);
  final String orgLogin;
  @override
  String toQueryString() => 'org:$orgLogin';
}

final class TextQualifier extends Qualifier {
  const TextQualifier._(this.key, this.value);
  final String key;
  final String value;
  @override
  String toQueryString() =>
      value.contains(' ') ? '$key:"$value"' : '$key:$value';
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'type': 'text', 'key': key, 'value': value};
}

final class NumericQualifier extends Qualifier {
  const NumericQualifier._(this.key, this.range);
  final String key;
  final NumericRange range;
  @override
  String toQueryString() => '$key:${range.toRangeString()}';
}

final class DateQualifier extends Qualifier {
  const DateQualifier._(this.key, this.range);
  final String key;
  final DateRange range;
  @override
  String toQueryString() => '$key:${range.toRangeString()}';
}

final class TeamQualifier extends Qualifier {
  const TeamQualifier._(this.key, this.orgSlashTeam);
  final String key;
  final String orgSlashTeam;
  @override
  String toQueryString() => '$key:$orgSlashTeam';
}

final class ProjectQualifier extends Qualifier {
  const ProjectQualifier(this.projectPath);
  final String projectPath;
  @override
  String toQueryString() => 'project:$projectPath';
}

final class ForkQualifier extends Qualifier {
  const ForkQualifier(this.option);
  final ForkOption option;
  @override
  String toQueryString() =>
      'fork:${option == ForkOption.only ? 'only' : 'true'}';
}
