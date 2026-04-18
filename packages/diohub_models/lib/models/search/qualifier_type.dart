/// Search qualifier type.
enum QualifierType {
  text,
  choice,
  date,
  number;

  factory QualifierType.fromString(String value) {
    return switch (value.toLowerCase()) {
      'text' => QualifierType.text,
      'choice' => QualifierType.choice,
      'date' => QualifierType.date,
      'number' => QualifierType.number,
      _ => QualifierType.text,
    };
  }
}
