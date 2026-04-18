enum AuthorAssociation {
  collaborator,
  contributor,
  firstTimeContributor,
  firstTimer,
  mannequin,
  member,
  none,
  owner;

  factory AuthorAssociation.fromString(String value) {
    final normalized = value.toUpperCase();
    return switch (normalized) {
      'COLLABORATOR' => AuthorAssociation.collaborator,
      'CONTRIBUTOR' => AuthorAssociation.contributor,
      'FIRST_TIME_CONTRIBUTOR' => AuthorAssociation.firstTimeContributor,
      'FIRST_TIMER' => AuthorAssociation.firstTimer,
      'MANNEQUIN' => AuthorAssociation.mannequin,
      'MEMBER' => AuthorAssociation.member,
      'NONE' => AuthorAssociation.none,
      'OWNER' => AuthorAssociation.owner,
      _ => AuthorAssociation.none,
    };
  }

  String get displayName => switch (this) {
    AuthorAssociation.owner => 'OWNER',
    AuthorAssociation.member => 'MEMBER',
    AuthorAssociation.contributor => 'CONTRIBUTOR',
    AuthorAssociation.firstTimeContributor => 'FIRST TIME',
    AuthorAssociation.firstTimer => 'FIRST TIMER',
    AuthorAssociation.mannequin => 'MANNEQUIN',
    AuthorAssociation.collaborator => 'COLLABORATOR',
    AuthorAssociation.none => 'NONE',
  };
}
