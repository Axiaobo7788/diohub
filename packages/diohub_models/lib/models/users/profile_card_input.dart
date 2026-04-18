import 'package:diohub_graphql/fragments/fragment_typedefs.dart' as gql;
import 'package:diohub_graphql/queries/users/user_typedefs.dart';

/// User data for profile card: fragment (list/search) or full (from userProvider).
sealed class UserCardData {
  const UserCardData();
  
  String get login;
  String? get id;
  Uri? get avatarUrl;
  Uri get url;
  String? get name;
  String? get bio;
  String? get location;
  String? get company;
  String? get pronouns;
  DateTime? get createdAt;
  int? get repositoryCount;
  int? get followerCount;
  int? get followingCount;
  bool get viewerIsFollowing;
  bool get viewerCanFollow;
  bool get isFollowingViewer;
  String? get statusEmoji;
  String? get statusMessage;
}

class FragmentUser extends UserCardData {
  const FragmentUser(this.user);
  final gql.UserCardData user;
  
  @override String get login => user.login;
  @override String? get id => user.id;
  @override Uri? get avatarUrl => user.avatarUrl;
  @override Uri get url => user.url;
  @override String? get name => user.name;
  @override String? get bio => user.bio;
  @override String? get location => user.location;
  @override String? get company => user.company;
  @override String? get pronouns => user.pronouns;
  @override DateTime? get createdAt => user.createdAt;
  @override int? get repositoryCount => user.repositories.totalCount;
  @override int? get followerCount => user.followers.totalCount;
  @override int? get followingCount => user.following.totalCount;
  @override bool get viewerIsFollowing => user.viewerIsFollowing;
  @override bool get viewerCanFollow => user.viewerCanFollow;
  @override bool get isFollowingViewer => user.isFollowingViewer;
  @override String? get statusEmoji => user.status?.emoji;
  @override String? get statusMessage => user.status?.message;
}

class FullUser extends UserCardData {
  const FullUser(this.user);
  final UserProfile user;
  
  @override String get login => user.login;
  @override String? get id => user.id;
  @override Uri? get avatarUrl => user.avatarUrl;
  @override Uri get url => user.url;
  @override String? get name => user.name;
  @override String? get bio => user.bio;
  @override String? get location => user.location;
  @override String? get company => user.company;
  @override String? get pronouns => user.pronouns;
  @override DateTime? get createdAt => user.createdAt;
  @override int? get repositoryCount => user.repositories.totalCount;
  @override int? get followerCount => user.followers.totalCount;
  @override int? get followingCount => user.following.totalCount;
  @override bool get viewerIsFollowing => user.viewerIsFollowing;
  @override bool get viewerCanFollow => user.viewerCanFollow;
  @override bool get isFollowingViewer => user.isFollowingViewer;
  @override String? get statusEmoji => user.status?.emoji;
  @override String? get statusMessage => user.status?.message;
}

/// Org data for profile card: fragment (list/search) or full (from userProvider).
sealed class OrgCardData {
  const OrgCardData();
  
  String get login;
  String? get id;
  Uri? get avatarUrl;
  Uri get url;
  String? get name;
  String? get bio;
  String? get location;
  Uri? get websiteUrl;
  int? get repositoryCount;
  int? get membersCount;
  int? get teamsCount;
  bool get viewerIsFollowing;
  bool get isVerified;
}

class FragmentOrg extends OrgCardData {
  const FragmentOrg(this.org);
  final gql.OrgCardData org;
  
  @override String get login => org.login;
  @override String? get id => org.id;
  @override Uri? get avatarUrl => org.avatarUrl;
  @override Uri get url => org.url;
  @override String? get name => org.name;
  @override String? get bio => org.description;
  @override String? get location => org.location;
  @override Uri? get websiteUrl => org.websiteUrl;
  @override int? get repositoryCount => org.repositories.totalCount;
  @override int? get membersCount => org.membersWithRole.totalCount;
  @override int? get teamsCount => org.teams.totalCount;
  @override bool get viewerIsFollowing => org.viewerIsFollowing;
  @override bool get isVerified => org.isVerified;
}

