import 'package:diohub/app/app_logger.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> setHighRefreshRate() async {
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e, stackTrace) {
    AppLogger.warning(
      'Error setting high refresh rate display mode',
      error: e,
      stackTrace: stackTrace,
      tag: 'Display',
    );
  }
}
