import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Load the custom fonts from the assets.
// From https://pub.dev/documentation/golden_toolkit/latest/golden_toolkit/loadAppFonts.html
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fontManifest = await rootBundle.loadStructuredData<Iterable<dynamic>>(
    'FontManifest.json',
    (string) async => json.decode(string),
  );
  for (final Map<String, dynamic> font in fontManifest) {
    final fontLoader = FontLoader(font['family']);
    for (final Map<String, dynamic> fontType in font['fonts']) {
      fontLoader.addFont(rootBundle.load(fontType['asset']));
    }
    await fontLoader.load();
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(loadAppFonts);
  await testMain();
}
