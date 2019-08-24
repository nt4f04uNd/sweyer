import 'package:flute_music_player/flute_music_player.dart';

enum PlayerStateType { stopped, playing, paused }

class MusicPlayer {
  /// `[MusicFinder]` player instance
  final _playerInstance = MusicFinder();

  /// Paths of found tracks in `_findSongs` method
  List<Song> _songs = <Song>[];

  /// Current player state
  PlayerStateType playerState = PlayerStateType.stopped;

  /// Current index of playing track in `_songs`
  ///
  /// TODO: `_songs` list can be resorted so I should to write method that updates this variable on resort
  int playingIndexState = 0;

  // Getters
  /// Get current playing song
  Song get currentSong => _songs[playingIndexState];
  /// Get songs count
  int get songsCount => _songs.length;

  /// Current track duration
  Duration _durationState;

  /// Current track seek position
  Duration _positionState;

  /// Callback of `_setState` funtion from `PlayerState`
  Function _setState;

  MusicPlayer(this._setState) {
    _findSongs();

    // Set handler for duration
    _playerInstance
        .setDurationHandler((d) => _setState(() => _durationState = d));
    // Set handler for position
    _playerInstance
        .setPositionHandler((p) => _setState(() => _positionState = p));
  }

  /// Play track
  ///
  /// `clickedListIndex` argument denotes an index of clicked rows in track `ListView`
  ///
  /// returns the result of operation:
  /// * 1 if success
  /// * 0 if failed
  Future<int> play(int clickedListIndex) async {
    final int result = await _playerInstance.play(_songs[clickedListIndex].uri);
    // Change state if result is successful
    if (result == 1)
      _setState(() {
        playerState = PlayerStateType.playing;
        playingIndexState = clickedListIndex;
      });
    return result;
  }

  /// Pause player
  ///
  /// returns the result of operation:
  /// * 1 if success
  /// * 0 if failed
  Future<int> pause() async {
    final int result = await _playerInstance.pause();
    // Change state if result is successful
    if (result == 1) _setState(() => playerState = PlayerStateType.paused);
    return result;
  }

  /// Stop player
  ///
  /// returns the result of operation:
  /// * 1 if success
  /// * 0 if failed
  Future<int> stop() async {
    final int result = await _playerInstance.stop();
    // Change state if result is successful
    if (result == 1)
      _setState(() {
        playerState = PlayerStateType.paused;
        playingIndexState = null;
      });
    return result;
  }

  /// Returns song object by index
  Song getSong(int index) {
    return _songs[index];
  }

  /// Finds songs on user device and calls `[setState]` method
  void _findSongs() async {
    var songs = await MusicFinder.allSongs();
    _setState(() => _songs = songs);
  }
}
