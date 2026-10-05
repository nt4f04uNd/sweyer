import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:sweyer/logic/models/song.dart';
import 'package:sweyer/logic/player/just_audio_player.dart';
import 'package:sweyer/logic/player/sweyer_player.dart';

import '../../fakes/fake_just_audio.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late JustAudioPlayer player;

  setUp(() {
    JustAudioPlatform.instance = MockJustAudio(binding);
    player = JustAudioPlayer();
  });

  tearDown(() => player.dispose());

  test('setSong returns success when the song is loaded', () async {
    expect(await player.setSong(_songWithUri('https://example.com/song')), isA<SetSongSuccess>());
  });

  test('setSong returns interrupted when loading is aborted', () async {
    expect(await player.setSong(_songWithUri('https://example.com/abort')), isA<SetSongInterrupted>());
  });

  test('setSong returns unavailable when just_audio rejects the song', () async {
    expect(await player.setSong(_songWithUri('https://example.com/404')), isA<SetSongUnavailable>());
  });

  test('play returns success when playback starts', () async {
    await player.setSong(_songWithUri('https://example.com/song'));

    final playFuture = player.play();
    await binding.pump();
    await player.pause();

    expect(await playFuture, isA<PlaySuccess>());
  });
}

Song _songWithUri(String uri) => _SongWithUri(uri);

class _SongWithUri extends Song {
  _SongWithUri(this._uri)
    : super(
        id: 1,
        album: null,
        albumId: null,
        artist: 'Artist',
        artistId: 1,
        genre: null,
        genreId: null,
        title: 'Song',
        track: null,
        dateAdded: 0,
        dateModified: 0,
        duration: 120000,
        size: null,
        filesystemPath: null,
        isFavoriteInMediaStore: false,
      );

  final String _uri;

  @override
  String get contentUri => _uri;
}
