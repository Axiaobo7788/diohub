/// Widget rendering mode type.
enum RenderMode {
  light,
  dark,
  system;

  factory RenderMode.fromString(String value) {
    return switch (value.toLowerCase()) {
      'light' => RenderMode.light,
      'dark' => RenderMode.dark,
      'system' => RenderMode.system,
      _ => RenderMode.system,
    };
  }
}
