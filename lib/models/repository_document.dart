/// A document surfaced by the repository Code page document tabs.
enum RepositoryDocumentKind { readme, contributing, license, security }

/// How [RepositoryDocument.content] should be rendered.
enum RepositoryDocumentFormat { html, markdown }

/// Repository document content together with the metadata required to render it.
///
/// GitHub renders README, CONTRIBUTING and SECURITY files when they are fetched
/// with its HTML media type. The existing license provider returns the source
/// text instead, so callers must retain the format distinction.
class RepositoryDocument {
  const RepositoryDocument({
    required this.kind,
    required this.branch,
    required this.content,
    required this.format,
    this.path,
  });

  final RepositoryDocumentKind kind;
  final String branch;
  final String content;
  final RepositoryDocumentFormat format;

  /// The repository-relative path when the Contents API resolved one of the
  /// supported community-file locations.
  final String? path;
}
