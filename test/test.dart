import 'dart:typed_data';
import 'dart:ui';

export 'package:sweyer/sweyer.dart';
export 'package:flutter/foundation.dart';
export 'package:flutter_test/flutter_test.dart';
import 'package:android_content_provider/android_content_provider.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:package_info_plus_platform_interface/package_info_platform_interface.dart';
import 'package:package_info_plus_platform_interface/method_channel_package_info.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flare_flutter/flare_testing.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:sweyer/constants.dart' as Constants;

export 'fakes/fakes.dart';

import 'observer/observer.dart';
import 'test.dart';

final _testSong = Song(
  id: 0,
  album: 'album',
  albumId: 0,
  artist: 'artist',
  artistId: 0,
  genre: 'genre',
  genreId: 0,
  title: 'title',
  track: 'track',
  dateAdded: 0,
  dateModified: 0,
  duration: 0,
  size: 0,
  data: 'data_data_data_data_data_data_data_data',
  isFavoriteInMediaStore: false,
  generationAdded: 0,
  generationModified: 0,
  origin: _testAlbum,
  duplicationIndex: 0,
);

const _testAlbum = Album(
  id: 0,
  album: 'album',
  albumArt: 'albumArt_albumArt_albumArt',
  artist: 'artist',
  artistId: 0,
  firstYear: 2000,
  lastYear: 2000,
  numberOfSongs: 1000,
);

final _testPlaylist = Playlist(
  id: 0,
  data: 'data_data_data_data_data_data_data_data',
  dateAdded: 0,
  dateModified: 0,
  name: 'name',
  songIds: [_testSong.id],
);

const _testArtist = Artist(
  id: 0,
  artist: 'artist',
  numberOfAlbums: 1, 
  numberOfTracks: 1, 
);

final SongCopyWith songWith = _testSong.copyWith;
final AlbumCopyWith albumWith = _testAlbum.copyWith;
final PlaylistCopyWith playlistWith = _testPlaylist.copyWith;
final ArtistCopyWith artistWith = _testArtist.copyWith;

/// Default l10n delegate in tests.
final l10n = AppLocalizationsEn();
const kScreenHeight = 800.0;
const kScreenWidth = 450.0;
const kScreenPixelRatio = 3.0;
const kScreenSize = Size(kScreenWidth, kScreenHeight);

/// Sets the fake data providers and initializes the app state.
/// 
/// The [configureFakes] callback can be used to modify the fake data providers
/// before the controls will load it.
Future<void> setUpAppTest([VoidCallback? configureFakes]) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;
  binding.window.physicalSizeTestValue = kScreenSize * kScreenPixelRatio;
  binding.window.devicePixelRatioTestValue = kScreenPixelRatio;
  // Prepare flare.
  FlareTesting.setup();

  // Fake prefs values.
  //
  // Set empty values, because Windows implements shared_preferences
  // without plugin code, thus works in tests, which is undesirable,
  // because it changes test results
  // https://github.com/flutter/flutter/issues/95951#issuecomment-1002972723
  NFPrefs.prefs = null;
  await NFPrefs.prefs?.clear();
  SharedPreferences.setMockInitialValues({});

  // Reset any state
  DeviceInfoControl.instance.dispose();
  ContentControl.instance.dispose();
  AppRouter.instance = AppRouter();

  // Set up fakes
  SystemUiStyleController.instance = FakeSystemUiStyleController();
  Backend.instance = FakeBackend();
  DeviceInfoControl.instance = FakeDeviceInfoControl();
  FavoritesControl.instance = FakeFavoritesControl();
  PermissionsChannelObserver(binding); // Grant all permissions by default.
  ContentChannel.instance = FakeContentChannel(binding);
  QueueControl.instance = FakeQueueControl();
  ThemeControl.instance = FakeThemeControl();
  JustAudioPlatform.instance = MockJustAudio();
  PackageInfoPlatform.instance = MethodChannelPackageInfo();
  binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/package_info'), (MethodCall methodCall) async {
    return {
      'appName': Constants.Config.APPLICATION_TITLE,
      'packageName': 'com.nt4f04und.sweyer',
      'version': '1.0.0',
      'buildNumber': '0',
    };
  });
  binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('com.ryanheise.audio_service.client.methods'), (MethodCall methodCall) async {
    return {};
  });
  binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('com.ryanheise.audio_service.handler.methods'), (MethodCall methodCall) async {
    return {};
  });
  binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('com.ryanheise.audio_session'), (MethodCall methodCall) async {
    return null;
  });
  binding.defaultBinaryMessenger.setMockMethodCallHandler(AndroidContentResolver.methodChannel, (MethodCall methodCall) async {
    return null;
  });
  LicenseRegistry.reset();
  LicenseRegistry.addLicense(() => Stream.value(const FakeLicenseEntry()));

  configureFakes?.call();

  // Set up regular classes
  PlaybackControl.instance = PlaybackControl();
  ContentControl.instance = ContentControl();

  // Default initialization process from main.dart
  await NFPrefs.initialize();
  await SearchHistory.instance.clear();

  await DeviceInfoControl.instance.init();
  ThemeControl.instance.init();
  ThemeControl.instance.initSystemUi();
  await Permissions.instance.init();
  await ContentControl.instance.init();

  // Called in the [App] widget
  NFWidgets.init(
    navigatorKey: AppRouter.instance.navigatorKey,
    routeObservers: [routeObserver, homeRouteObserver],
  );
}

