import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:app/components/show_functions.dart';
import 'package:app/constants/constants.dart' as Constants;
import 'package:app/player/logger.dart';
import 'package:app/player/playlist.dart';
import 'package:app/player/prefs.dart';
import 'package:catcher/core/catcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

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

abstract class MusicPlayer {
  /// Image bytes to display in notification
  static Uint8List _placeholderImgBytes;

  /// Channel for handling audio focus
  static MethodChannel _playerChannel =
      const MethodChannel(Constants.PlayerChannel.channelName);

  /// Event channel for receiving native android events
  static EventChannel _eventChannel =
      const EventChannel(Constants.EventChannel.channelName);

  /// `[AudioPlayer]` player instance
  static final nativePlayerInstance =
      AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);

  /// A subscription to song change
  static StreamSubscription<void> _songChangeListenerSubscription;

  /// Subscription for events stream
  static StreamSubscription _eventSubscription;

  /// Subscription for changes in state
  static StreamSubscription<AudioPlayerState> _stateChangeSubscription;

  /// Subscription for completion changes
  static StreamSubscription<void> _completionSubscription;

  /// Subscription for native player error
  static StreamSubscription<String> _errorSubscription;

  /// Audio manager focus state
  static AudioFocusType focusState = AudioFocusType.no_focus;

  /// Is notification visible
  static bool notificationState = false;

  /// Is notification visible
  static bool loopModeState = false;

  /// Hook handle
  /// Variable to save latest hook press time
  static DateTime _latestHookPressTime;

  /// How much times hook has been pressed during handle multiple presses time (e.g. 700ms)
  static int _hookPressStack = 0;

  // Getters

  /// Get stream of changes on audio position.
  static Stream<Duration> get onAudioPositionChanged =>
      nativePlayerInstance.onAudioPositionChanged;

  /// Get stream of changes on player state.
  static Stream<AudioPlayerState> get onPlayerStateChanged =>
      nativePlayerInstance.onPlayerStateChanged;

  /// Get stream of changes on audio duration
  static Stream<Duration> get onDurationChanged =>
      nativePlayerInstance.onDurationChanged;

  /// Get stream of player completions
  static Stream<void> get onPlayerCompletion =>
      nativePlayerInstance.onPlayerCompletion;

  /// Get stream of player errors
  static Stream<String> get onPlayerError => nativePlayerInstance.onPlayerError;

  static AudioPlayerState get playState => nativePlayerInstance.state;

  /// Get current position
  static Future<Duration> get currentPosition async {
    try {
      return Duration(
          milliseconds: await nativePlayerInstance.getCurrentPosition());
    } catch (e) {
      debugPrint('nativePlayerInstance getCurrentPosition error! - error: $e');
      return Duration(seconds: 0);
    }
  }

  /// Init whole music instance
  ///
  static Future<void> init() async {
    nativePlayerInstance.setReleaseMode(ReleaseMode.STOP);

    _songChangeListenerSubscription =
        PlaylistControl.onSongChange.listen((event) {
      Prefs.byKey.songIdInt.setPref(PlaylistControl.currentSong?.id);
    });

    _errorSubscription = nativePlayerInstance.onPlayerError.listen((event) {
      debugger();
    });

    _completionSubscription = onPlayerCompletion.listen((event) {
      // Play next track if not in loop mode, as in loop mode this event is not triggered
      playNext();
    });

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      switch (event) {
        case Constants
            .EventChannel.eventBecomeNoisy: // handle headphones disconnect
          pause();
          break;
        case Constants.EventChannel.eventPlay:
          playPause();
          break;
        case Constants.EventChannel.eventPause:
          playPause();
          break;
        case Constants.EventChannel.eventNext:
          playNext();
          break;
        case Constants.EventChannel.eventPrev:
          playPrev();
          break;
        default:
          throw Exception('Invalid event');
      }
    });

    _stateChangeSubscription = onPlayerStateChanged.listen((event) async {
      Logger.log("stateChange", event.toString());

      switch (event) {
        case AudioPlayerState.PLAYING:
          _showNotification(
              artist: artistString(PlaylistControl.currentSong?.artist),
              title: PlaylistControl.currentSong?.title,
              albumArtUri: PlaylistControl.currentSong?.albumArtUri,
              isPlaying: true);
          notificationState = true;
          break;
        case AudioPlayerState.PAUSED:
          if (notificationState)
            _showNotification(
                artist: artistString(PlaylistControl.currentSong?.artist),
                title: PlaylistControl.currentSong?.title,
                albumArtUri: PlaylistControl.currentSong?.albumArtUri,
                isPlaying: false);
          break;
        case AudioPlayerState.STOPPED:
          _closeNotification();
          notificationState = false;
          break;
        case AudioPlayerState.COMPLETED:
          break;
        default: // Can be null, so don't throw
          break;
      }
    });

    // TODO: see how to improve focus and implement gain delayed usage
    // Set listener for method calls for changing focus
    _playerChannel.setMethodCallHandler((MethodCall call) async {
      // debugPrint('${call.method}, ${call.arguments.toString()}');

      if (call.method == Constants.PlayerChannel.methodFocusChange) {
        switch (call.arguments) {
          // TODO: rewrite instead of these methods my class methods (resume, pause, etc.)
          case Constants.PlayerChannel.argFocusGain:
            int res = await _recursiveCallback(nativePlayerInstance.resume);
            if (res == 1) focusState = AudioFocusType.focus;
            break;
          case Constants.PlayerChannel.argFocusLoss:
            int res = await _recursiveCallback(nativePlayerInstance.pause);
            if (res == 1) focusState = AudioFocusType.no_focus;
            break;
          case Constants.PlayerChannel.argFocusLossTrans:
            int res = await _recursiveCallback(nativePlayerInstance.pause);
            if (res == 1) focusState = AudioFocusType.focus_delayed;
            break;
          case Constants.PlayerChannel.argFocusLossTransCanDuck:
            int res = await _recursiveCallback(nativePlayerInstance.pause);
            if (res == 1) focusState = AudioFocusType.focus_delayed;
            // TODO: implement volume change
            break;
          default:
            throw Exception('Incorrect method argument came from native code');
        }
      } else if (call.method ==
          Constants.PlayerChannel.methodMediaButtonClick) {
        Logger.log('playerChannel',
            'method: ${call.method}, argument ${call.arguments}');

        if (call.arguments == Constants.PlayerChannel.argAudioTrack) {
          await playNext();
        } else if (call.arguments == Constants.PlayerChannel.argFastForward) {
          await fastForward();
        } else if (call.arguments == Constants.PlayerChannel.argRewind) {
          await rewind();
        } else if (call.arguments == Constants.PlayerChannel.argNext) {
          await playNext();
        } else if (call.arguments == Constants.PlayerChannel.argPrevious) {
          await playPrev();
        } else if (call.arguments == Constants.PlayerChannel.argPlayPause) {
          await playPause();
        } else if (call.arguments == Constants.PlayerChannel.argPlay) {
          await resume();
        } else if (call.arguments == Constants.PlayerChannel.argStop) {
          await pause();
        } else if (call.arguments == Constants.PlayerChannel.argHookButton) {
          // Avoid errors when app is loading
          if (PlaylistControl.playReady) {
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
      }
    });

    // Get saved data
    var savedLoopMode = await Prefs.byKey.loopModeBool.getPref();

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
  static void dispose() {
    _songChangeListenerSubscription.cancel();
    _eventSubscription.cancel();
    _stateChangeSubscription.cancel();
    _completionSubscription.cancel();
  }

  /// Play/pause, next or prev function depending on `_hookPressStack`
  static Future<void> _handleHookDelayedPress() async {
    // Wait 0.6s
    await Future.delayed(Duration(milliseconds: 600));
    switch (_hookPressStack) {
      case 1:
        Logger.log('hookPressRes', 'play/pause');
        await playPause();
        break;
      case 2:
        Logger.log('hookPressRes', 'next');
        await playNext();
        break;
      case 3:
        await playPrev();
        Logger.log('hookPressRes', 'prev');
        break;
    }
    _hookPressStack = 0;
  }

  // TODO: add implementation for this function and change method name to `get_intent_action_view`
  static Future<void> _isIntentActionView() async {
    debugPrint((await _playerChannel
            .invokeMethod(Constants.PlayerChannel.methodIntentActionView))
        .toString());
  }

  /// Request audio manager focus
  static Future<void> _requestFocus() async {
    if (focusState == AudioFocusType.no_focus) {
      switch (await _playerChannel
          .invokeMethod<String>(Constants.PlayerChannel.methodRequestFocus)) {
        case Constants.PlayerChannel.returnRequestFail:
          focusState = AudioFocusType.no_focus;
          break;
        case Constants.PlayerChannel.returnRequestGrant:
          focusState = AudioFocusType.focus;
          break;
        case Constants.PlayerChannel.returnRequestDelay:
          focusState = AudioFocusType.focus_delayed;
          break;
      }
    }
  }

  /// Abandon audio manager focus
  static Future<void> _abandonFocus() async {
    await _playerChannel
        .invokeMethod(Constants.PlayerChannel.methodAbandonFocus);
    focusState = AudioFocusType.no_focus;
  }

// TODO: move notification methods to separate class maybe
  /// Method to show/update notification
  static Future<void> _showNotification(
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

    await _playerChannel
        .invokeMethod(Constants.PlayerChannel.methodShowNotification, {
      Constants.PlayerChannel.argTitle: title,
      Constants.PlayerChannel.argArtist: artist,
      Constants.PlayerChannel.argAlbumArtBytes: albumArtBytes,
      Constants.PlayerChannel.argIsPlaying: isPlaying
    });
  }

  /// Method to hide notification
  static Future<void> _closeNotification() async {
    await _playerChannel
        .invokeMethod(Constants.PlayerChannel.methodCloseNotification);
  }

  static Future<void> switchLoopMode() async {
    if (loopModeState) {
      nativePlayerInstance.setReleaseMode(ReleaseMode.STOP);
      Prefs.byKey.loopModeBool.setPref(false);
    } else {
      nativePlayerInstance.setReleaseMode(ReleaseMode.LOOP);
      Prefs.byKey.loopModeBool.setPref(true);
    }
    loopModeState = !loopModeState;
  }

  /// Play track
  ///
  /// `songId` argument denotes an id track to play
  static Future<void> play(int songId) async {
    await _requestFocus();
    int res = 1;
    try {
      final uri = PlaylistControl.getSongById(songId).trackUri;
      if (focusState == AudioFocusType.focus)
        await nativePlayerInstance.play(
          uri,
          stayAwake:
              true, // This is very important for player to stay play even in background
          isLocal: true,
        );
      else if (focusState == AudioFocusType.focus_delayed)
        // Set url if no focus has been granted
        await nativePlayerInstance.setUrl(uri);
    } on PlatformException catch (e) {
      /// `Unsupported value: java.lang.IllegalStateException` message thrown when `play` gets called in wrong state
      /// `Unsupported value: java.lang.RuntimeException: Unable to access resource` message thrown when resource can't be played
      debugPrint(
          'Error thrown in my player class play method - {code: ${e.code} --- details: ${e.details} --- message:${e.message}}');

      Logger.log('Play error', e.toString());

      if (e.code == "error") {
        if (e.message ==
            "Unsupported value: java.lang.RuntimeException: Unable to access resource") {
          ShowFunctions.showToast(
              msg: 'Произошла ошибка при воспроизведении,\n удаление трека');

          // NOTE THAT ORDER OF THESE INSTRUCTION MATTERS
          // Play next track after broken one
          await play(PlaylistControl.getNextSongId(songId));
          PlaylistControl.songs(PlaylistType.global).removeAt(
              PlaylistControl.getSongIndexById(songId)); //Remove broken track
          PlaylistControl.emitPlaylistChange();
          PlaylistControl.refetchSongs(); // perform fetching
        } else if (e.message ==
            "Unsupported value: java.lang.IllegalStateException") {
          // TODO: maybe add handler here
          res = 0;
        }
      }
    } catch (e) {
      debugPrint(
          'Unexpected error thrown in my player class play method - error: $e');
    } finally {
      // Change playing track id
      // NOTE that we change it always
      // TODO: check for deleted track error case;
      if (res == 1)
        PlaylistControl.changeSong(songId);
      else
        play(PlaylistControl.currentSongId);
    }
  }

  /// Resume player
  ///
  /// TODO: rewrite like `play()` method
  ///
  /// It handles errors the same way as play method above
  /// Positional optional argument `songId` is needed to jump to next track when handling error
  static Future<void> resume([int songId]) async {
    // If `songId` hasn't been provided then use playing id state
    if (songId == null) songId = PlaylistControl.currentSongId;
    await _requestFocus();
    try {
      if (focusState == AudioFocusType.focus)
        await nativePlayerInstance.resume();
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
          ShowFunctions.showToast(
              msg: 'Произошла ошибка при воспроизведении,\n удаление трека');

          Logger.log('Resume error', e.toString());

          // NOTE THAT ORDER OF THESE INSTRUCTION MATTERS
          // Play next track after broken one
          await play(PlaylistControl.getNextSongId(songId));
          PlaylistControl.songs(PlaylistType.global).removeAt(
              PlaylistControl.getSongIndexById(songId)); //Remove broken track
          PlaylistControl.emitPlaylistChange();
          PlaylistControl.refetchSongs(); // Perform fetching
        } else if (e.message ==
            "Unsupported value: java.lang.IllegalStateException") {
          // TODO: maybe add handler here
        }
      }
    } catch (e) {
      debugPrint(
          'Unexpected error thrown in my player class play method - error: $e');
    }
  }

  /// Pause player
  static Future<void> pause() async {
    await nativePlayerInstance.pause();
    await _abandonFocus();
  }

  /// Stop player
  static Future<void> stop() async {
    await nativePlayerInstance.stop();
    // await _closeNotification();
    // Change state if result is successful
    await _abandonFocus();
  }

  /// Seek
  static Future<void> seek(Duration timing) async {
    await nativePlayerInstance.seek(timing);
  }

  /// Seek 3 seconds forward
  ///
  /// @param (optional) interval makes it possible to seek for specified interval
  static Future<void> fastForward([Duration interval]) async {
    if (interval == null) interval = Duration(seconds: 3);
    await nativePlayerInstance.seek(((await currentPosition) + interval));
  }

  /// Seek 3 seconds backwards
  ///
  /// @param (optional) interval makes it possible to seek for specified interval
  static Future<void> rewind([Duration interval]) async {
    if (interval == null) interval = Duration(seconds: 3);
    await nativePlayerInstance.seek(((await currentPosition) - interval));
  }

  /// Function that fires when pause/play button got clicked
  static Future<void> playPause() async {
    switch (playState) {
      case AudioPlayerState.PLAYING:
        await pause();
        break;
      case AudioPlayerState.PAUSED:
        await resume();
        break;
      case AudioPlayerState.STOPPED:
        // Currently unused and shouldn't
        await play(PlaylistControl.currentSongId);
        break;
      case AudioPlayerState.COMPLETED:
        await play(PlaylistControl.currentSongId);
        break;
      default: // Can be null, so don't throw
        break;
    }
  }

  /// Function that fires when next track button got clicked
  ///
  /// If provided `songId` - plays next from this id
  static Future<void> playNext([int songId]) async {
    songId ??= PlaylistControl.getNextSongId(PlaylistControl.currentSongId);
    await play(songId);
  }

  /// Function that fires when prev track button got clicked
  ///
  /// If provided `songId` - plays prev from this id
  static Future<void> playPrev([int songId]) async {
    songId ??= PlaylistControl.getPrevSongId(PlaylistControl.currentSongId);
    await play(songId);
  }

  /// Function that handles click on track tile
  ///
  /// `clickedSongId` argument denotes an id of clicked track `MainRouteTrackList`
  static Future<void> clickTrackTile(int clickedSongId) async {
    switch (playState) {
      case AudioPlayerState.PLAYING:
        // If user clicked the same track
        if (PlaylistControl.currentSongId == clickedSongId)
          await pause();
        // If user decided to click a new track
        else
          await play(clickedSongId);
        break;
      case AudioPlayerState.PAUSED:
        // If user clicked the same track
        if (PlaylistControl.currentSongId == clickedSongId)
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
      default: // Can be null, so don't throw, just play
        await play(clickedSongId);
        break;
    }
  }
}

/// Function that returns artist, or automatically show "Неизвестный исполнитель" instead of "<unknown>"
String artistString(String artist) =>
    artist != '<unknown>' ? artist : 'Неизвестный исполнитель';
