/// One commit comment from REST GET /repos/.../commits/{sha}/comments.
class CommitCommentItem {
  const CommitCommentItem({
    required this.id,
    required this.body,
    this.bodyHtml,
    required this.createdAt,
    this.path,
    this.position,
    this.line,
    this.userLogin,
    this.userAvatarUrl,
  });

  final int id;
  final String body;
  final String? bodyHtml;
  final DateTime createdAt;
  final String? path;
  final int? position;
  final int? line;
  final String? userLogin;
  final String? userAvatarUrl;

  factory CommitCommentItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? user = json['user'] as Map<String, dynamic>?;
    return CommitCommentItem(
      id: json['id'] as int,
      body: json['body'] as String? ?? '',
      bodyHtml: json['body_html'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      path: json['path'] as String?,
      position: json['position'] as int?,
      line: json['line'] as int?,
      userLogin: user?['login'] as String?,
      userAvatarUrl: user?['avatar_url'] as String?,
    );
  }
}
