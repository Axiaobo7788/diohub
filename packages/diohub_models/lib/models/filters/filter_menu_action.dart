/// Filter management menu action.
enum FilterMenuAction {
  edit,
  delete,
  duplicate,
  share;

  factory FilterMenuAction.fromString(String value) {
    return switch (value.toLowerCase()) {
      'edit' => FilterMenuAction.edit,
      'delete' => FilterMenuAction.delete,
      'duplicate' => FilterMenuAction.duplicate,
      'share' => FilterMenuAction.share,
      _ => FilterMenuAction.edit,
    };
  }
}
