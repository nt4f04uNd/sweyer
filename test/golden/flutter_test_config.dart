import 'dart:async';

import 'package:golden_toolkit/golden_toolkit.dart';

// Load fonts for goldens, taken from https://pub.dev/packages/golden_toolkit#loading-fonts
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  return testMain();
}
