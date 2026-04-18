/// Canonicalizes a platform-specific node ID for DB storage.
///
/// GitHub IDs are prefixed with 'gh:' for global uniqueness when
/// GitLab/Gitea support is added. Apply at adapter boundary (API → EntityRef).
extension CanonicalNodeId on String {
  String get asGitHubNodeId => 'gh:$this';
}
