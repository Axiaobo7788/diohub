import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/charts/traffic_line_chart.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrafficLineChart', () {
    testWidgets('renders without error when given empty data', (
      final WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            settingsCacheProvider.overrideWithValue(
              SettingsCache(<String, String>{}),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TrafficLineChart(
                timestamps: <String?>[],
                counts: <int>[],
                uniques: <int>[],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(TrafficLineChart), findsOneWidget);
    });

    testWidgets('renders without error when given 14-day data', (
      final WidgetTester tester,
    ) async {
      final List<String?> timestamps = List<String?>.generate(
        14,
        (final int i) => DateTime(2024, 1, 1 + i).toIso8601String(),
      );
      final List<int> counts = List<int>.generate(14, (final int i) => 10 + i);
      final List<int> uniques = List<int>.generate(14, (final int i) => 5 + i);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            settingsCacheProvider.overrideWithValue(
              SettingsCache(<String, String>{}),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TrafficLineChart(
                timestamps: timestamps,
                counts: counts,
                uniques: uniques,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(TrafficLineChart), findsOneWidget);
    });
  });
}
