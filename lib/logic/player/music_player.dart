/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

export 'content.dart';
export 'queue.dart';
export 'serialization.dart';

import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';

class _AudioHandler extends BaseAudioHandler with SeekHandler, QueueHandler, WidgetsBindingObserver {
  _AudioHandler() {
    _init();
  }

  final MusicPlayer player = MusicPlayer.instance;

  Future<void> _init() async {
    WidgetsBinding.instance.addObserver(this);
    queue.add(ContentControl.state.queues.current.toMediaItems());
    player.loopingStream.listen((event) => _setState());
    player.playingStream.listen((event) => _setState());
    ContentControl.state.onSongChange.listen((song) {
      mediaItem.add(song.toMediaItem());
      _setState();
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId, [Map<String, dynamic> options]) async {
    switch (parentMediaId) {
      case AudioService.recentRootId:
      default:
        // Allow client to browse the media library.
        print('### get $parentMediaId children');
        return ContentControl.state.queues.current.toMediaItems();
    }
  }

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
    switch (parentMediaId) {
      case AudioService.recentRootId:
      default: // In all cases return current queue.
        return ContentControl.state.onContentChange.map((_) => {}) as ValueStream<Map<String, dynamic>>;
    }
  }

  @override
  Future<MediaItem> getMediaItem(String mediaId) async => null;

  @override
  Future<void> skipToQueueItem(int index) async {
    final queue = ContentControl.state.queues.current;
    if (index < 0 || index > queue.length)
      return;
    await player.setSong(queue.songs[index]);
    await player.play();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) {
    if (repeatMode == AudioServiceRepeatMode.one) {
      return player.setLoopMode(LoopMode.one);
    } else {
      return player.setLoopMode(LoopMode.all);
    }
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    // TODO: currently stop seeks to the beginning, use stop when https://github.com/ryanheise/just_audio/issues/366 is resolved
    // await player.stop();
    await player.pause();
    await super.stop();
  }

  @override
  void didChangeLocales(List<Locale> locales) {
    _setState();
  }

  @override
  void didChangePlatformBrightness() {
    _setState();
  }

  @override
  Future<void> onNotificationAction(String action) async {
    switch (action) {
      case 'loop_on':
      case 'loop_off': return player.switchLooping();
      case 'play_prev': return player.playPrev();
      case 'pause': return player.pause();
      case 'play': return player.play();
      case 'play_next': return player.playNext();
      case 'stop': stop();
    }
  }

  /// Broadcasts the current state to all clients.
  void _setState() {
    final playing = player.playing;
    final l10n = staticl10n;
    final color = WidgetsBinding.instance.window.platformBrightness == Brightness.dark ? 'white' : 'black';
    playbackState.add(playbackState.value.copyWith(
      controls: [
        // TODO: currently using custom API from my fork, see https://github.com/ryanheise/audio_service/issues/633
        if (player.looping)
          MediaControl(
            androidIcon: 'drawable/round_loop_on_${color}_24',
            label: l10n.loopOn,
            action: 'loop_on',
          )
        else
          MediaControl(
            androidIcon: 'drawable/round_loop_${color}_24',
            label: l10n.loopOff,
            action:'loop_off',
          ),
        MediaControl(
          androidIcon: 'drawable/round_skip_previous_${color}_36',
          label: l10n.previous,
          action: 'play_prev',
        ),
        if (playing)
          MediaControl(
            androidIcon: 'drawable/round_pause_${color}_36',
            label: l10n.pause,
            action: 'pause',
          )
        else
          MediaControl(
            androidIcon: 'drawable/round_play_arrow_${color}_36',
            label: l10n.play,
            action: 'play',
          ),
        MediaControl(
          androidIcon: 'drawable/round_skip_next_${color}_36',
          label: l10n.next,
          action: 'play_next',
        ),
        MediaControl(
          androidIcon: 'drawable/round_close_next_${color}_36',
          label: l10n.stop,
          action: 'stop',
        ),
      ],
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: [1, 2, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState],
      playing: playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: ContentControl.state.currentSongIndex,
    ));
  }
}

/// Player that plays the content provided by provided [ContentControl].
class MusicPlayer extends AudioPlayer {
  MusicPlayer._();
  static MusicPlayer _instance;
  static MusicPlayer get instance {
    return _instance ??= MusicPlayer._();
  }

  static _AudioHandler _handler;

  bool get looping => loopMode == LoopMode.all;
  Stream<bool> get loopingStream => loopModeStream.map((event) => event == LoopMode.all);

  @override
  Duration get duration => Duration(milliseconds: ContentControl.state.currentSong.duration);

  Future<void> init() async {
    await restoreLastSong();
    _handler ??= await AudioService.init(builder: () {
      return _AudioHandler();
    });

    processingStateStream.listen((state) {
      if (state == ProcessingState.completed &&
          loopMode == LoopMode.off) { // TODO: check if i need this condition
        // Play next track if not in loop mode, in loop mode this event is not triggered.
        playNext();
      }
    });

    // Restring seek from prefs.
    final songPosition = await Prefs.songPositionInt.get();
    await seek(Duration(seconds: songPosition));
  }

