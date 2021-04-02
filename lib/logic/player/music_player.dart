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

abstract class MusicPlayer {
  /// Stream of changes on audio position.
  static Stream<Duration> get onPosition => NativePlayer.onPosition;

  /// Stream of changes on player state.
  static Stream<PlayerState> get onStateChange => NativePlayer.onStateChange;

  /// Stream of loop mode changes
  static Stream<bool> get onLoopSwitch => NativePlayer.onLoopSwitch;
  static PlayerState get playerState => NativePlayer.state;
  static bool get looping => NativePlayer.looping;

  /// Current position.
  static Future<Duration> get position async {
    try {
      return Duration(milliseconds: await NativePlayer.getPosition());
    } catch (e) {
      return Duration(seconds: 0);
    }
  }

  /// Duration of current song.
  static Future<Duration> get duration async {
    try {
      return Duration(milliseconds: await NativePlayer.getDuration());
    } catch (e) {
      return Duration(seconds: 0);
    }
  }

  static Future<void> init() async {
    NativePlayer.init();

    onStateChange.listen((event) {
      if (event == PlayerState.COMPLETED) {
        // Play next track if not in loop mode, in loop mode this event is not triggered.
        playNext();
      }
    });

    // Restring seek from prefs.
    // Disable restoring position if native player is actually playing right now.
    if (!(await NativePlayer.isPlaying())) {
      final songPosition = await Prefs.songPositionInt.get();
      await MusicPlayer.seek(Duration(seconds: songPosition));
    }
  }

  /// Switches the loop mode.
  static Future<void> switchLooping() async {
    return NativePlayer.setLooping(!looping);
  }

  static bool _hasDuplicates(Song song) {
    final queues = ContentControl.state.queues;
    return (queues.type != QueueType.all || queues.modified) &&
            queues.current.songs.where((el) => el.id == song.id).length > 1;
  }

  /// Plays the [song].
  ///
  /// If [silent] is true, won't play track, but just switch to it.
  static Future<void> play(Song song, { bool silent = false, bool duplicate }) async {
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
        res = NativePlayer.play(copiedSong, _duplicate);
      } else {
        res = NativePlayer.setUri(copiedSong, _duplicate);
      }
      if (_duplicate && duplicate == null) {
        ContentControl.handleDuplicate(song);
      }
      await res;
    } on PlatformException catch (e) {
      if (e.code == 'error') {
        if (e.message == NativePlayerErrors.UNABLE_ACCESS_RESOURCE_ERROR) {
          final message = getl10n(AppRouter.instance.navigatorKey.currentContext).playbackErrorMessage;
          ShowFunctions.instance.showToast(msg: message,);
          // The order of these calls matters
          // Play next song after broken one
          playNext(song: song, silent: silent);
          // Remove broken song
          ContentControl.state.queues.all.removeSong(song);
          ContentControl.state.emitSongListChange();
          ContentControl.refetch<Song>();
        }
      }
    } catch (e) {
      // Other exceptions are not expected, rethrow.
      rethrow;
    }
  }

  static Future<void> resume([int songId]) async {
    return NativePlayer.resume();
  }

  static Future<void> pause() async {
    return NativePlayer.pause();
  }

  static Future<void> seek(Duration position) async {
    return NativePlayer.seek(position);
  }

  /// Seeks by [interval] forward, by default `3` seconds.
  static Future<void> fastForward([Duration interval]) async {
    if (interval == null) interval = Duration(seconds: 3);
    return NativePlayer.seek(((await position) + interval));
  }

  /// Seeks by [interval] backwards, by default `3` seconds.
  static Future<void> rewind([Duration interval]) async {
    if (interval == null) interval = Duration(seconds: 3);
    return NativePlayer.seek(((await position) - interval));
  }

  static Future<void> playPause() async {
    switch (playerState) {
      case PlayerState.PLAYING:
        await pause();
        break;
      case PlayerState.PAUSED:
        await resume();
        break;
      case PlayerState.COMPLETED:
        await play(ContentControl.state.currentSong);
        break;
      default:
        throw ArgumentError('Invalid state');
    }
  }

  /// Plays the song after current, or if speceified, then after [song].
  static Future<void> playNext({ Song song, bool silent = false }) async {
    song ??= ContentControl.state.queues.current.getNextSong(
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

  /// Plays the song before current, or if speceified, then before [song].
  static Future<void> playPrev({ Song song, bool silent = false }) async {
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
  ///
  /// Opens player route.
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
        if (playerState == PlayerState.PAUSED || playerState == PlayerState.COMPLETED) {
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
  /// Always start the clicked song from the beginning.
  play,

  /// Allow play/pause on the clicked song.
  playPause
}
