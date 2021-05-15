/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

export 'content_channel.dart';
export 'content.dart';
export 'queue.dart';
export 'serialization.dart';

import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';

class _BrowseParent extends Enum {
  const _BrowseParent(String value, [this.id]) : super(value);

  /// This property is non-null for entries that have id, for currently only for albums.
  final int? id;
  bool get hasId => id != null;

  static const root = _BrowseParent('root');
  static const tracks = _BrowseParent('tracks');
  static const albums = _BrowseParent('albums');

  _BrowseParent withId(int id) {
    assert(this == albums, 'This parent cannot have id');
    return _BrowseParent(value, id); 
  }
}

class _AudioHandler extends BaseAudioHandler with SeekHandler, WidgetsBindingObserver {
  _AudioHandler() {
    _init();
  }

  bool _disposed = false;
  bool _running = false;
  MusicPlayer player = MusicPlayer.instance;
  final BehaviorSubject<void> contentChangeSubject = BehaviorSubject();

  Future<void> _init() async {
    WidgetsBinding.instance!.addObserver(this);
    
    DateTime? _lastEvent;
    player.positionStream.listen((event) {
      final now = DateTime.now();
      if (_lastEvent == null || now.difference(_lastEvent!) > const Duration(milliseconds: 1000)) {
        _lastEvent = now;
        _setState();
      }
    });
    player.playingStream.listen((playing) {
      _setState();
      _lastEvent = DateTime.now();
      if (playing)
        _running = true;
    });
    player.loopingStream.listen((event) => _setState());
    ContentControl.state.onSongChange.listen((song) {
      mediaItem.add(song.toMediaItem());
      _setState();
    });
    ContentControl.state.onContentChange.listen((_) {
      contentChangeSubject.add(null);
      queue.add(
        ContentControl.state.queues.current.songs
          .map((el) => el.toMediaItem())
          .toList());
      _setState();
    });
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance!.removeObserver(this);
  }

  
  T _parentWithIdPick<T>({ required T albums }) {
    assert(parent.hasId);
    switch(parent.value) {
      case 'albums':
        return albums;
      default:
        throw UnimplementedError();
    }
  }

  void _handleMediaItemChange() {
    if (!parent.hasId) {
      ContentControl.resetQueue();
    } else {
      _parentWithIdPick<VoidCallback>(
        albums: () {
          final album = ContentControl.state.albums[parent.id!];
          if (album != null) {
            ContentControl.setOriginQueue(origin: album, songs: album.songs);
          }
        },
      )();
    }
  }

  @override
  Future<void> prepare() {
    return player.setSong(ContentControl.state.currentSong);
  }

