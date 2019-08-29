import 'dart:async';
import 'dart:convert';
// import 'package:flute_music_player/flute_music_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'package:permission_handler/permission_handler.dart';

class Song {
  final int id;
  final String artist;
  final String album;
  final String albumArtUri;
  final String title;
  final String trackUri;
  final int duration;

  Song(
      {@required this.id,
      @required this.artist,
      @required this.album,
      @required this.albumArtUri,
      @required this.title,
      @required this.trackUri,
      @required this.duration});

  Song.fromMap(Map m)
      : id = m["id"],
        artist = m["artist"],
        album = m["album"],
        albumArtUri = m["albumArtUri"],
        title = m["title"],
        trackUri = m["trackUri"],
        duration = m["duration"];
}

/// Type for audio manager focus
enum AudioFocusType { focus, no_focus, focus_delayed }

/// Type for play process state
enum PlayStateType { stopped, playing, paused }

/// Function for call player functions from AudioPlayers package until they will be completed, or until recursive callstack will exceed 10
///
/// First argument is callback to complete
///
/// Seconds argument is initial callStackSize and optional
Future<int> _recursiveCallback(Future<int> callback(),
    [int callStackSize = 0]) async {
  int res = await callback();
  if (res != 1 && callStackSize < 10) // If result isn't successful try again
    return await _recursiveCallback(callback, callStackSize++);
  else if (res == 1) // If  result is successful return 1
    return 1;
  else // If result isn't successful and callstack exceeded return 0
    throw Exception(
        "_recursiveCallback failed and didn't manage to get success before callstack exceeded 10");
}

class MusicPlayer {
  static MusicPlayer getInstance;

  /// Channel for handling audio focus
  static const _methodChannel = const MethodChannel('methodChannelStream');

  /// `[MusicFinder]` player instance
  final _playerInstance = AudioPlayer();

  /// Paths of found tracks in `_findSongs` method
  List<Song> _songs = [];

  /// Audio manager focus state
  AudioFocusType focusState = AudioFocusType.no_focus;

  /// Current index of playing track in `_songs`
  ///
  /// TODO: `_songs` list can be resorted so I should to write method that updates this variable on resort
  int playingIndexState = 0;

  // Getters
  /// Get current playing song
  Song get currentSong {
    _songsCheck();
    return _songs[playingIndexState];
  }

  /// Get songs count
  int get songsCount {
    _songsCheck();
    return _songs.length;
  }

  /// Whether songs list instantiated or not (in the future will implement cashing so, but for now this depends on `_findSongs`)
  bool get songsReady => _songs.length > 0;

  /// Get stream of changes on audio position.
  Stream<Duration> get onAudioPositionChanged =>
      _playerInstance.onAudioPositionChanged;

  /// Get stream of changes on player state.
  Stream<AudioPlayerState> get onPlayerStateChanged =>
      _playerInstance.onPlayerStateChanged;

  AudioPlayerState get playState => _playerInstance.state;

  /// Get current position
  Future<int> get currentPosition async {
    try {
      return _playerInstance.getCurrentPosition();
    } catch (e) {}
  }

  MusicPlayer() {
    getInstance = this;

    // Change player mode for sure
    _playerInstance.mode = PlayerMode.MEDIA_PLAYER;

    _findSongs();

    // TODO: see how to improve focus and gaindelayed usage
    // Set listener for method calls for changing focus
    _methodChannel.setMethodCallHandler((MethodCall call) async {
      debugPrint('${call.method}, ${call.arguments.toString()}');
      if (call.method == 'focus_change') {
        switch (call.arguments) {
          case 'AUDIOFOCUS_GAIN':
            int res = await _recursiveCallback(_playerInstance.resume);
            if (res == 1) focusState = AudioFocusType.focus;
            break;
          case 'AUDIOFOCUS_LOSS':
            int res = await _recursiveCallback(_playerInstance.pause);
            if (res == 1) focusState = AudioFocusType.no_focus;
            break;
          case 'AUDIOFOCUS_LOSS_TRANSIENT':
            int res = await _recursiveCallback(_playerInstance.pause);
            if (res == 1) focusState = AudioFocusType.focus_delayed;
            break;
          case 'AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK':
            int res = await _recursiveCallback(_playerInstance.pause);
            if (res == 1) focusState = AudioFocusType.focus_delayed;
            // TODO: implement volume change
            break;
          default:
            throw Exception('Incorrect method argument came from native code');
        }
      }
    });
  }

// TODO: add implementation for this function and change method name to `get_intent_action_view`
  Future<void> _isIntentActionView() async {
    debugPrint(
        (await _methodChannel.invokeMethod('intent_action_view')).toString());
  }

