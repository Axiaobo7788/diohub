import 'package:diohub_lint/src/helpers/path_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Import layer resolution for rules', () {
    test('view importing services is forbidden', () {
      expect(resolveLayer('lib/view/screen.dart'), AppLayer.view);
      expect(
        resolveImportLayer('package:diohub/services/foo.dart'),
        AppLayer.services,
      );
    });

    test('common importing view is forbidden', () {
      expect(resolveLayer('lib/common/widget.dart'), AppLayer.common);
      expect(
        resolveImportLayer('package:diohub/view/home.dart'),
        AppLayer.view,
      );
    });

    test('providers importing view is forbidden', () {
      expect(resolveLayer('lib/providers/foo.dart'), AppLayer.providers);
      expect(
        resolveImportLayer('package:diohub/view/screen.dart'),
        AppLayer.view,
      );
    });

    test('models forbidden from view, providers, services', () {
      expect(resolveLayer('lib/models/entity.dart'), AppLayer.models);
      expect(resolveImportLayer('package:diohub/view/x.dart'), AppLayer.view);
      expect(
        resolveImportLayer('package:diohub/providers/x.dart'),
        AppLayer.providers,
      );
      expect(
        resolveImportLayer('package:diohub/services/x.dart'),
        AppLayer.services,
      );
    });

    test('view can import providers and common', () {
      expect(
        resolveImportLayer('package:diohub/providers/account_provider.dart'),
        AppLayer.providers,
      );
      expect(
        resolveImportLayer('package:diohub/common/widgets/bar.dart'),
        AppLayer.common,
      );
    });
  });
}
