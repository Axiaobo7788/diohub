import 'package:flutter/material.dart';

/// Serialize [EdgeInsets] as [left, top, right, bottom] for JSON persistence.
List<double> edgeInsetsToJson(final EdgeInsets e) =>
    <double>[e.left, e.top, e.right, e.bottom];

/// Deserialize [EdgeInsets] from JSON (list of 4 numbers).
EdgeInsets edgeInsetsFromJson(final dynamic v) {
  if (v is List && v.length >= 4) {
    return EdgeInsets.fromLTRB(
      (v[0] as num).toDouble(),
      (v[1] as num).toDouble(),
      (v[2] as num).toDouble(),
      (v[3] as num).toDouble(),
    );
  }
  return EdgeInsets.zero;
}

/// Read [EdgeInsets] from [json][key], or [defaultValue] if key is absent.
EdgeInsets edgeInsetsFromJsonOr(
  final Map<String, dynamic> json,
  final String key,
  final EdgeInsets defaultValue,
) =>
    json.containsKey(key) ? edgeInsetsFromJson(json[key]) : defaultValue;

/// Read [double] from [json][key], or [defaultValue] if absent/invalid.
double doubleFromJsonOr(
  final Map<String, dynamic> json,
  final String key,
  final double defaultValue,
) =>
    (json[key] as num?)?.toDouble() ?? defaultValue;

/// Read [bool] from [json][key], or [defaultValue] if absent/invalid.
bool boolFromJsonOr(
  final Map<String, dynamic> json,
  final String key,
  final bool defaultValue,
) =>
    json[key] as bool? ?? defaultValue;
