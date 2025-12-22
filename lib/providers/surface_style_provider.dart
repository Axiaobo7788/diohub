import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';

/// Provider for managing surface styling preferences across the app
///
/// This allows users to customize border shapes, radii, and other
/// surface styling properties app-wide through settings.
class SurfaceStyleProvider extends ChangeNotifier {
  SurfaceStyleProvider({
    BorderShapeType? initialShapeType,
    double? initialSmallRadius,
    double? initialMediumRadius,
    double? initialLargeRadius,
    double? initialCornerSmoothing,
  })  : _shapeType = initialShapeType ?? BorderShapeType.rounded,
        _smallRadius = initialSmallRadius ?? 8,
        _mediumRadius = initialMediumRadius ?? 12,
        _largeRadius = initialLargeRadius ?? 16,
        _cornerSmoothing = initialCornerSmoothing ?? 0.5;

  BorderShapeType _shapeType;
  double _smallRadius;
  double _mediumRadius;
  double _largeRadius;
  double _cornerSmoothing;

  /// Current shape type (rounded or squircle)
  BorderShapeType get shapeType => _shapeType;

  /// Current small radius value
  double get smallRadius => _smallRadius;

  /// Current medium radius value
  double get mediumRadius => _mediumRadius;

  /// Current large radius value
  double get largeRadius => _largeRadius;

  /// Current corner smoothing value (for squircle)
  double get cornerSmoothing => _cornerSmoothing;

  /// Get the current surface style theme
  SurfaceStyleTheme get theme => SurfaceStyleTheme(
        shapeType: _shapeType,
        smallRadius: _smallRadius,
        mediumRadius: _mediumRadius,
        largeRadius: _largeRadius,
        cornerSmoothing: _cornerSmoothing,
      );

  /// Update shape type
  void setShapeType(BorderShapeType shapeType) {
    if (_shapeType != shapeType) {
      _shapeType = shapeType;
      notifyListeners();
    }
  }

  /// Update all radii at once
  void setRadii({
    double? small,
    double? medium,
    double? large,
  }) {
    bool changed = false;
    if (small != null && _smallRadius != small) {
      _smallRadius = small;
      changed = true;
    }
    if (medium != null && _mediumRadius != medium) {
      _mediumRadius = medium;
      changed = true;
    }
    if (large != null && _largeRadius != large) {
      _largeRadius = large;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Update corner smoothing (for squircle)
  void setCornerSmoothing(double smoothing) {
    if (_cornerSmoothing != smoothing) {
      _cornerSmoothing = smoothing;
      notifyListeners();
    }
  }

  /// Reset to defaults
  void reset() {
    _shapeType = BorderShapeType.rounded;
    _smallRadius = 8;
    _mediumRadius = 12;
    _largeRadius = 16;
    _cornerSmoothing = 0.5;
    notifyListeners();
  }
}
