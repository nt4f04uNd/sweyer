export 'package:flutter/foundation.dart';
export 'package:flutter_test/flutter_test.dart';
export 'package:sweyer/sweyer.dart';

export 'fakes/fakes.dart';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flare_flutter/flare_testing.dart';

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
  isFavorite: false,
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
const kScreenSize = Size(kScreenWidth, kScreenHeight);
const kScreenHeight = 800.0;
const kScreenWidth = 600.0;

/// Sets the fake data providers and initializes the app state.
/// 
/// The [configureFakes] callback can be used to modify the fake data providers
/// before the controls will load it.
Future<void> setUpAppTest([VoidCallback? configureFakes]) async {
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

  // Set up fakes
  Backend.instance = FakeBackend();
  DeviceInfoControl.instance = FakeDeviceInfoControl();
  Permissions.instance = FakePermissions();
  ContentChannel.instance = FakeContentChannel();
  QueueControl.instance = FakeQueueControl();
  JustAudioPlatform.instance = MockJustAudio();
  const MethodChannel('com.ryanheise.audio_service.client.methods').setMockMethodCallHandler((MethodCall methodCall) async {
    return {};
  });
  const MethodChannel('com.ryanheise.audio_service.handler.methods').setMockMethodCallHandler((MethodCall methodCall) async {
    return {};
  });
  const MethodChannel('com.ryanheise.audio_session').setMockMethodCallHandler((MethodCall methodCall) async {
    return null;
  });

  configureFakes?.call();

  // Set up regular classes
  PlaybackControl.instance = PlaybackControl();
  ContentControl.instance = ContentControl();

  // Default initialization process from main.dart
  await NFPrefs.initialize();
  await DeviceInfoControl.instance.init();
  ThemeControl.init();

  // TODO: UI animations break tests
  // ThemeControl.initSystemUi();
  SystemUiStyleController.setSystemUiOverlay(const SystemUiOverlayStyle());

  await Permissions.instance.init();
  await ContentControl.instance.init();

  // Called in the [App] widget
  NFWidgets.init(
    navigatorKey: AppRouter.instance.navigatorKey,
    routeObservers: [routeObserver, homeRouteObserver],
  );
}

extension WidgetTesterExtension on WidgetTester {
  Future<void> runAppTest(AsyncCallback callback) async {
    // App only suppots vertical orientation, so switch tests to use it.
    await binding.setSurfaceSize(kScreenSize);
    await pumpWidget(
      Center(
        child: MediaQuery(
          data: MediaQueryData.fromWindow(window).copyWith(size: kScreenSize),
          child: const App(),
        ),
      ),
    );
    await pump();
    await callback();
    // Unpump, in case we have any real animations running,
    // so the pumpAndSettle on the next line doesn't hang on.
    await pumpWidget(const SizedBox());
    // Wait for ui animations.
    await pumpAndSettle();
    // Don't leak player state throughout tests.
    await MusicPlayer.instance.stop();
  }

  /// Expect the app to render a list of songs in [SongTile]s.
  void expectSongTiles(Iterable<Song> songs) {
    final songTiles = widgetList<SongTile>(find.byType(SongTile));
    final foundSongs = songTiles.map((e) => e.song);
    expect(foundSongs, songs);
  }
}