class FullOrg extends OrgCardData {
  const FullOrg(this.org);
  final OrgProfile org;
  
  @override String get login => org.login;
  @override String? get id => org.id;
  @override Uri? get avatarUrl => org.avatarUrl;
  @override Uri get url => org.url;
  @override String? get name => org.name;
  @override String? get bio => org.description;
  @override String? get location => org.location;
  @override Uri? get websiteUrl => org.websiteUrl;
  @override int? get repositoryCount => org.repositories.totalCount;
  @override int? get membersCount => org.membersWithRole.totalCount;
  @override int? get teamsCount => org.teams.totalCount;
  @override bool get viewerIsFollowing => org.viewerIsFollowing;
  @override bool get isVerified => org.isVerified;
}

/// Input for ProfileCard - polymorphic, no switch statements needed.
sealed class ProfileCardInput {
  const ProfileCardInput();
  
  String get login;
  String? get id;
  Uri? get avatarUrl;
  Uri get profileUrl;
  String? get name;
  String? get bio;
  String? get location;
  int? get repositoryCount;
  bool get viewerIsFollowing;
  bool get isOrganization;
  
  // User-specific getters (null for org)
  bool get viewerCanFollow;
  int? get membersOrFollowersCount;
  int? get following;
  String? get statusEmoji;
  String? get statusMessage;
  String? get company;
  bool get isFollowingViewer;
  String? get pronouns;
  DateTime? get createdAt;
  
  // Org-specific getters (null/false for user)
  bool get isVerified;
  int? get membersCount;
  int? get teamsCount;
  Uri? get websiteUrl;
}

class ProfileCardInputUser extends ProfileCardInput {
  const ProfileCardInputUser(this.user);
  final UserCardData user;
  
  @override String get login => user.login;
  @override String? get id => user.id;
  @override Uri? get avatarUrl => user.avatarUrl;
  @override Uri get profileUrl => user.url;
  @override String? get name => user.name;
  @override String? get bio => user.bio;
  @override String? get location => user.location;
  @override int? get repositoryCount => user.repositoryCount;
  @override bool get viewerIsFollowing => user.viewerIsFollowing;
  @override bool get isOrganization => false;
  
  @override bool get viewerCanFollow => user.viewerCanFollow;
  @override int? get membersOrFollowersCount => user.followerCount;
  @override int? get following => user.followingCount;
  @override String? get statusEmoji => user.statusEmoji;
  @override String? get statusMessage => user.statusMessage;
  @override String? get company => user.company;
  @override bool get isFollowingViewer => user.isFollowingViewer;
  @override String? get pronouns => user.pronouns;
  @override DateTime? get createdAt => user.createdAt;
  
  // Org-specific getters return null/false for users
  @override bool get isVerified => false;
  @override int? get membersCount => null;
  @override int? get teamsCount => null;
  @override Uri? get websiteUrl => null;
}

class ProfileCardInputOrg extends ProfileCardInput {
  const ProfileCardInputOrg(this.org);
  final OrgCardData org;
  
  @override String get login => org.login;
  @override String? get id => org.id;
  @override Uri? get avatarUrl => org.avatarUrl;
  @override Uri get profileUrl => org.url;
  @override String? get name => org.name;
  @override String? get bio => org.bio;
  @override String? get location => org.location;
  @override int? get repositoryCount => org.repositoryCount;
  @override bool get viewerIsFollowing => org.viewerIsFollowing;
  @override bool get isOrganization => true;
  
  @override bool get viewerCanFollow => false;
  @override int? get membersOrFollowersCount => null;
  @override int? get following => null;
  @override bool get isVerified => org.isVerified;
  @override int? get membersCount => org.membersCount;
  @override int? get teamsCount => org.teamsCount;
  @override Uri? get websiteUrl => org.websiteUrl;
  
  // User-specific getters return null/false for orgs
  @override String? get statusEmoji => null;
  @override String? get statusMessage => null;
  @override String? get company => null;
  @override bool get isFollowingViewer => false;
  @override String? get pronouns => null;
  @override DateTime? get createdAt => null;
}
