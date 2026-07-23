import 'package:diohub/app/settings/code_browser_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('per-path last-commit requests are opt-in', () {
    expect(const CodeBrowserSettings().showLastCommitInfo, isFalse);
    expect(
      CodeBrowserSettings.fromJson(<String, dynamic>{}).showLastCommitInfo,
      isFalse,
    );
  });
}
