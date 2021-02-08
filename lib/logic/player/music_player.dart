/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

export 'native_player.dart';
export 'playlist.dart';
export 'serialization.dart';
export 'content.dart';
export 'models/models.dart';

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

abstract class MusicPlayer {
  // Getters

  /// Get stream of changes on audio position.
  static Stream<Duration> get onPosition => NativeAudioPlayer.onPosition;

  /// Get stream of changes on player state.
  static Stream<MusicPlayerState> get onStateChange =>
      NativeAudioPlayer.onStateChange;

  /// Get stream of player completions
  static Stream<void> get onCompletion => NativeAudioPlayer.onCompletion;

  /// Get stream of player errors
  static Stream<PlatformException> get onError => NativeAudioPlayer.onError;

  /// Get stream of loop mode changes
  static Stream<bool> get onLoopSwitch => NativeAudioPlayer.onLoopSwitch;
  static MusicPlayerState get playerState => NativeAudioPlayer.state;
  static bool get looping => NativeAudioPlayer.looping;

  /// Get current position
  static Future<Duration> get position async {
    try {
      return Duration(milliseconds: await NativeAudioPlayer.getPosition());
    } catch (e) {
      return Duration(seconds: 0);
    }
  }

  /// Get duration of current song
  static Future<Duration> get duration async {
    try {
      return Duration(milliseconds: await NativeAudioPlayer.getDuration());
    } catch (e) {
      return Duration(seconds: 0);
    }
  }

  /// Init whole music instance
  ///
  static Future<void> init() async {
    NativeAudioPlayer.init();

    onCompletion.listen((event) {
      // Play next track if not in loop mode, as in loop mode this event is not triggered
      playNext();
    });

    //******** RESTORE BY PREFS ***************

    int songPosition;
    // Disable restoring position if native player is actually playing right now
    if (!(await NativeAudioPlayer.isPlaying())) {
      songPosition = await Prefs.songPositionInt.get();
    }

    // Seek to saved position
    if (songPosition != null) {
      await MusicPlayer.seek(Duration(seconds: songPosition));
    }
  }

  static Future<void> switchLooping() async {
    return NativeAudioPlayer.setLooping(!looping);
  }

  static bool _hasDuplicates(Song song) {
    return (ContentControl.state.queues.type != QueueType.all ||
            ContentControl.state.queues.modified) &&
        ContentControl.state.queues.current.songs
                .where((el) => el.id == song.id)
                .length >
            1;
  }

  /// Plays the [song].
  ///
  /// If [silent] is true, won't play track, but just switch to it.
  static Future<void> play(
    Song song, {
    bool silent = false,
    bool duplicate,
  }) async {
    song ??= ContentControl.state.queues.all.songs[0];
    ContentControl.state.changeSong(song);
    try {
      final _duplicate = duplicate ?? _hasDuplicates(song);
      final copiedSong = song.copyWith(
        id: song.id < 0
            ? ContentControl.state.idMap[song.id.toString()]
            : song.id,
      );
      var res;
      if (!silent) {
        res = NativeAudioPlayer.play(copiedSong, _duplicate);
      } else {
        res = NativeAudioPlayer.setUri(copiedSong, _duplicate);
      }
      if (_duplicate && duplicate == null) {
        ContentControl.handleDuplicate(song);
      }
      await res;
    } on PlatformException catch (e) {
      if (e.code == 'error') {
        if (e.message == Constants.Errors.UNABLE_ACCESS_RESOURCE) {
          ShowFunctions.instance.showToast(
            msg: getl10n(App.navigatorKey.currentContext).playbackErrorMessage,
          );
          // The order of these calls matters
          // Play next song after broken one
          await playNext(
            song: song,
            silent: silent,
          );
          // Remove broken song
          ContentControl.state.queues.all.removeSong(song);
          ContentControl.state.emitSongListChange();
          ContentControl.refetchSongs(); // perform fetching
        } else if (e.message == Constants.Errors.NATIVE_PLAYER_ILLEGAL_STATE) {
          // ...
        }
      }
    } catch (e) {
      // Do not handle this, because other exceptions are not expected
      rethrow;
    }
  }

