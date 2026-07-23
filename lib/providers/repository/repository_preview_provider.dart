import 'package:diohub/models/repository_preview.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RepositoryPreviewNotifier extends Notifier<RepositoryPreview?> {
  RepositoryPreviewNotifier(this.repoRef);

  final RepoRef repoRef;

  @override
  RepositoryPreview? build() => null;

  void seed(final RepositoryPreview preview) {
    if (preview.fullName == repoRef.fullName) {
      state = preview;
    }
  }

  void clear() => state = null;
}

/// Session-local repository previews keyed by the exact route reference.
///
/// This provider intentionally is not auto-disposed: a recently opened
/// repository should retain its lightweight identity snapshot when navigating
/// back and forth, while the full API provider keeps its own independent TTL.
final repositoryPreviewProvider =
    NotifierProvider.family<
      RepositoryPreviewNotifier,
      RepositoryPreview?,
      RepoRef
    >(RepositoryPreviewNotifier.new);
