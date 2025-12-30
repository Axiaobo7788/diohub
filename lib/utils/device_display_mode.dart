import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> setHighRefreshRate() async {
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e) {
    // Error setting display mode
  }
}
