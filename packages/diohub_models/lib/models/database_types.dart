/// Re-exports database enums and extensions for use by view and other layers
/// that must not depend on [database/] directly.
library;

import 'package:diohub_models/models/entity_ref.dart';

export 'package:diohub_database/database/database.dart' show HistoryWithEntity, SavedSearchEntry;
export 'package:diohub_database/database/enums/enums.dart';
export 'package:diohub_database/database/extensions/entity_ref_dao_extensions.dart';

/// View-layer data shape for a saved search. Use this instead of [SavedSearchEntry]
/// in views/common so they do not depend on [database/].
typedef ViewSafeSavedSearch = ({
  String query,
  String? label,
  DateTime savedAt,
});

/// View-layer data shape for a history list item. Use this instead of
/// [HistoryWithEntity] in views/common so they do not depend on [database/].
/// [displayTitle] is typically entity.snapshotTitle ?? entity.entityPath.
typedef ViewSafeHistoryEntry = ({
  String nodeId,
  String displayTitle,
  EntityRef? entityRef,
});
