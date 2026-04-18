/// Home feed filter type.
enum HomeFilter {
  all,
  pulls,
  issues,
  discussions;

  factory HomeFilter.fromString(String value) {
    return switch (value.toLowerCase()) {
      'all' => HomeFilter.all,
      'pulls' => HomeFilter.pulls,
      'issues' => HomeFilter.issues,
      'discussions' => HomeFilter.discussions,
      _ => HomeFilter.all,
    };
  }
}