  @override
  Future<void> dispose() {
    _instance = null;
    _handler?.stop();
    _handler?.dispose();
    return super.dispose();
  }

  /// Function that fires right after json has fetched and when initial songs fetch has done.
  ///
  /// Its main purpose to setup player to work with queues.
  Future<void> restoreLastSong() async {
    final current = ContentControl.state.queues.current;
    // songsEmpty condition is here to avoid errors when trying to get first song index
    if (current.isNotEmpty) {
      final int songId = await Prefs.songIdInt.get();
      await setSong(songId == null
        ? current.songs[0]
        : current.byId.getSong(songId) ?? current.songs[0]);
    }
  }

  /// Switches the [looping].
  Future<void> switchLooping() async {
    return setLoopMode(looping ? LoopMode.off : LoopMode.all);
  }

  static bool _hasDuplicates(Song song) {
    final queues = ContentControl.state.queues;
    return (queues.type != QueueType.all || queues.modified) &&
            queues.current.songs.where((el) => el.id == song.id).length > 1;
  }

  /// Prepare the [song] to be played.
  Future<void> setSong(Song song, { bool fromBeginning = false, bool duplicate }) async {
    song ??= ContentControl.state.queues.all.songs[0];
    ContentControl.state.changeSong(song);
    try {
      final _duplicate = duplicate ?? _hasDuplicates(song);
      if (_duplicate && duplicate == null) {
        ContentControl.handleDuplicate(song);
      }
      // await setUrl('https://s3.amazonaws.com/scifri-segments/scifri201711241.mp');
      await setAudioSource(
        ProgressiveAudioSource(
          Uri.parse('content://media/external/audio/media/${song.sourceId}')
          // Uri.parse('https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3')
        ),
        initialPosition: fromBeginning ? const Duration() : null,
      );
    } on PlatformException catch (e) {
      // TODO: handle errors
      // if (e.code == 'error') {
      //   if (e.message == NativePlayerErrors.UNABLE_ACCESS_RESOURCE_ERROR) {
      //     final message = getl10n(AppRouter.instance.navigatorKey.currentContext).playbackErrorMessage;
      //     ShowFunctions.instance.showToast(msg: message,);
      //     // The order of these calls matters
      //     // Play next song after broken one
      //     playNext(song: song, silent: silent);
      //     // Remove broken song
      //     ContentControl.state.queues.all.removeSong(song);
      //     ContentControl.state.emitSongListChange();
      //     ContentControl.refetch<Song>();
      //   }
      // }
    } catch (e) {
      // Other exceptions are not expected, rethrow.
      rethrow;
    }
  }

  /// The [index] parameter is made no-op.
  @override
  Future<void> seek(Duration position, {void index}) async {
    return super.seek(position);
  }

  Future<void> playPause() async {
    if (playing) {
      return pause();
    } else {
      return play();
    }
  }

  /// Plays the song after current, or if speceified, then after [song].
  Future<void> playNext({ Song song }) async {
    song ??= ContentControl.state.queues.current.getNextSong(
      song ?? ContentControl.state.currentSong,
    );
    if (song != null) {
      await setSong(song, fromBeginning: true);
      await play();
    } else {
      final songs = ContentControl.state.queues.all.songs;
      if (songs.isNotEmpty) {
        song = songs[0];
        await setSong(song, fromBeginning: true);
        await play();
      }
    }
  }

  /// Plays the song before current, or if speceified, then before [song].
  Future<void> playPrev({ Song song }) async {
    song ??= ContentControl.state.queues.current.getPrevSong(
      song ?? ContentControl.state.currentSong,
    );
    if (song != null) {
      await setSong(song, fromBeginning: true);
      await play();
    } else {
      final songs = ContentControl.state.queues.all.songs;
      if (songs.isNotEmpty) {
        song = songs[0];
        await setSong(song, fromBeginning: true);
        await play();
      }
    }
  }

  /// Function that handles click on track tile.
  ///
  /// Opens player route.
  Future<void> handleSongClick(
    BuildContext context,
    Song clickedSong, {
    SongClickBehavior behavior = SongClickBehavior.play,
  }) async {
    final duplicate = _hasDuplicates(clickedSong);
    bool isSame;
    if (duplicate) {
      ContentControl.handleDuplicate(clickedSong);
      isSame = false;
    }
    isSame = clickedSong == ContentControl.state.currentSong;
    if (behavior == SongClickBehavior.play) {
      getPlayerRouteControllerProvider(context).controller.open();
      await setSong(clickedSong, duplicate: duplicate, fromBeginning: true);
      await play();
    } else {
      if (isSame) {
        if (!playing) {
          getPlayerRouteControllerProvider(context).controller.open();
          await play();
        } else {
          await pause();
        }
      } else {
        getPlayerRouteControllerProvider(context).controller.open();
        await setSong(clickedSong, duplicate: duplicate , fromBeginning: true);
        await play();
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
