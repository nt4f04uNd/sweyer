import 'dart:async';

import 'package:golden_toolkit/golden_toolkit.dart';

// Load fonts for goldens, taken from https://pub.dev/packages/golden_toolkit#loading-fonts
// Also enable real shadows
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return GoldenToolkit.runWithConfiguration(
    () async {
      await loadAppFonts();
      return testMain();
    },
    config: GoldenToolkitConfiguration(
      enableRealShadows: true,
    ),
  );
}
