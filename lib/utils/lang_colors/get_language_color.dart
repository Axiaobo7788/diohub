import 'dart:collection';
import 'dart:convert';

import 'package:diohub/utils/hex_color.dart';
import 'package:diohub/utils/lang_colors/colors_data.dart';
import 'package:flutter/material.dart';

int getLangColor(final String? language) {
  final LinkedHashMap<String, dynamic> langData =
      LinkedHashMap<String, dynamic>(
        equals: (final String a, final String b) =>
            a.toLowerCase() == b.toLowerCase(),
        hashCode: (final String p0) => p0.toLowerCase().hashCode,
        //  (key) => key.toLowerCase().hashCode
      );
  final Object? decoded = jsonDecode(colorsData);
  if (decoded is Map<String, dynamic>) {
    langData.addAll(decoded);
  }
  if (langData.containsKey(language)) {
    final Object? langEntry = langData[language];
    if (langEntry is Map<String, dynamic> && langEntry['color'] is String) {
      final String color = langEntry['color']! as String;
      return tryParseHexColor(color, fallback: const Color(0xFF878787))!.value;
    }
  }
  return 0xFF878787;
}