extension WidgetTesterExtension on WidgetTester {
  /// A template for this:
  ///  1. pumps the app
  ///  2. runs the test from the [callback]
  ///  3. stops and disposes the player
  ///  4. optionally, runs [goldenCaptureCallback]. It would time out if was ran before player is disposed in [callback].
  ///  5. unpumps the screen
  Future<void> runAppTest(AsyncCallback callback, {AsyncCallback? goldenCaptureCallback}) async {
    await withClock(binding.clock, () async {
      // App only supports vertical orientation, so switch tests to use it.
      await binding.setSurfaceSize(kScreenSize);
      await pumpWidget(const App(debugShowCheckedModeBanner: false));
      await pump();
      await callback();
      await runAsync(() async {
        // Don't leak player state between tests.
        // Delay needed for proper disposal in some tests.
        await Future.delayed(const Duration(milliseconds: 1));
        await MusicPlayer.instance.stop();
        await MusicPlayer.instance.dispose();
      });
      await goldenCaptureCallback?.call();
      // Unpump, in case we have any real animations running,
      // so the pumpAndSettle on the next line doesn't hang on.
      await pumpWidget(const SizedBox());
      // Wait for ui animations.
      await pumpAndSettle();
    });
  }

  /// Whether the current tester is running in [testAppGoldens] and
  /// in light mode.
  bool get lightThemeGolden => _testersLightTheme.contains(this);

  Future<void> screenMatchesGolden(
    WidgetTester tester,
    String name, {
    bool? autoHeight,
    Finder? finder,
    CustomPump? customPump,
  }) {
    name = '$name.${_getThemeMessage(tester.lightThemeGolden)}';
    return _screenMatchesGoldenWithTolerance(
      this,
      name,
      autoHeight: autoHeight,
      finder: finder,
      customPump: customPump,
    );
  }

  /// Expect the app to render a list of songs in [SongTile]s.
  void expectSongTiles(Iterable<Song> songs) {
    final songTiles = widgetList<SongTile>(find.byType(SongTile));
    final foundSongs = songTiles.map((e) => e.song);
    expect(foundSongs, songs);
  }
}

final _testersLightTheme = <WidgetTester>{};
String _getThemeMessage(bool lightTheme) => lightTheme  ? 'light' : 'dark';
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
}) {
  for (final lightTheme in [false, true]) {
    testGoldens(
      '$description ${_getThemeMessage(lightTheme)}',
      (tester) async {
        try {
          ThemeControl.instance.setThemeLightMode(lightTheme);
          if (lightTheme) {
            _testersLightTheme.add(tester);
          }
          return await test(tester);
        } finally {
          _testersLightTheme.remove(tester);
        }
      },
      tags: tags != _defaultTagObject ? tags : GoldenToolkit.configuration.tags,
    );
  }
}

/// Signature used in [runGoldenAppTest].
typedef GoldenCaptureCallback = Future<void> Function(bool lightTheme);

Future<void> _screenMatchesGoldenWithTolerance(
  WidgetTester tester,
  String name, {
  bool? autoHeight,
  Finder? finder,
  CustomPump? customPump,
}) {
  goldenFileComparator = _TolerableFileComparator(path.join(
    (goldenFileComparator as LocalFileComparator).basedir.toString(),
    name,
  ));
  return screenMatchesGolden(
    tester,
    name,
    autoHeight: autoHeight,
    finder: finder,
    customPump: customPump,
  );
}

class _TolerableFileComparator extends LocalFileComparator {
  _TolerableFileComparator(String testFile) : super(Uri.parse(testFile));

  static const double _kGoldenDiffTolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent > _kGoldenDiffTolerance) {
      final String error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    if (!result.passed) {
      print('A tolerable difference of ${result.diffPercent * 100}% was found when '
          'comparing $golden.');
    }
    return result.passed || result.diffPercent <= _kGoldenDiffTolerance;
  }
}

class FakeLicenseEntry extends LicenseEntry {
  const FakeLicenseEntry();

  @override
  Iterable<String> get packages => const ['test_package'];

  @override
  Iterable<LicenseParagraph> get paragraphs => const [
    LicenseParagraph('test paragraph 1', 0),
    LicenseParagraph('test paragraph 2', 0),
    LicenseParagraph('test paragraph 3', 0),
    LicenseParagraph('test paragraph 4', 0),
    LicenseParagraph('test paragraph 5', 0),
  ];
}

class FakeSystemUiStyleController implements SystemUiStyleController {
  @override
  Curve curve = Curves.linear;

  @override
  Duration duration = Duration.zero;

  @override
  SystemUiOverlayStyle get actualUi => const SystemUiOverlayStyle();

  @override
  Future<void> animateSystemUiOverlay({SystemUiOverlayStyle? from, required SystemUiOverlayStyle to, Curve? curve, Duration? duration}) async {}

  @override
  SystemUiOverlayStyle get lastUi => const SystemUiOverlayStyle();

  @override
  Stream<SystemUiOverlayStyle> get onUiChange => const Stream.empty();

  @override
  void setSystemUiOverlay(SystemUiOverlayStyle ui) {}
}
