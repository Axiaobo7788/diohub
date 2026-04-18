class AccessTokenModel {
  AccessTokenModel({
    this.accessToken,
    this.scope,
    this.refreshToken,
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
  });

  AccessTokenModel.fromJson(final Map<String, dynamic> json) {
    accessToken = json['access_token'] as String?;
    scope = json['scope'] as String?;
    refreshToken = json['refresh_token'] as String?;
    accessTokenExpiresAt = json['access_token_expires_at'] != null
        ? DateTime.parse(json['access_token_expires_at'] as String)
        : null;
    refreshTokenExpiresAt = json['refresh_token_expires_at'] != null
        ? DateTime.parse(json['refresh_token_expires_at'] as String)
        : null;
  }

  String? accessToken;
  String? scope;
  String? refreshToken;
  DateTime? accessTokenExpiresAt;
  DateTime? refreshTokenExpiresAt;

  bool get canRefresh => refreshToken != null;
  bool get isExpired =>
      accessTokenExpiresAt != null &&
      DateTime.now().isAfter(accessTokenExpiresAt!);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['access_token'] = accessToken;
    data['scope'] = scope;
    data['refresh_token'] = refreshToken;
    data['access_token_expires_at'] = accessTokenExpiresAt?.toIso8601String();
    data['refresh_token_expires_at'] = refreshTokenExpiresAt?.toIso8601String();
    return data;
  }
}