  /// Request audio manager focus
  Future<void> _requestFocus() async {
    if (focusState == AudioFocusType.no_focus) {
      switch (await _methodChannel.invokeMethod<String>('request_focus')) {
        case "AUDIOFOCUS_REQUEST_FAILED":
          focusState = AudioFocusType.no_focus;
          break;
        case "AUDIOFOCUS_REQUEST_GRANTED":
          focusState = AudioFocusType.focus;
          break;
        case "AUDIOFOCUS_REQUEST_DELAYED":
          focusState = AudioFocusType.focus_delayed;
          break;
      }
    }
  }

  /// Abandon audio manager focus
  Future<void> _abandonFocus() async {
    await _methodChannel.invokeMethod('abandon_focus');
    focusState = AudioFocusType.no_focus;
  }

  //TODO: add usage for set url method
  /// Play track
  ///
  /// `clickedListIndex` argument denotes an index of clicked row in track `ListView`
  Future<void> play(int clickedListIndex) async {
    await _requestFocus();

    int res;
    if (focusState == AudioFocusType.focus)
      res = await _playerInstance.play(getSong(clickedListIndex).trackUri);
    else if (focusState == AudioFocusType.focus_delayed)
      // Set url if no focus has been granted
      res = await _playerInstance.setUrl(getSong(clickedListIndex).trackUri);
    // Do nothing if no focus has been granted

    if (res == 1) playingIndexState = clickedListIndex;
  }

  /// Resume player
  Future<void> resume() async {
    await _requestFocus();

    if (focusState == AudioFocusType.focus) await _playerInstance.resume();
    // Else if gainFocus is being handled in `setMethodCallHandler` listener above.
    //When delay is over android triggers AUDIOFOCUS_GAIN and track starts to play

    // Do nothing if no focus has been granted
  }

  /// Pause player
  Future<void> pause() async {
    final int result = await _playerInstance.pause();
    await _abandonFocus();
  }

  /// Stop player
  Future<void> stop() async {
    final int result = await _playerInstance.stop();
    // Change state if result is successful
    await _abandonFocus();
  }

  /// Seek
  Future<void> seek(int seconds) async {
    await _playerInstance.seek(Duration(seconds: seconds));
  }

  /// Function that handles click on track tile
  Future<void> clickTrackTile(int clickedListIndex) async {
    switch (playState) {
      case AudioPlayerState.PLAYING:
        // If user clicked the same track
        if (playingIndexState == clickedListIndex)
          await pause();
        // If user decided to click a new track
        else
          await play(clickedListIndex);
        break;
      case AudioPlayerState.PAUSED:
        // If user clicked the same track
        if (playingIndexState == clickedListIndex)
          await resume();
        // If user decided to click a new track
        else
          await play(clickedListIndex);
        break;
      case AudioPlayerState.STOPPED:
        await play(clickedListIndex);
        break;
      case AudioPlayerState.COMPLETED:
        await play(clickedListIndex);
        break;
      default:
        throw Exception('Invalid player state variant');
        break;
    }
  }

  /// Returns song object by index
  Song getSong(int index) {
    _songsCheck();
    return _songs[index];
  }

  /// Finds songs on user device
  void _findSongs() async {
    // _songs.removeWhere(
    //     // Remove all elements whose duration is shorter than 30 seconds
    //     (item) => item.duration < Duration(seconds: 30).inMilliseconds);
    // Emit event

    // TODO: add button to re-request permissions
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);

    Map<PermissionGroup, PermissionStatus> permissions;
    if (permission == PermissionStatus.denied)
      permissions = await PermissionHandler()
          .requestPermissions([PermissionGroup.storage]);
          
          
    var songsJson =
        await _methodChannel.invokeListMethod<String>("retrieve_songs");
    for (String songJson in songsJson) {
      _songs.add(Song.fromMap(jsonDecode(songJson)));
    }
    await _playerInstance.setUrl(currentSong.trackUri);
    await _playerInstance.pause();
  }

  /// Method that asserts that `_songs` is not `null`
  void _songsCheck() {
    assert(songsReady,
        '_songs is null, probably because it is not initilized by _findSongs');
  }
}
