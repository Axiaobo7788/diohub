/// Filter types for Home Issues and Pulls positions.
enum HomeFilter {
  assigned,
  mentioned;

  String get value {
    switch (this) {
      case HomeFilter.assigned:
        return 'assigned';
      case HomeFilter.mentioned:
        return 'mentioned';
    }
  }

  static HomeFilter? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'assigned':
        return HomeFilter.assigned;
      case 'mentioned':
        return HomeFilter.mentioned;
      default:
        return null;
    }
  }
}
