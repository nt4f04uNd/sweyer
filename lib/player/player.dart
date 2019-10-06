import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:app/constants/constants.dart' as Constants;
import 'package:app/player/playlist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// VIEW https://medium.com/@wangdazhitech/flutter-read-asset-file-and-write-to-app-path-42115d4ec1b6
import 'package:flutter/services.dart' show rootBundle;

/// Type for audio manager focus
enum AudioFocusType { focus, no_focus, focus_delayed }

/// Function for call player functions from AudioPlayers package until they will be completed, or until recursive callstack will exceed 10
///
/// First argument is callback to complete
///
/// Seconds argument is initial callStackSize and optional
///
/// TODO: test this method
///
/// #REMOVE(PROBABLY)
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

// FIXME: conduct a massive refactor of methods and properties
class MusicPlayer {
  static MusicPlayer instance;

  /// Image bytes to display in notification
  Uint8List _placeholderImgBytes;

  /// Channel for handling audio focus
  MethodChannel _methodChannel =
      const MethodChannel(Constants.MethodChannel.channelName);

  /// Event channel for receiving native android events
  EventChannel _eventChannel =
      const EventChannel(Constants.EventChannel.channelName);

  /// `[AudioPlayer]` player instance
  final nativePlayerInstance = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);

  PlaylistControl playlistControl = PlaylistControl();

  /// A subscription to song change
  StreamSubscription<void> _songChangeListenerSubscription;

  /// Subscription for events stream
  StreamSubscription _eventSubscription;

  /// Subscription for changes in state
  StreamSubscription<AudioPlayerState> _stateChangeSubscription;

  /// Subscription for completion changes
  StreamSubscription<void> _completionSubscription;

  /// Audio manager focus state
  AudioFocusType focusState = AudioFocusType.no_focus;

  /// Is notification visible
  bool notificationState = false;

  /// Is notification visible
  bool loopModeState = false;

  /// Hook handle
  /// Variable to save latest hook press time
  DateTime _latestHookPressTime;

  /// How much times hook has been pressed during handle multiple presses time (e.g. 700ms)
  int _hookPressStack = 0;

  /// Is player tries to switch right now
  /// TODO: improve implementation of this
  bool switching = false;

  // Getters

  /// Get stream of changes on audio position.
  Stream<Duration> get onAudioPositionChanged =>
      nativePlayerInstance.onAudioPositionChanged;

  /// Get stream of changes on player state.
  Stream<AudioPlayerState> get onPlayerStateChanged =>
      nativePlayerInstance.onPlayerStateChanged;

  /// Get stream of changes on audio duration
  Stream<Duration> get onDurationChanged =>
      nativePlayerInstance.onDurationChanged;

  /// Get stream of player completions
  Stream<void> get onPlayerCompletion =>
      nativePlayerInstance.onPlayerCompletion;

  /// Get stream of player errors
  Stream<String> get onPlayerError => nativePlayerInstance.onPlayerError;

  /// Get stream of notifier events about changes on track list
  Stream<void> get onPlaylistListChange => playlistControl.onPlaylistListChange;

  /// Get stream of notifier events about changes on current song
  Stream<void> get onSongChange => playlistControl.onSongChange;

  AudioPlayerState get playState => nativePlayerInstance.state;

  /// Get current position
  ///
  /// TODO: report this bu
  Future<Duration> get currentPosition async {
    try {
      return Duration(
          milliseconds: await nativePlayerInstance.getCurrentPosition());
    } catch (e) {
      debugPrint('nativePlayerInstance getCurrentPosition error! - error: $e');
      return Duration(seconds: 0);
    }
  }

  MusicPlayer() {
    instance = this;

    nativePlayerInstance.setReleaseMode(ReleaseMode.STOP);

    _songChangeListenerSubscription = onSongChange.listen((event) {
      switching = false;
    });

    _completionSubscription = onPlayerCompletion.listen((event) {
      // Play next track if not in loop mode
      if (!loopModeState) clickNext();
      playlistControl.emitSongChange();
    });

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      switch (event) {
        case Constants
            .EventChannel.eventBecomeNoisy: // handle headphones disconnect
          pause();
          break;
        case Constants.EventChannel.eventPlay:
          clickPausePlay();
          break;
        case Constants.EventChannel.eventPause:
          clickPausePlay();
          break;
        case Constants.EventChannel.eventNext:
          clickNext();
          break;
        case Constants.EventChannel.eventPrev:
          clickPrev();
          break;
        default:
          throw Exception('Invalid event');
      }
    });

    _stateChangeSubscription = onPlayerStateChanged.listen((event) async {
      if (!playlistControl.songsEmpty(PlaylistType.global)) {
        // TODO: improve this code + add comments
        var prefs = await SharedPreferences.getInstance();
        prefs.setInt(
            Constants.PrefKeys.songIdInt, playlistControl.currentSong.id);
      }

      switch (event) {
        case AudioPlayerState.PLAYING:
          _showNotification(
              artist: artistString(playlistControl.currentSong.artist),
              title: playlistControl.currentSong.title,
              albumArtUri: playlistControl.currentSong.albumArtUri,
              isPlaying: true);
          notificationState = true;
          break;
        case AudioPlayerState.PAUSED:
          if (notificationState)
            _showNotification(
                artist: artistString(playlistControl.currentSong.artist),
                title: playlistControl.currentSong.title,
                albumArtUri: playlistControl.currentSong.albumArtUri,
                isPlaying: false);
          break;
        case AudioPlayerState.STOPPED:
          _closeNotification();
          notificationState = false;
          break;
        case AudioPlayerState.COMPLETED:
          break;
        default:
          break;
      }
    });

    // TODO: see how to improve focus and implement gain delayed usage
    // Set listener for method calls for changing focus
    _methodChannel.setMethodCallHandler((MethodCall call) async {
      // debugPrint('${call.method}, ${call.arguments.toString()}');

      if (call.method == Constants.MethodChannel.methodFocusChange) {
        switch (call.arguments) {
          // TODO: rewrite instead of these methods my class methods (resume, pause, etc.)
          case Constants.MethodChannel.argFocusGain:
            int res = await _recursiveCallback(nativePlayerInstance.resume);
            if (res == 1) focusState = AudioFocusType.focus;
            break;
          case Constants.MethodChannel.argFocusLoss:
            int res = await _recursiveCallback(nativePlayerInstance.pause);
            if (res == 1) focusState = AudioFocusType.no_focus;
            break;
          case Constants.MethodChannel.argFocusLossTrans:
            int res = await _recursiveCallback(nativePlayerInstance.pause);
            if (res == 1) focusState = AudioFocusType.focus_delayed;
            break;
          case Constants.MethodChannel.argFocusLossTransCanDuck:
            int res = await _recursiveCallback(nativePlayerInstance.pause);
            if (res == 1) focusState = AudioFocusType.focus_delayed;
            // TODO: implement volume change
            break;
          default:
            throw Exception('Incorrect method argument came from native code');
        }
      } else if (call.method == Constants.MethodChannel.methodHookButtonClick) {
        // Avoid errors when app is loading
        if (playlistControl.playReady) {
          DateTime now = DateTime.now();
          if (_latestHookPressTime == null ||
              now.difference(_latestHookPressTime) >
                  // TODO: extract delays to constant
                  // TODO: add async task instead of 200 safe delay
                  // `_handleHookDelayedPress` delay + sfe delay (trying to fix hook button press bug)
                  Duration(milliseconds: 600 + 50)) {
            // If hook is pressed first time or last press were more than 0.5s ago
            _latestHookPressTime = now;
            _hookPressStack = 1;
            _handleHookDelayedPress();
          } else if (_hookPressStack == 1 || _hookPressStack == 2) {
            // This condition ensures that nothing more than 3 will not be assigned to _hookPressStack
            _hookPressStack++;
          }
        }
      }
    });

    _init();
  }

  /// Play/pause, next or prev function depending on `_hookPressStack`
  void _handleHookDelayedPress() async {
    // Wait 0.6s
    await Future.delayed(Duration(milliseconds: 600));
    switch (_hookPressStack) {
      case 1:
        await clickPausePlay();
        break;
      case 2:
        await clickNext();
        break;
      case 3:
        await clickPrev();
        break;
    }
    _hookPressStack = 0;
  }

  // TODO: add implementation for this function and change method name to `get_intent_action_view`
  // #SEPARATE
  Future<void> _isIntentActionView() async {
    debugPrint((await _methodChannel
            .invokeMethod(Constants.MethodChannel.methodIntentActionView))
        .toString());
  }

  /// Request audio manager focus
  Future<void> _requestFocus() async {
    if (focusState == AudioFocusType.no_focus) {
      switch (await _methodChannel
          .invokeMethod<String>(Constants.MethodChannel.methodRequestFocus)) {
        case Constants.MethodChannel.returnRequestFail:
          focusState = AudioFocusType.no_focus;
          break;
        case Constants.MethodChannel.returnRequestGrant:
          focusState = AudioFocusType.focus;
          break;
        case Constants.MethodChannel.returnRequestDelay:
          focusState = AudioFocusType.focus_delayed;
          break;
      }
    }
  }

  /// Abandon audio manager focus
  Future<void> _abandonFocus() async {
    await _methodChannel
        .invokeMethod(Constants.MethodChannel.methodAbandonFocus);
    focusState = AudioFocusType.no_focus;
  }

