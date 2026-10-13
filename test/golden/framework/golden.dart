import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, FontLoader, VoidCallback, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:freezed_annotation/freezed_annotation.dart' show isTest;
import 'package:path/path.dart' as path show joinAll;
import 'package:sweyer/features/player_interface_color_style/player_interface_color_style.dart'
    show PlayerInterfaceColorStyle;
import 'package:test_api/src/backend/invoker.dart' show Invoker;

import '../../test.dart' show Settings, ThemeControl, WidgetTesterExtension, registerPostAppSetup;
import 'test_description.dart' show getTestDescription;

extension GoldenWidgetTesterExtension on WidgetTester {
  /// Whether the current tester is running in [testAppGoldens] and
  /// in light mode.
  bool get lightThemeGolden => _testersLightTheme[this] ?? false;

  /// Whether the current tester is running in [testAppGoldens] and
  /// has non-default player interface style.
  PlayerInterfaceColorStyle? get nonDefaultPlayerInterfaceColorStyle => _testersPlayerInterfaceColorStyle[this];

  Future<void> _screenMatchesGolden(
    String name, {
    Future<void> Function(WidgetTester)? customPump,
  }) async {
    final testDescription = getTestDescription(
      lightTheme: lightThemeGolden,
      playerInterfaceColorStyle: nonDefaultPlayerInterfaceColorStyle,
    );
    name = testDescription.buildFileName(name);
    await _waitForAssets();
    if (customPump != null) {
      await customPump(this);
    } else {
      await pumpAndSettle();
    }
    await expectLater(
      find.byWidgetPredicate((widget) => true).first, // The whole screen
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  Future<void> _waitForAssets() async {
    final imageElements = find.byType(Image, skipOffstage: false).evaluate();
    final containerElements = find.byType(DecoratedBox, skipOffstage: false).evaluate();
    await runAsync(() async {
      for (final imageElement in imageElements) {
        final widget = imageElement.widget;
        if (widget is Image) {
          await precacheImage(widget.image, imageElement);
        }
      }
      for (final container in containerElements) {
        final widget = container.widget as DecoratedBox;
        final decoration = widget.decoration;
        if (decoration is BoxDecoration) {
          if (decoration.image != null) {
            await precacheImage(decoration.image!.image, container);
          }
        }
      }
    });
  }
}

final _testersLightTheme = <WidgetTester, bool>{};
final _testersPlayerInterfaceColorStyle = <WidgetTester, PlayerInterfaceColorStyle?>{};
const _defaultPlayerInterfaceColorStyle = PlayerInterfaceColorStyle.artColor;
const Object _defaultTagObject = Object();

/// Creates a golden test in two variants - in dark and light mode.
//
// TODO: weird, when run individually from IDE for some reason Dart extension throws
// "No tests match regular expression "^tabs_route idle_drawer( \(variant: .*\))?$"."
// report it here https://github.com/Dart-Code/Dart-Code/issues/new/choose
//
// More weird, just `testGoldens` itself works ok
@isTest
void testAppGoldens(
  String description,
  Future<void> Function(WidgetTester) test, {
  bool? skip,
  Object? tags = _defaultTagObject,
  Set<PlayerInterfaceColorStyle> playerInterfaceColorStylesToTest = const {_defaultPlayerInterfaceColorStyle},
  VoidCallback? setUp,
  Future<void> Function(WidgetTester)? customGoldenPump,
}) {
  assert(playerInterfaceColorStylesToTest.isNotEmpty);
  for (final lightTheme in [false, true]) {
    final nonDefaultPlayerInterfaceColorStyle = playerInterfaceColorStylesToTest.length > 1 ||
        !playerInterfaceColorStylesToTest.contains(_defaultPlayerInterfaceColorStyle);

    for (final playerInterfaceColorStyle in playerInterfaceColorStylesToTest) {
      final testDescription = getTestDescription(
        lightTheme: lightTheme,
        playerInterfaceColorStyle: nonDefaultPlayerInterfaceColorStyle ? playerInterfaceColorStyle : null,
      ).buildDescription(description);
      testWidgets(
        testDescription,
        (tester) async {
          final previousDebugDisableShadowsValue = debugDisableShadows;
          try {
            debugDisableShadows = false;
            final previousDeterministicCursor = EditableText.debugDeterministicCursor;
            addTearDown(() {
              EditableText.debugDeterministicCursor = previousDeterministicCursor;
              _testersLightTheme.remove(tester);
              _testersPlayerInterfaceColorStyle.remove(tester);
            });
            EditableText.debugDeterministicCursor = true;
            _testersLightTheme[tester] = lightTheme;
            if (nonDefaultPlayerInterfaceColorStyle) {
              _testersPlayerInterfaceColorStyle[tester] = playerInterfaceColorStyle;
            }
            registerPostAppSetup((_) {
              ThemeControl.instance.setThemeLightMode(lightTheme);
              Settings.playerInterfaceColorStyle.set(playerInterfaceColorStyle);
            });
            setUp?.call();
            return await tester.runAppTest(
              () => test(tester),
              goldenCaptureCallback: () {
                final group = Invoker.current!.liveTest.test.name.split(testDescription)[0].trim().replaceAll(' ', '.');
                return tester._screenMatchesGolden(
                  "$group.${description.replaceAll(' ', '.')}",
                  customPump: customGoldenPump,
                );
              },
            );
          } finally {
            debugDisableShadows = previousDebugDisableShadowsValue;
          }
        },
        tags: tags != _defaultTagObject ? tags : const ['golden'],
      );
    }
  }
}

/// Signature used in [runGoldenAppTest].
typedef GoldenCaptureCallback = Future<void> Function(bool lightTheme);

// Load the custom fonts from the assets.
// From https://pub.dev/documentation/golden_toolkit/latest/golden_toolkit/loadAppFonts.html
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final String robotoPath = path.joinAll(<String>[
    Platform.environment['FLUTTER_ROOT']!,
    'bin',
    'cache',
    'artifacts',
    'material_fonts',
    'Roboto-Regular.ttf',
  ]);
  final roboto = File(robotoPath).readAsBytes().then(ByteData.sublistView);
  final FontLoader fontLoader = FontLoader('Roboto')..addFont(roboto);
  await fontLoader.load();

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
