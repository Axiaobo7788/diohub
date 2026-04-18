import 'package:diohub_lint/src/helpers/path_utils.dart';
import 'package:test/test.dart';

void main() {
  group('resolveLayer', () {
    test('returns view for lib/view/ path', () {
      expect(
        resolveLayer('/project/diohub/lib/view/home/home.dart'),
        AppLayer.view,
      );
      expect(resolveLayer('lib/view/foo.dart'), AppLayer.view);
    });

    test('returns providers for lib/providers/ path', () {
      expect(resolveLayer('lib/providers/foo.dart'), AppLayer.providers);
    });

    test('returns services for lib/services/ path', () {
      expect(resolveLayer('lib/services/auth.dart'), AppLayer.services);
    });

    test('returns common for lib/common/ path', () {
      expect(resolveLayer('lib/common/widgets/bar.dart'), AppLayer.common);
    });

    test('returns database for lib/database/ path', () {
      expect(resolveLayer('lib/database/daos/foo.dart'), AppLayer.database);
    });

    test('returns style for lib/style/ path', () {
      expect(resolveLayer('lib/style/theme.dart'), AppLayer.style);
    });

    test('returns unknown when lib/ is missing', () {
      expect(resolveLayer('view/home.dart'), AppLayer.unknown);
    });
  });

  group('resolveImportLayer', () {
    test('returns view for package:diohub/view/ import', () {
      expect(
        resolveImportLayer('package:diohub/view/home/home.dart'),
        AppLayer.view,
      );
    });

    test('returns services for package:diohub/services/ import', () {
      expect(
        resolveImportLayer('package:diohub/services/auth_service.dart'),
        AppLayer.services,
      );
    });

    test('returns unknown for non-diohub package', () {
      expect(
        resolveImportLayer('package:flutter/material.dart'),
        AppLayer.unknown,
      );
    });
  });
}
