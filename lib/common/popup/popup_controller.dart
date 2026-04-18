import 'package:flutter/foundation.dart';

/// Controller for managing popup open/close state
///
/// Can be used to programmatically control popup visibility
/// or to listen to state changes.
class PopupController extends ChangeNotifier {
  bool _isOpen = false;

  /// Whether the popup is currently open
  bool get isOpen => _isOpen;

  /// Open the popup
  void open() {
    if (!_isOpen) {
      _isOpen = true;
      notifyListeners();
    }
  }

  /// Close the popup
  void close() {
    if (_isOpen) {
      _isOpen = false;
      notifyListeners();
    }
  }

  /// Toggle the popup open/close state
  void toggle() {
    _isOpen = !_isOpen;
    notifyListeners();
  }
}
