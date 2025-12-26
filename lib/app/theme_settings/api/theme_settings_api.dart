import 'dart:async';
import 'dart:convert';

import 'package:diohub/app/global.dart';
import 'package:flutter/foundation.dart';

/// A new settings API for theme settings that doesn't use the existing Settings<T> base
/// This provides a more flexible approach for complex nested settings
abstract class ThemeSettingsApi<T> extends ChangeNotifier {
  ThemeSettingsApi({
    required this.storageKey,
    required this.defaultValue,
    this.version = 1,
  }) {
    _loadSettings();
  }

  final String storageKey;
  final T defaultValue;
  final int version;

  late T _value;
  T get value => _value;

  /// Load settings from storage
  Future<void> _loadSettings() async {
    _value = defaultValue;
    try {
      final String? data = sharedPrefs.getString(storageKey);
      if (data != null) {
        final Map<String, dynamic> content = jsonDecode(data) as Map<String, dynamic>;
        if (content['version'] == version) {
          _value = fromJson(content['data'] as Map<String, dynamic>);
          notifyListeners();
        } else {
          // Version mismatch, reset to default
          await _clearStorage();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading settings for $storageKey: $e');
      }
      await _clearStorage();
    }
  }

  /// Save settings to storage
  Future<void> save() async {
    try {
      final Map<String, dynamic> data = {
        'version': version,
        'data': toJson(_value),
      };
      await sharedPrefs.setString(storageKey, jsonEncode(data));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving settings for $storageKey: $e');
      }
    }
  }

  /// Update the value and save
  Future<void> update(T newValue) async {
    if (_value != newValue) {
      _value = newValue;
      await save();
    }
  }

  /// Reset to default value
  Future<void> reset() async {
    _value = defaultValue;
    await _clearStorage();
    notifyListeners();
  }

  /// Clear storage
  Future<void> _clearStorage() async {
    await sharedPrefs.remove(storageKey);
  }

  /// Convert value to JSON
  Map<String, dynamic> toJson(T value);

  /// Convert JSON to value
  T fromJson(Map<String, dynamic> json);
}

