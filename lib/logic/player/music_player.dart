/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

export 'fetcher.dart';
export 'native_player.dart';
export 'playlist.dart';
export 'serialization.dart';
export 'song.dart';

import 'dart:async';
import 'dart:developer';
import 'playlist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:sweyer/sweyer.dart';

abstract class MusicPlayer {
  /// A subscription to song change
  static StreamSubscription<void> _songChangeListenerSubscription;

  // Native player subscriptions
  static StreamSubscription<AudioPlayerState> _stateChangeSubscription;
  static StreamSubscription<void> _completionSubscription;
  /// TODO: implement this instead of on song change
  static StreamSubscription<Duration> _durationSubscription;
  static StreamSubscription<String> _errorSubscription;

  /// Audio manager focus state
  // static AudioFocusType focusState = AudioFocusType.no_focus;

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
      NativeAudioPlayer.onAudioPositionChanged;

  /// Get stream of changes on player state.
  static Stream<AudioPlayerState> get onPlayerStateChanged =>
      NativeAudioPlayer.onPlayerStateChanged;

  /// Get stream of changes on audio duration
  static Stream<Duration> get onDurationChanged =>
      NativeAudioPlayer.onDurationChanged;

  /// Get stream of player completions
  static Stream<void> get onPlayerCompletion =>
      NativeAudioPlayer.onPlayerCompletion;

  /// Get stream of player errors
  static Stream<String> get onPlayerError => NativeAudioPlayer.onPlayerError;

  static AudioPlayerState get playState => NativeAudioPlayer.state;

  /// Get current position
  static Future<Duration> get currentPosition async {
    try {
      return Duration(
          milliseconds: await NativeAudioPlayer.getCurrentPosition());
    } catch (e) {
      return Duration(seconds: 0);
    }
  }

  /// Init whole music instance
  ///
  static Future<void> init() async {

    NativeAudioPlayer.init();

    _songChangeListenerSubscription =
        PlaylistControl.onSongChange.listen((event) async {
      // Prefs.byKey.songIdInt.setPref(PlaylistControl.currentSong?.id);

      await setUrl(PlaylistControl.currentSong.trackUri);
    });

    _durationSubscription = NativeAudioPlayer.onDurationChanged.listen((event) {
      print("DURATION CHANGE ${event.inSeconds}");
    });

    _errorSubscription = NativeAudioPlayer.onPlayerError.listen((event) {
      debugger();
    });

    _completionSubscription = onPlayerCompletion.listen((event) {
      // Play next track if not in loop mode, as in loop mode this event is not triggered
      playNext();
    });

    //******** RESTORE BY PREFS ***************

    var prefs = await Prefs.getSharedInstance();
    // Get saved data
    bool savedLoopMode = await Prefs.byKey.loopModeBool.getPref(prefs);

    int savedSongPos;
    // Disable restoring position if native player is actually playing right now
    if (!(await NativeAudioPlayer.isPlaying()))
      savedSongPos = await Prefs.byKey.songPositionInt.getPref(prefs);

    // Set loop mode to true if it is true in prefs
    if (savedLoopMode != null && savedLoopMode) {
      loopModeState = savedLoopMode;
      NativeAudioPlayer.setReleaseMode(ReleaseMode.LOOP);
    }
    // Seek to saved position
    if (savedSongPos != null)
      await MusicPlayer.seek(Duration(seconds: savedSongPos));
  }

  // TODO: improve and add usage to this method
  static void dispose() {
    _songChangeListenerSubscription.cancel();
    _stateChangeSubscription.cancel();
    _durationSubscription.cancel();
    _errorSubscription.cancel();
    _completionSubscription.cancel();
  }

  static void hookPress() {
    // Avoid errors when app is loading
    if (PlaylistControl.playReady) {
      DateTime now = DateTime.now();
      if (_latestHookPressTime == null ||
          now.difference(_latestHookPressTime) >
              // TODO: extract delays to constant
              // TODO: move this to native side
              // `_handleHookDelayedPress` delay + safe delay (trying to fix hook button press bug)
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

  static Future<void> switchLoopMode() async {
    if (loopModeState) {
      NativeAudioPlayer.setReleaseMode(ReleaseMode.STOP);
      Prefs.byKey.loopModeBool.setPref(false);
    } else {
      NativeAudioPlayer.setReleaseMode(ReleaseMode.LOOP);
      Prefs.byKey.loopModeBool.setPref(true);
    }
    loopModeState = !loopModeState;
  }

  /// Play track
  /// TODO: rewrite this completely and test with deleted songs
  /// `songId` argument denotes an id track to play
  ///
  /// If `silent` is true, won't play track, but just switch to it
  /// (the difference with the `setUrl` with this parameter is that this function will also update current playing song respectively)
  static Future<void> play(int songId, {bool silent = false}) async {
    // await _requestFocus();
    int res = 1;
    try {
      final song = PlaylistControl.getSongById(songId);
      // if (focusState == AudioFocusType.focus && !silent)
      if (!silent)
        await NativeAudioPlayer.play(
          song,
          stayAwake:
              true, // This is very important for player to stay play even in background
          isLocal: true,
        );
      // else if (focusState == AudioFocusType.focus_delayed && silent)
      else if (silent)
        // Set url if no focus has been granted
        await setUrl(song.trackUri);
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
          await play(PlaylistControl.getNextSongId(songId), silent: silent);
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
      // TODO: check for deleted track error case;
      if (res == 1)
        PlaylistControl.changeSong(songId);
      else
        play(PlaylistControl.currentSongId, silent: silent);
    }
  }

  /// Sets track url
  ///
  /// Unlike [play], the playback will not resume, but song will be switched if it player is playing
  static Future<void> setUrl(String url) async {
    try {
      await NativeAudioPlayer.setUrl(url);
    } catch (e) {
      debugPrint("Error in `setUrl` method: $e");
    }
  }

  /// Resume player
  ///
  /// TODO: rewrite this completely
  ///
  /// It handles errors the same way as play method above
  /// Positional optional argument `songId` is needed to jump to next track when handling error
  static Future<void> resume([int songId]) async {
    // If `songId` hasn't been provided then use playing id state
    if (songId == null) songId = PlaylistControl.currentSongId;
    try {
      await NativeAudioPlayer.resume();
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
    await NativeAudioPlayer.pause();
  }

  /// Stop player
  static Future<void> stop() async {
    await NativeAudioPlayer.stop();
  }

  /// Seek
  static Future<void> seek(Duration timing) async {
    await NativeAudioPlayer.seek(timing);
  }

  /// Seek 3 seconds forward
  ///
  /// @param (optional) interval makes it possible to seek for specified interval
  static Future<void> fastForward([Duration interval]) async {
    if (interval == null) interval = Duration(seconds: 3);
    await NativeAudioPlayer.seek(((await currentPosition) + interval));
  }

  /// Seek 3 seconds backwards
  ///
  /// @param (optional) interval makes it possible to seek for specified interval
  static Future<void> rewind([Duration interval]) async {
    if (interval == null) interval = Duration(seconds: 3);
    await NativeAudioPlayer.seek(((await currentPosition) - interval));
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
  static Future<void> playNext({int songId, bool silent = false}) async {
    songId ??= PlaylistControl.getNextSongId(PlaylistControl.currentSongId);
    await play(songId, silent: silent);
  }

  /// Function that fires when prev track button got clicked
  ///
  /// If provided `songId` - plays prev from this id
  static Future<void> playPrev({int songId, bool silent = false}) async {
    songId ??= PlaylistControl.getPrevSongId(PlaylistControl.currentSongId);
    await play(songId, silent: silent);
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
