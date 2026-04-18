/// REST GET /user response fields used to build [AccountModel].
class ViewerUserPayload {
  const ViewerUserPayload({
    required this.nodeId,
    required this.login,
    this.name,
    this.avatarUrl,
  });

  final String nodeId;
  final String login;
  final String? name;
  final String? avatarUrl;

  factory ViewerUserPayload.fromJson(Map<String, dynamic> json) {
    return ViewerUserPayload(
      nodeId: json['node_id'] as String,
      login: json['login'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
