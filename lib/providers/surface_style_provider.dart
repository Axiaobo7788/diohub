import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';

/// Provider for managing surface styling preferences across the app
///
/// This allows users to customize border shapes, radii, and other
/// surface styling properties app-wide through settings.
class SurfaceStyleProvider extends ChangeNotifier {
  SurfaceStyleProvider({
    BorderShapeType? initialShapeType,
    double? initialSoftRadius,
    double? initialSmallRadius,
    double? initialMediumRadius,
    double? initialLargeRadius,
    double? initialVeryLargeRadius,
    double? initialCornerSmoothing,
  })  : _shapeType = initialShapeType ?? BorderShapeType.rounded,
        _softRadius = initialSoftRadius ?? 4,
        _smallRadius = initialSmallRadius ?? 10,
        _mediumRadius = initialMediumRadius ?? 14,
        _largeRadius = initialLargeRadius ?? 18,
        _veryLargeRadius = initialVeryLargeRadius ?? 28,
        _cornerSmoothing = initialCornerSmoothing ?? 0.5;

  BorderShapeType _shapeType;
  double _softRadius;
  double _smallRadius;
  double _mediumRadius;
  double _largeRadius;
  double _veryLargeRadius;
  double _cornerSmoothing;

  /// Current shape type (rounded or squircle)
  BorderShapeType get shapeType => _shapeType;

  /// Current soft radius value
  double get softRadius => _softRadius;

  /// Current small radius value
  double get smallRadius => _smallRadius;

  /// Current medium radius value
  double get mediumRadius => _mediumRadius;

  /// Current large radius value
  double get largeRadius => _largeRadius;

  /// Current very large radius value
  double get veryLargeRadius => _veryLargeRadius;

  /// Current corner smoothing value (for squircle)
  double get cornerSmoothing => _cornerSmoothing;

  /// Get the current surface style theme
  SurfaceStyleTheme get theme => SurfaceStyleTheme(
        shapeType: _shapeType,
        softRadius: _softRadius,
        smallRadius: _smallRadius,
        mediumRadius: _mediumRadius,
        largeRadius: _largeRadius,
        veryLargeRadius: _veryLargeRadius,
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
    double? soft,
    double? small,
    double? medium,
    double? large,
    double? veryLarge,
  }) {
    bool changed = false;
    if (soft != null && _softRadius != soft) {
      _softRadius = soft;
      changed = true;
    }
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
    if (veryLarge != null && _veryLargeRadius != veryLarge) {
      _veryLargeRadius = veryLarge;
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
    _softRadius = 4;
    _smallRadius = 10;
    _mediumRadius = 14;
    _largeRadius = 18;
    _veryLargeRadius = 28;
    _cornerSmoothing = 0.5;
    notifyListeners();
  }
}