// TODO: move notification methods to separate class maybe
  /// Method to show/update notification
  void _showNotification(
      {@required String title,
      @required String artist,
      @required String albumArtUri,
      @required bool isPlaying}) async {
    Uint8List albumArtBytes;

    if (albumArtUri ==
        null) // Set placeholder as an image if album art is absent
      albumArtBytes = _placeholderImgBytes;
    else {
      try {
        albumArtBytes = await File(albumArtUri).readAsBytes() as Uint8List;
      } catch (e) {
        albumArtBytes = _placeholderImgBytes;
        debugPrint('Album art read error in _showNotification');
      }
    }

    await _methodChannel
        .invokeMethod(Constants.MethodChannel.methodShowNotification, {
      "title": title,
      "artist": artist,
      "albumArtBytes": albumArtBytes,
      "isPlaying": isPlaying
    });
  }

  /// Method to hide notification
  Future<void> _closeNotification() async {
    await _methodChannel
        .invokeMethod(Constants.MethodChannel.methodCloseNotification);
  }

  void switchLoopMode() async {
    var prefs = await SharedPreferences.getInstance();
    if (loopModeState) {
      nativePlayerInstance.setReleaseMode(ReleaseMode.STOP);
      prefs.setBool(Constants.PrefKeys.loopModeBool, false);
    } else {
      nativePlayerInstance.setReleaseMode(ReleaseMode.LOOP);
      prefs.setBool(Constants.PrefKeys.loopModeBool, true);
    }
    loopModeState = !loopModeState;
  }

  //TODO: add usage for set url method
  /// Play track
  ///
  /// `songId` argument denotes an id track to play
  Future<void> play(int songId) async {
    switching = true;
    await _requestFocus();
    // NOTE that this is defaults to 1 and if needed you have to set it manually to 0
    int res = 1;
    try {
      final uri = playlistControl.getSongById(songId).trackUri;
      if (focusState == AudioFocusType.focus)
        res = await nativePlayerInstance.play(uri,
            stayAwake:
                true // This is very important for player to stay play even in background
            );
      else if (focusState == AudioFocusType.focus_delayed)
        // Set url if no focus has been granted
        res = await nativePlayerInstance.setUrl(uri);
    } on PlatformException catch (e) {
      /// `Unsupported value: java.lang.IllegalStateException` message thrown when `play` gets called in wrong state
      /// `Unsupported value: java.lang.RuntimeException: Unable to access resource` message thrown when resource can't be played
      debugPrint(
          'Error thrown in my player class play method - {code: ${e.code} --- details: ${e.details} --- message:${e.message}}');

      if (e.code == "error") {
        if (e.message ==
            "Unsupported value: java.lang.RuntimeException: Unable to access resource") {
          Fluttertoast.showToast(
              msg: 'Произошла ошибка при воспроизведении,\n удаление трека',
              backgroundColor: Color.fromRGBO(18, 18, 18, 1));

          // NOTE THAT ORDER OF THESE INSTRUCTION MATTERS
          // Play next track after broken one
          await play(playlistControl.getNextSongId(songId));
          res = 0;
          playlistControl.songs(PlaylistType.global).removeAt(
              playlistControl.getSongIndexById(songId)); //Remove broken track
          playlistControl.emitPlaylistChange();
          playlistControl.refetchSongs(); // Perform fetching
        }
      }
    } catch (e) {
      debugPrint('Error thrown in my player class play method - error: $e');
    } finally {
      // If res is successful, then change playing track id
      if (res == 1) playlistControl.playingTrackIdState = songId;
      // Switching is set to false in `onSongChange` listener
      playlistControl.emitSongChange();
    }
  }

  /// Resume player
  ///
  /// It handles errors the same way as play method above
  /// Positional optional argument `songId` is needed to jump to next track when handling error
  Future<void> resume([int songId]) async {
    // If `songId` hasn't been provided then use playing id state
    if (songId == null) songId = playlistControl.playingTrackIdState;
    switching = true;
    await _requestFocus();
    // NOTE that this is defaults to 1 and if needed you have to set it manually to 0
    int res = 1;
    try {
      if (focusState == AudioFocusType.focus)
        res = await nativePlayerInstance.resume();
      // Else if gainFocus is being handled in `setMethodCallHandler` listener above.
      //When delay is over android triggers AUDIOFOCUS_GAIN and track starts to play

      // Do nothing if no focus has been granted

    } on PlatformException catch (e) {
      /// `Unsupported value: java.lang.IllegalStateException` message thrown when `play` gets called in wrong state
      /// `Unsupported value: java.lang.RuntimeException: Unable to access resource` message thrown when resource can't be played
      debugPrint(
          'Error thrown in my player class play method - {code: ${e.code} --- details: ${e.details} --- message:${e.message}}');

      if (e.code == "error") {
        if (e.message ==
            "Unsupported value: java.lang.RuntimeException: Unable to access resource") {
          Fluttertoast.showToast(
              msg: 'Произошла ошибка при воспроизведении,\n удаление трека',
              backgroundColor: Color.fromRGBO(18, 18, 18, 1));

          // NOTE THAT ORDER OF THESE INSTRUCTION MATTERS
          // Play next track after broken one
          await play(playlistControl.getNextSongId(songId));
          res = 0;
          playlistControl.songs(PlaylistType.global).removeAt(
              playlistControl.getSongIndexById(songId)); //Remove broken track
          playlistControl.emitPlaylistChange();
          playlistControl.refetchSongs(); // Perform fetching
        }
      }
    } catch (e) {
      debugPrint('Error thrown in my player class play method - error: $e');
    } finally {
      // If res is successful, then change playing track id
      if (res == 1) playlistControl.playingTrackIdState = songId;
      // Switching is set to false
      switching = false;
    }
  }

  /// Pause player
  Future<void> pause() async {
    await nativePlayerInstance.pause();
    await _abandonFocus();
  }

  /// Stop player
  Future<void> stop() async {
    await nativePlayerInstance.stop();
    // await _closeNotification();
    // Change state if result is successful
    await _abandonFocus();
  }

  /// Seek
  Future<void> seek(int seconds) async {
    await nativePlayerInstance.seek(Duration(seconds: seconds));
  }

  /// Function that fires when pause/play button got clicked
  Future<void> clickPausePlay() async {
    debugPrint(switching.toString());
    // TODO: refactor
    if (!switching) {
      switch (playState) {
        case AudioPlayerState.PLAYING:
          await pause();
          break;
        case AudioPlayerState.PAUSED:
          await resume();
          break;
        case AudioPlayerState.STOPPED:
          // Currently unused and shouldn't
          await play(playlistControl.playingTrackIdState);
          break;
        case AudioPlayerState.COMPLETED:
          await play(playlistControl.playingTrackIdState);
          break;
        default:
          // TODO: add exception
          // throw Exception('Invalid player state variant');
          break;
      }
    }
  }

  /// Function that fires when next track button got clicked
  Future<void> clickNext() async {
    if (!switching)
      play(playlistControl.getNextSongId(playlistControl.playingTrackIdState));
  }

  /// Function that fires when prev track button got clicked
  Future<void> clickPrev() async {
    if (!switching)
      play(playlistControl.getPrevSongId(playlistControl.playingTrackIdState));
  }

  /// Function that handles click on track tile
  ///
  /// `clickedSongId` argument denotes an id of clicked track `TrackList`
  Future<void> clickTrackTile(int clickedSongId) async {
    if (!switching) {
      switch (playState) {
        case AudioPlayerState.PLAYING:
          // If user clicked the same track
          if (playlistControl.playingTrackIdState == clickedSongId)
            await pause();
          // If user decided to click a new track
          else
            await play(clickedSongId);
          break;
        case AudioPlayerState.PAUSED:
          // If user clicked the same track
          if (playlistControl.playingTrackIdState == clickedSongId)
            await resume(clickedSongId);
          // If user decided to click a new track
          else
            await play(clickedSongId);
          break;
        case AudioPlayerState.STOPPED:
          // Currently unused and shouldn't
          await play(clickedSongId);
          break;
        case AudioPlayerState.COMPLETED:
          await play(clickedSongId);
          break;
        default:
          // All other case, e.g. null or state after error
          await play(clickedSongId);
          break;
      }
    }
  }

  /// Init whole music instance
  ///
  Future<void> _init() async {
    // Get saved data
    var prefs = await SharedPreferences.getInstance();
    var savedLoopMode = prefs.getBool(Constants.PrefKeys.loopModeBool);

    // Set loop mode to true if it is true in prefs
    if (savedLoopMode != null && savedLoopMode) {
      loopModeState = savedLoopMode;
      nativePlayerInstance.setReleaseMode(ReleaseMode.LOOP);
    }

    _placeholderImgBytes =
        (await rootBundle.load('images/placeholder_thumb.png'))
            .buffer
            .asUint8List();
  }

  // TODO: improve and implement this method
  void dispose() {
    _songChangeListenerSubscription.cancel();
    _eventSubscription.cancel();
    _stateChangeSubscription.cancel();
    _completionSubscription.cancel();
  }
}

/// Function that returns artist, or automatically show "Неизвестный исполнитель" instead of "<unknown>"
String artistString(String artist) =>
    artist != '<unknown>' ? artist : 'Неизвестный исполнитель';
