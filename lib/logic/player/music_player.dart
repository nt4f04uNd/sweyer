/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

export 'playlist.dart';
export 'serialization.dart';
export 'content.dart';
export 'models/models.dart';

import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';

class _AudioHandler extends BaseAudioHandler {
  _AudioHandler() {
    _init();
  }

  final MusicPlayer player = MusicPlayer.instance;

  Future<void> _init() async {
    // Load and broadcast the queue
    queue.add(ContentControl.state.queues.current.toMediaItems());
    // Broadcast media item changes.
    ContentControl.state.onSongChange.listen((song) {
      mediaItem.add(song.toMediaItem());
    });
    // Propagate all events from the audio player to AudioService clients.
    player.playbackEventStream.listen(_broadcastState);
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
        return ContentControl.state.onSongListChange.map((_) => {}) as ValueStream<Map<String, dynamic>>;
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final queue = ContentControl.state.queues.current;
    if (index < 0 || index > queue.length)
      return;
    await player.setSong(queue.songs[index]);
    await player.play();
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  /// Broadcasts the current state to all clients.
  void _broadcastState(PlaybackEvent event) {
    final playing = player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: [0, 1, 3],
      processingState: {
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
      queueIndex: event.currentIndex,
    ));
  }
}

class MusicPlayer extends AudioPlayer {
  MusicPlayer._();
  static final instance = MusicPlayer._();

  _AudioHandler _handler;

  bool get looping => loopMode == LoopMode.all;
  Stream<bool> get onLoopingSwitch => loopModeStream.map((event) => event == LoopMode.all);

  Future<void> init() async {
    _handler = await AudioService.init(builder: () {
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

    await restoreLastSong();
  }

  /// Function that fires right after json has fetched and when initial songs fetch has done.
  ///
  /// Its main purpose to setup player to work with queues.
  Future<void> restoreLastSong() async {
    final current = ContentControl.state.queues.current;
    // songsEmpty condition is here to avoid errors when trying to get first song index
    if (current.isNotEmpty) {
      final int songId = await Prefs.songIdIntNullable.get();
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
  Future<void> seek(Duration position, {index}) async {
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
    } else {
      isSame = clickedSong == ContentControl.state.currentSong;
    }
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
