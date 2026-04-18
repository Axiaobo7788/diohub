/// Filter section identifier.
enum FilterSection {
  label,
  assignee,
  milestone,
  author,
  sort;

  factory FilterSection.fromString(String value) {
    return switch (value.toLowerCase()) {
      'label' => FilterSection.label,
      'assignee' => FilterSection.assignee,
      'milestone' => FilterSection.milestone,
      'author' => FilterSection.author,
      'sort' => FilterSection.sort,
      _ => FilterSection.label,
    };
  }

  String get id => switch (this) {
    FilterSection.label => 'label',
    FilterSection.assignee => 'assignee',
    FilterSection.milestone => 'milestone',
    FilterSection.author => 'author',
    FilterSection.sort => 'sort',
  };
}
