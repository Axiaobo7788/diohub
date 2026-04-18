/// Social media provider type.
enum SocialProvider {
  twitter,
  x,
  linkedin,
  mastodon,
  generic;

  factory SocialProvider.fromString(String value) {
    return switch (value.toUpperCase()) {
      'TWITTER' => SocialProvider.twitter,
      'X' => SocialProvider.x,
      'LINKEDIN' => SocialProvider.linkedin,
      'MASTODON' => SocialProvider.mastodon,
      _ => SocialProvider.generic,
    };
  }
}