  @override
  Future<void> prepareFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    _handleMediaItemChange();
    final song = ContentControl.state.allSongs.byId.get(int.parse(mediaId));
    if (song != null) {
      await player.setSong(song);
    }
  }

  @override
  Future<void> prepareFromSearch(String query, [Map<String, dynamic>? extras]) async {
    final songs = ContentControl.search<Song>(query);
    if (songs.isNotEmpty) {
      ContentControl.setSearchedQueue(query, songs);
      await player.setSong(ContentControl.state.allSongs.byId.get(songs[0].id));
    }
  }

  @override
  Future<void> prepareFromUri(Uri uri, [Map<String, dynamic>? extras]) {
    // TODO: implement prepareFromUri
    throw UnimplementedError();
    return super.prepareFromUri(uri, extras);
  }

  @override
  Future<void> play() {
    return player.play();
  }

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    _handleMediaItemChange();
    final song = ContentControl.state.allSongs.byId.get(int.parse(mediaId));
    if (song != null) {
      await player.setSong(song);
      await player.play();
    }
  }

  @override
  Future<void> playFromSearch(String query, [Map<String, dynamic>? extras]) async {
    final songs = ContentControl.search<Song>(query);
    if (songs.isNotEmpty) {
      ContentControl.setSearchedQueue(query, songs);
      await player.setSong(ContentControl.state.allSongs.byId.get(songs[0].id));
      await player.play();
    }
  }

  @override
  Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) {
    // TODO: implement playFromUri
    throw UnimplementedError();
    return super.playFromUri(uri, extras);
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    final song = ContentControl.state.allSongs.byId.get(int.parse(mediaItem.id));
    if (song != null) {
      await player.setSong(song);
      await player.play();
    }
  }

  @override
  Future<void> pause() => player.pause();

  Timer? hookTimer;
  int hookPressedCount = 0;

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    switch (button) {
      case MediaButton.media:
        hookPressedCount += 1;
        hookTimer ??= Timer(const Duration(milliseconds: 600), () {
          switch (hookPressedCount) {
            case 1: player.playPause(); break;
            case 2: player.playNext(); break;
            case 3:
            default: player.playPrev(); break;
          }
          hookPressedCount = 0;
          hookTimer = null;
        });
        break;
      case MediaButton.next:
        await skipToNext();
        break;
      case MediaButton.previous:
        await skipToPrevious();
        break;
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    // TODO: currently stop seeks to the beginning, use stop when https://github.com/ryanheise/just_audio/issues/366 is resolved
    // await player.stop();
    await player.pause();
    await super.stop();
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final song = ContentControl.state.allSongs.byId.get(int.parse(mediaItem.id));
    if (song != null) {
      ContentControl.addToQueue([song]);
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final songs = mediaItems.map((mediaItem) {
      return ContentControl.state.allSongs.byId.get(int.parse(mediaItem.id))!;
    });
    if (songs.isNotEmpty) {
      ContentControl.addToQueue(songs.toList());
    }
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    final song = ContentControl.state.allSongs.byId.get(int.parse(mediaItem.id));
    if (song != null) {
      ContentControl.insertToQueue(index, song);
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    if (queue.isNotEmpty) {
      final songs = queue.map((el) {
        return ContentControl.state.allSongs.byId.get(int.parse(el.id))!;
      }).toList();
      ContentControl.setQueue(
        type: QueueType.arbitrary,
        shuffled: false,
        songs: songs,
      );
      if (!songs.contains(ContentControl.state.currentSong)) {
        MusicPlayer.instance.setSong(songs[0]);
      }
    }
  }

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) {
    // TODO: implement updateMediaItem
    throw UnimplementedError();
    return super.updateMediaItem(mediaItem);
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    ContentControl.removeFromQueue(
      ContentControl.state.allSongs.byId.get(int.parse(mediaItem.id))!,
    );
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    ContentControl.removeFromQueueAt(index);
  }

  @override
  Future<void> skipToPrevious() {
    return player.playPrev();
  }

  @override
  Future<void> skipToNext() {
    return player.playNext();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final queue = ContentControl.state.queues.current;
    if (index >= 0 && index < queue.length) {
      await player.setSong(queue.songs[index]);
      await play();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await player.seek(position);
    _setState();
  }

  @override
  Future<void> setRating(Rating rating, Map? extras) {
    // TODO: implement setRating
    throw UnimplementedError();
    return super.setRating(rating, extras);
  }

  @override
  Future<void> setCaptioningEnabled(bool enabled) {
    // TODO: implement setCaptioningEnabled
    throw UnimplementedError();
    return super.setCaptioningEnabled(enabled);
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
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    ContentControl.setQueue(
      shuffled: shuffleMode == AudioServiceShuffleMode.all ||
                shuffleMode == AudioServiceShuffleMode.group,
    );
  }

  @override
  Future<void> setSpeed(double speed) {
    return player.setSpeed(speed);
  }

  /// Current parent.
  _BrowseParent parent = _BrowseParent.root;

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId, [Map<String, dynamic>? options]) async {
    if (parentMediaId != AudioService.recentRootId) {
      final id = int.tryParse(parentMediaId);
      if (id != null) {
        parent = _BrowseParent.albums.withId(id);
      } else {
        switch (parentMediaId) {
          case AudioService.browsableRootId:
            parent = _BrowseParent.root;
            break;
          case 'tracks':
            parent = _BrowseParent.tracks;
            break;
          case 'albums':
            parent = _BrowseParent.albums;
            break;
          default:
            throw ArgumentError();
        }
      }
    }
    switch (parentMediaId) {
      case AudioService.recentRootId:
        return ContentControl.state.queues.current
            .songs
            .map((song) => song.toMediaItem())
            .toList();
      case AudioService.browsableRootId:
        return [
          MediaItem(
            id: 'tracks',
            album: '',
            title: staticl10n.tracks,
            playable: false,
          ),
          MediaItem(
            id: 'albums',
            album: '',
            title: staticl10n.albums,
            playable: false,
          ),
        ];
      case 'tracks':
        return ContentControl.state.allSongs
            .songs
            .map((song) => song.toMediaItem())
            .toList();
      case 'albums':
        return ContentControl.state.albums.values
            .map((album) => album.toMediaItem())
            .toList();
      default:
        return ContentControl.state.albums[int.parse(parentMediaId)]!
            .songs
            .map((song) => song.toMediaItem())
            .toList();
    }
  }

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
    super.subscribeToChildren(parentMediaId);
    switch (parentMediaId) {
      case AudioService.recentRootId:
      default: // I have a single event stream for all updates of the  library
        return contentChangeSubject.map<Map<String, dynamic>>((_) => {});
    }
  }

  @override
  Future<MediaItem> getMediaItem(String mediaId) async {
    return ContentControl.state.allSongs.byId.get(int.parse(mediaId))!.toMediaItem();
  }

  @override
  Future<List<MediaItem>> search(String query, [Map<String, dynamic>? extras]) async {
    return ContentControl.search<Song>(query)
      .map((song) => song.toMediaItem())
      .toList();
  }

  @override
  Future<void> onNotificationAction(String action) async {
    switch (action) {
      case 'loop_on':
      case 'loop_off': return player.switchLooping();
      case 'play_prev': return player.playPrev();
      case 'pause':
      case 'play': return player.playPause();
      case 'play_next': return player.playNext();
      case 'stop': stop();
    }
  }

  @override
  Future<void> didChangeLocales(List<Locale>? locales) async {
    await AppLocalizations.init();
    mediaItem.add(ContentControl.state.currentSong.toMediaItem());
    queue.add(ContentControl.state.queues.current
      .songs
      .map((el) => el.toMediaItem())
      .toList(),
    );
  }

  @override
  void didChangePlatformBrightness() {
    _setState();
  }

  /// Broadcasts the current state to all clients.
  void _setState() {
    if (_disposed || !_running)
      return;
    final playing = player.playing;
    final l10n = staticl10n;
    final color = WidgetsBinding.instance!.window.platformBrightness == Brightness.dark
      ? 'white'
      : 'black';
    playbackState.add(playbackState.value!.copyWith(
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
          androidIcon: 'drawable/round_close_${color}_24',
          label: l10n.stop,
          action: 'stop',
        ),
      ],
      systemActions: const {
        MediaAction.stop,
        MediaAction.pause,
        MediaAction.play,
        MediaAction.rewind,
        MediaAction.skipToPrevious,
        MediaAction.skipToNext,
        MediaAction.fastForward,
        // MediaAction.setRating,
        MediaAction.seek,
        MediaAction.playPause,
        MediaAction.playFromMediaId,
        MediaAction.playFromSearch,
        MediaAction.skipToQueueItem,
        // MediaAction.playFromUri,
        MediaAction.prepare,
        MediaAction.prepareFromMediaId,
        MediaAction.prepareFromSearch,
        // MediaAction.prepareFromUri,
        MediaAction.setRepeatMode,
        // MediaAction.unused_1,
        // MediaAction.unused_2,
        MediaAction.setShuffleMode,
        MediaAction.seekBackward,
        MediaAction.seekForward,
      },
      androidCompactActionIndices: const [1, 2, 3],
      repeatMode: player.looping
        ? AudioServiceRepeatMode.one
        : AudioServiceRepeatMode.all,
      shuffleMode: ContentControl.state.queues.shuffled
        ? AudioServiceShuffleMode.all
        : AudioServiceShuffleMode.none,
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[ // Excluding idle state because it makes notification to reappear.
        player.processingState == ProcessingState.idle
          ? ProcessingState.loading
          : player.processingState
      ],
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
  static MusicPlayer? _instance;
  static MusicPlayer get instance {
    return _instance ??= MusicPlayer._();
  }

  static _AudioHandler? _handler;

  /// Updates service state media item.
  void updateServiceMediaItem() {
    final song = ContentControl.state.currentSongNullable;
    if (song != null && _handler!._running) {
      _handler!.mediaItem.add(song.toMediaItem());
    }
  }

  Future<void> init() async {
    await restoreLastSong();
    _handler ??= await AudioService.init(builder: () {
        return _AudioHandler();
      },
      config: AudioServiceConfig(
        androidResumeOnClick: true,
        androidNotificationChannelName: staticl10n.playback,
        androidNotificationChannelDescription: staticl10n.playbackControls,
        // notificationColor,
        androidNotificationIcon: 'drawable/round_music_note_white_48',
        androidShowNotificationBadge: false,
        androidNotificationClickStartsActivity: true,
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: true,
        // artDownscaleWidth,
        // artDownscaleHeight,
        fastForwardInterval: const Duration(seconds: 5),
        rewindInterval: const Duration(seconds: 5),
        androidEnableQueue: true,
        preloadArtwork: false,
        // androidBrowsableRootExtras,
      ),
    );

    processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // Play next track if not in loop mode, in loop mode this event is not triggered.
        playNext();
      }
    });

    positionStream.listen((position) { 
      Prefs.songPositionInt.set(position.inSeconds);
    });

    // Restore from prefs.
    await Future.wait([
      seek(Duration(seconds: await Prefs.songPositionInt.get())),
      setLoopMode(await Prefs.loopModeBool.get()
        ? LoopMode.one
        : LoopMode.off),
    ]);
  }

  @override
  Future<void> dispose() {
    _instance = null;
    _handler?.stop();
    return super.dispose();
  }

  /// Function that fires right after json has fetched and when initial songs fetch has done.
  ///
  /// Its main purpose to setup player to work with queues.
  Future<void> restoreLastSong() async {
    final current = ContentControl.state.queues.current;
    // songsEmpty condition is here to avoid errors when trying to get first song index
    if (current.isNotEmpty) {
      final songId = await Prefs.songIdInt.get();
      await setSong(songId == null
        ? current.songs[0]
        : current.byId.get(songId) ?? current.songs[0]);
    }
  }

  bool get looping => loopMode == LoopMode.one;
  Stream<bool> get loopingStream => loopModeStream.map((event) => event == LoopMode.one);

  @override
  Duration get duration => Duration(milliseconds: ContentControl.state.currentSong.duration);

  @override
  Future<void> setLoopMode(LoopMode mode) async {
    if (mode == LoopMode.all) {
      mode = LoopMode.off;
    }
    await super.setLoopMode(mode);
    Prefs.loopModeBool.set(looping);
  }

  /// Switches the [looping].
  Future<void> switchLooping() async {
    return setLoopMode(looping ? LoopMode.off : LoopMode.one);
  }

  /// Prepare the [song] to be played.
  Future<void> setSong(Song? song, { bool fromBeginning = false}) async {
    song ??= ContentControl.state.allSongs.songs[0];
    ContentControl.state.changeSong(song);
    try {
      await setAudioSource(
        ProgressiveAudioSource(Uri.parse(song.contentUri)),
        initialPosition: fromBeginning ? const Duration() : null,
      );
    } catch (e) {
      if (e is PlayerInterruptedException) {

      } else if (e is PlayerException) {
        final message = getl10n(AppRouter.instance.navigatorKey.currentContext!).playbackErrorMessage;
        ShowFunctions.instance.showToast(msg: message);
        playNext(song: song);
        ContentControl.state.allSongs.remove(song);
        ContentControl.refetch<Song>();
      } else {
        // Other exceptions are not expected, rethrow.
        rethrow;
      }
    }
  }

  /// The [index] parameter is made no-op.
  @override
  Future<void> seek(Duration? position, {void index}) async {
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
  Future<void> playNext({ Song? song }) async {
    song = ContentControl.state.queues.current.getNext(
      song ?? ContentControl.state.currentSong,
    );
    if (song != null) {
      await setSong(song, fromBeginning: true);
      await play();
    } else {
      final songs = ContentControl.state.allSongs.songs;
      if (songs.isNotEmpty) {
        song = songs[0];
        await setSong(song, fromBeginning: true);
        await play();
      }
    }
  }

  /// Plays the song before current, or if speceified, then before [song].
  Future<void> playPrev({ Song? song }) async {
    song = ContentControl.state.queues.current.getPrev(
      song ?? ContentControl.state.currentSong,
    );
    if (song != null) {
      await setSong(song, fromBeginning: true);
      await play();
    } else {
      final songs = ContentControl.state.allSongs.songs;
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
    if (behavior == SongClickBehavior.play) {
      playerRouteController.open();
      await setSong(clickedSong, fromBeginning: true);
      await play();
    } else {
      if (clickedSong == ContentControl.state.currentSong) {
        if (!playing) {
          playerRouteController.open();
          await play();
        } else {
          await pause();
        }
      } else {
        playerRouteController.open();
        await setSong(clickedSong, fromBeginning: true);
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
