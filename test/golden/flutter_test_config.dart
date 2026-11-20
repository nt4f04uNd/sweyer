import 'dart:async' show FutureOr;

import 'package:flutter_test/flutter_test.dart' show setUpAll;

import 'framework/golden.dart' show loadAppFonts;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(loadAppFonts);
  await testMain();
}