  /// Resume player
  static Future<void> resume([int songId]) async {
    // If [songId] hasn't been provided then use playing id state
    if (songId == null) songId = ContentControl.state.currentSongId;
    try {
      return NativeAudioPlayer.resume();
    } catch (e) {
      rethrow;
    }
  }

  /// Pause player
  static Future<void> pause() async {
    return NativeAudioPlayer.pause();
  }

  /// Seek
  static Future<void> seek(Duration position) async {
    return NativeAudioPlayer.seek(position);
  }

  /// Seeks by [interval] forward, by default `3` seconds.
  static Future<void> fastForward([Duration interval]) async {
    if (interval == null) interval = Duration(seconds: 3);
    return NativeAudioPlayer.seek(((await position) + interval));
  }

  /// Seeks by [interval] backwards, by default `3` seconds.
  static Future<void> rewind([Duration interval]) async {
    if (interval == null) interval = Duration(seconds: 3);
    return NativeAudioPlayer.seek(((await position) - interval));
  }

  /// Function that fires when pause/play button got clicked
  static Future<void> playPause() async {
    switch (playerState) {
      case MusicPlayerState.PLAYING:
        await pause();
        break;
      case MusicPlayerState.PAUSED:
        await resume();
        break;
      case MusicPlayerState.COMPLETED:
        await play(ContentControl.state.currentSong);
        break;
      default: // Can be null, so don't throw
        break;
    }
  }

  /// Plays the song after current, or if speceified, then after [song].
  static Future<void> playNext({Song song, bool silent = false}) async {
    song ??= ContentControl.state.queues.current.getNextSong(
      song ?? ContentControl.state.currentSong,
    );
    var res;

    if (song != null) {
      play(song, silent: silent);
    } else {
      final songs = ContentControl.state.queues.all.songs;
      if (songs.isNotEmpty) {
        song = songs[0];
        play(song, silent: silent);
      }
    }
    seek(const Duration());
    await res;
  }

  /// Plays the song before current, or if speceified, then before [song].
  static Future<void> playPrev({Song song, bool silent = false}) async {
    song ??= ContentControl.state.queues.current.getPrevSong(
      song ?? ContentControl.state.currentSong,
    );
    var res;
    if (song != null) {
      res = play(song, silent: silent);
    } else {
      final songs = ContentControl.state.queues.all.songs;
      if (songs.isNotEmpty) {
        song = songs[0];
        res = play(song, silent: silent);
      }
    }
    seek(const Duration());
    await res;
  }

  /// Function that handles click on track tile.
  /// Opens player route.
  /// Default click [behaviour] is [SongClickBehavior.play].
  static Future<void> handleSongClick(
    BuildContext context,
    Song clickedSong, {
    SongClickBehavior behavior = SongClickBehavior.play,
  }) async {
    final duplicate = _hasDuplicates(clickedSong);
    bool isSame;
    if (duplicate) {
      ContentControl.handleDuplicate(clickedSong);
      isSame = false;
    } else {
      isSame = clickedSong == ContentControl.state.currentSong;
    }
    if (behavior == SongClickBehavior.play) {
      getPlayerRouteControllerProvider(context).controller.open();
      final res = play(clickedSong, duplicate: duplicate);

      /// I'm doing this in this order because for some reason on
      /// the VERY FIRST seek it will be ignored. Just ignored,
      /// it will seek and after it will start playing, it will be just restored
      /// back for some reason. In other places the same applies.
      seek(const Duration());
      await res;
    } else {
      if (isSame) {
        if (playerState == MusicPlayerState.PAUSED ||
            playerState == MusicPlayerState.COMPLETED) {
          getPlayerRouteControllerProvider(context).controller.open();
          await resume();
        } else {
          await pause();
        }
      } else {
        getPlayerRouteControllerProvider(context).controller.open();
        final res = play(clickedSong, duplicate: duplicate);
        seek(const Duration());
        await res;
      }
    }
  }
}

/// Describes how to respond to song tile clicks.
enum SongClickBehavior {
  /// Behavior to always start the clicked song from the beginning.
  play,

  /// Behavior to allow play/pause on the clicked song.
  playPause
}
