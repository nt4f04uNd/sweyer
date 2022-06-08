export 'backend.dart';
export 'content_channel.dart';
export 'content.dart';
export 'favorites.dart';
export 'media_store_content_observer.dart';
export 'playback.dart';
export 'queue.dart';
export 'serialization.dart';

import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Represents the path in browsed library.
///
/// There may be:
/// * nested paths, like [albums] - which can have an [id]
/// * and not nested paths - like [songs], which just displays all songs
class _BrowseParent extends Enum {
  const _BrowseParent(String value, {this.id, required this.nested}) : super(value);

  final bool nested;

  /// This property is non-null for entries that have id, for currently only for albums.
  final int? id;
  bool get hasId => id != null;

  /// Shows all other parents.
  static const root = _BrowseParent('root', nested: false);

  /// Path for all songs.
  static const songs = _BrowseParent('songs', nested: false);

  /// Path for all albums.
  static const albums = _BrowseParent('albums', nested: true);

  /// Path for all playlists.
  static const playlists = _BrowseParent('playlists', nested: true);

  /// Path for all artists.
  static const artists = _BrowseParent('artists', nested: true);

  _BrowseParent withId(int id) {
    assert(nested, "This parent cannot have and id, because it's not nested");
    return _BrowseParent(value, id: id, nested: false); 
  }
}

class _BrowserParentProvider {
  /// Current parent.
  _BrowseParent _parent = _BrowseParent.root;
  _BrowseParent get parent => _parent;

  /// Handles [AudioHandler.getChildren] call.
  List<MediaItem> handleGetChildren(String parentMediaId) {
    final id = int.tryParse(parentMediaId);
    if (id != null) {
        _parent = _parent.withId(id);
    } else {
      switch (parentMediaId) {
        case 'root':
          _parent = _BrowseParent.root; break;
        case 'songs':
          _parent = _BrowseParent.songs; break;
        case 'albums':
          _parent = _BrowseParent.albums; break;
        case 'playlists':
          _parent = _BrowseParent.playlists; break;
        case 'artists':
          _parent = _BrowseParent.artists; break;
      }
    }

    switch (parentMediaId) {
      case AudioService.recentRootId:
        return QueueControl.instance.state.current
          .songs
          .map((song) => song.toMediaItem())
          .toList();
      case 'root':
        return [
          MediaItem(
            id: _BrowseParent.songs.value,
            album: '',
            title: staticl10n.contents<Song>(),
            playable: false,
          ),
          MediaItem(
            id: _BrowseParent.albums.value,
            album: '',
            title: staticl10n.contents<Album>(),
            playable: false,
          ),
          MediaItem(
            id: _BrowseParent.playlists.value,
            album: '',
            title: staticl10n.contents<Playlist>(),
            playable: false,
          ),
          MediaItem(
            id: _BrowseParent.artists.value,
            album: '',
            title: staticl10n.contents<Artist>(),
            playable: false,
          ),
        ];
      case 'songs':
        return ContentControl.instance.getContent<Song>()
          .map((el) => el.toMediaItem())
          .toList();
      case 'albums':
        return ContentControl.instance.getContent<Album>()
          .map((el) => el.toMediaItem())
          .toList();
      case 'playlists':
        return ContentControl.instance.getContent<Playlist>()
          .map((el) => el.toMediaItem())
          .toList();
      case 'artists':
        return ContentControl.instance.getContent<Artist>()
          .map((el) => el.toMediaItem())
          .toList();
      default:
        if (id == null) {
          throw StateError('');
        }
        switch (_parent.value) {
          case 'albums':
            return ContentControl.instance.getContentById<Album>(id)
              !.songs
              .map((song) => song.toMediaItem())
              .toList();
          case 'playlists':
            return ContentControl.instance.getContentById<Playlist>(id)
              !.songs
              .map((song) => song.toMediaItem())
              .toList();
          case 'artists':
            return ContentControl.instance.getContentById<Artist>(id)
              !.songs
              .map((song) => song.toMediaItem())
              .toList();
          default:
            throw UnimplementedError();
        }
    }
  }

  /// Updates the queue.
  /// Should be called when media item changes.
  void handleMediaItemChange() {
    if (!parent.hasId) {
      QueueControl.instance.resetQueue();
    } else {
      switch (parent.value) {
        case 'albums':
          final album = ContentControl.instance.getContentById<Album>(parent.id!);
          if (album != null) {
            QueueControl.instance.setOriginQueue(origin: album, songs: album.songs);
          }
          break;
        case 'playlists':
          final playlist = ContentControl.instance.getContentById<Playlist>(parent.id!);
          if (playlist != null) {
            QueueControl.instance.setOriginQueue(origin: playlist, songs: playlist.songs);
          }
          break;
        case 'artists':
          final artist = ContentControl.instance.getContentById<Artist>(parent.id!);
          if (artist != null) {
            QueueControl.instance.setOriginQueue(origin: artist, songs: artist.songs);
          }
          break;
        default:
          throw UnimplementedError();
      }
    }
  }
}

@visibleForTesting
class AudioHandler extends BaseAudioHandler with SeekHandler, WidgetsBindingObserver {
  AudioHandler(MusicPlayer player) {
    _init(player);
  }

  bool _disposed = false;
  @visibleForTesting
  bool running = false;
  late MusicPlayer player;
  late StreamSubscription playbackSubscriber;
  late StreamSubscription queueSubscriber;

  void _init(MusicPlayer player) {
    _disposed = false;
    this.player = player;
    WidgetsBinding.instance!.addObserver(this);
    
    DateTime? _lastEvent;
    player.positionStream.listen((event) {
      final now = clock.now();
      if (_lastEvent == null || now.difference(_lastEvent!) > const Duration(milliseconds: 1000)) {
        _lastEvent = now;
        _setState();
      }
    });
    player.playingStream.listen((playing) {
      _setState();
      _lastEvent = clock.now();
      if (playing)
        running = true;
    });
    player.loopingStream.listen((event) => _setState());
    playbackSubscriber = PlaybackControl.instance.onSongChange.listen((song) {
      mediaItem.add(song.toMediaItem());
      _setState();
    });
    queueSubscriber = QueueControl.instance.onQueueChanged.listen((_) {
      queue.add(
        QueueControl.instance.state.current.songs
          .map((el) => el.toMediaItem())
          .toList(),
      );
      _setState();
    });
  }

  void dispose() {
    _disposed = true;
    stop();
    playbackSubscriber.cancel();
    queueSubscriber.cancel();
    WidgetsBinding.instance!.removeObserver(this);
  }

  @override
  Future<void> prepare() {
    return player.setSong(PlaybackControl.instance.currentSong);
  }

  @override
  Future<void> prepareFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    parentProvider.handleMediaItemChange();
    final song = ContentControl.instance.state.allSongs.byId.get(int.parse(mediaId));
    if (song != null) {
      await player.setSong(song);
    }
  }

  @override
  Future<void> prepareFromSearch(String query, [Map<String, dynamic>? extras]) async {
    final songs = ContentControl.instance.search<Song>(query);
    if (songs.isNotEmpty) {
      QueueControl.instance.setSearchedQueue(query, songs);
      await player.setSong(ContentControl.instance.state.allSongs.byId.get(songs[0].id));
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
    parentProvider.handleMediaItemChange();
    final song = ContentControl.instance.state.allSongs.byId.get(int.parse(mediaId));
    if (song != null) {
      await player.setSong(song);
      await player.play();
    }
  }

  @override
  Future<void> playFromSearch(String query, [Map<String, dynamic>? extras]) async {
    final songs = ContentControl.instance.search<Song>(query);
    if (songs.isNotEmpty) {
      QueueControl.instance.setSearchedQueue(query, songs);
      await player.setSong(ContentControl.instance.state.allSongs.byId.get(songs[0].id));
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
    final song = ContentControl.instance.state.allSongs.byId.get(int.parse(mediaItem.id));
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
    running = false;
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final song = ContentControl.instance.state.allSongs.byId.get(int.parse(mediaItem.id));
    if (song != null) {
      QueueControl.instance.addToQueue([song]);
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final songs = mediaItems.map((mediaItem) {
      return ContentControl.instance.state.allSongs.byId.get(int.parse(mediaItem.id))!;
    });
    if (songs.isNotEmpty) {
      QueueControl.instance.addToQueue(songs.toList());
    }
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    final song = ContentControl.instance.state.allSongs.byId.get(int.parse(mediaItem.id));
    if (song != null) {
      QueueControl.instance.insertToQueue(index, [song]);
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    if (queue.isNotEmpty) {
      final songs = queue.map((el) {
        return ContentControl.instance.state.allSongs.byId.get(int.parse(el.id))!;
      }).toList();
      QueueControl.instance.setQueue(
        type: QueueType.arbitrary,
        shuffled: false,
        songs: songs,
      );
      if (!songs.contains(PlaybackControl.instance.currentSong)) {
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
    QueueControl.instance.removeFromQueue(
      ContentControl.instance.state.allSongs.byId.get(int.parse(mediaItem.id))!,
    );
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    QueueControl.instance.removeFromQueueAt(index);
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
    final queue = QueueControl.instance.state.current;
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
    QueueControl.instance.setQueue(
      shuffled: shuffleMode == AudioServiceShuffleMode.all ||
                shuffleMode == AudioServiceShuffleMode.group,
    );
  }

  @override
  Future<void> setSpeed(double speed) {
    return player.setSpeed(speed);
  }

  final parentProvider = _BrowserParentProvider();

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId, [Map<String, dynamic>? options]) async {
    return parentProvider.handleGetChildren(parentMediaId);
  }

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
    super.subscribeToChildren(parentMediaId);
    switch (parentMediaId) {
      case AudioService.recentRootId:
        return QueueControl.instance.onQueueChanged
          .map<Map<String, dynamic>>((_) => {})
          .shareValue();
      default: // I have a single event stream for all updates of the library
        return ContentControl.instance.onContentChange
          .map<Map<String, dynamic>>((_) => {})
          .shareValue();
    }
  }

  @override
  Future<MediaItem> getMediaItem(String mediaId) async {
    return ContentControl.instance.state.allSongs.byId.get(int.parse(mediaId))!.toMediaItem();
  }

  @override
  Future<List<MediaItem>> search(String query, [Map<String, dynamic>? extras]) async {
    return ContentControl.instance.search<Song>(query)
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
      case 'stop': return stop();
      default: throw UnimplementedError();
    }
  }

  @override
  Future<void> didChangeLocales(List<Locale>? locales) async {
    mediaItem.add(PlaybackControl.instance.currentSong.toMediaItem());
    queue.add(QueueControl.instance.state.current
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
    if (_disposed || !running)
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
          androidIcon: 'drawable/round_stop_${color}_24',
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
      shuffleMode: QueueControl.instance.state.shuffled
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
      queueIndex: PlaybackControl.instance.currentSongIndex,
    ));
  }
}

/// Player that plays the content provided by [ContentControl].
class MusicPlayer extends AudioPlayer {
  MusicPlayer._();
  static MusicPlayer? _instance;
  static MusicPlayer get instance {
    return _instance ??= MusicPlayer._();
  }

  @visibleForTesting
  static AudioHandler? handler;

  /// Updates service state media item.
  void updateServiceMediaItem() {
    final song = PlaybackControl.instance.currentSongNullable;
    if (song != null && handler!.running) {
      handler!.mediaItem.add(song.toMediaItem());
    }
  }

  Future<void> init() async {
    await restoreLastSong();

    // Reinitialize the AudioHandler if it already exists. Otherwise it is
    // initialized by the AudioService. The AudioService must only ever be
    // initialized once per process, but the handler depends on the MusicPlayer,
    // which can be disposed and recreated.
    handler?._init(this);
    handler ??= await AudioService.init(builder: () {
        return AudioHandler(MusicPlayer.instance);
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
      Prefs.songPosition.set(position.inSeconds);
    });

    // Restore from prefs.
    await Future.wait([
      seek(Duration(seconds: Prefs.songPosition.get())),
      setLoopMode(Prefs.loopMode.get()
        ? LoopMode.one
        : LoopMode.off),
    ]);
  }

  @override
  Future<void> dispose() {
    _instance = null;
    handler?.dispose();
    return super.dispose();
  }

  /// Function that fires right after json has fetched and when initial songs fetch has done.
  ///
  /// Its main purpose to setup player to work with queues.
  Future<void> restoreLastSong() async {
    final current = QueueControl.instance.state.current;
    // songsEmpty condition is here to avoid errors when trying to get first song index
    if (current.isNotEmpty) {
      final songId = Prefs.songId.get();
      await setSong(
        songId == null
          ? current.songs[0]
          : current.byId.get(songId) ?? current.songs[0],
        fromBeginningWhenSame: false,
      );
    }
  }

  bool get looping => loopMode == LoopMode.one;
  Stream<bool> get loopingStream => loopModeStream.map((event) => event == LoopMode.one);

  @override
  Duration get duration => Duration(milliseconds: PlaybackControl.instance.currentSong.duration);

  @override
  Future<void> setLoopMode(LoopMode mode) async {
    if (mode == LoopMode.all) {
      mode = LoopMode.off;
    }
    await super.setLoopMode(mode);
    Prefs.loopMode.set(looping);
  }

  /// Switches the [looping].
  Future<void> switchLooping() async {
    return setLoopMode(looping ? LoopMode.off : LoopMode.one);
  }

  /// Prepare the [song] to be played.
  /// The song position is set to 0.
  ///
  /// Calling this function with the same song will just seek to the
  /// beginning. To disable this [fromBeginningWhenSame] can be set to false.
  Future<void> setSong(Song? song, { bool fromBeginningWhenSame = true }) async {
    song ??= ContentControl.instance.state.allSongs.songs[0];
    final previousCurrentSong = PlaybackControl.instance.currentSongNullable;
    PlaybackControl.instance.changeSong(song);
    if (previousCurrentSong == PlaybackControl.instance.currentSong) {
      if (fromBeginningWhenSame)
        await seek(Duration.zero);
      return;
    }
    try {
      await setAudioSource(
        ProgressiveAudioSource(Uri.parse(song.contentUri)),
      );
    } catch (e) {
      if (e is PlayerInterruptedException || e is PlatformException && e.code == 'abort') {
        // Do nothing
      } else if (e is PlayerException) {
        final message = getl10n(AppRouter.instance.navigatorKey.currentContext!).playbackError;
        ShowFunctions.instance.showToast(msg: message);
        playNext(song: song);
        ContentControl.instance.state.allSongs.remove(song);
        ContentControl.instance.refetch<Song>();
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
    song = QueueControl.instance.state.current.getNext(
      song ?? PlaybackControl.instance.currentSong,
    );
    if (song != null) {
      await setSong(song);
      await play();
    } else {
      final songs = ContentControl.instance.state.allSongs.songs;
      if (songs.isNotEmpty) {
        song = songs[0];
        await setSong(song);
        await play();
      }
    }
  }

  /// Plays the song before current, or if speceified, then before [song].
  Future<void> playPrev({ Song? song }) async {
    song = QueueControl.instance.state.current.getPrev(
      song ?? PlaybackControl.instance.currentSong,
    );
    if (song != null) {
      await setSong(song);
      await play();
    } else {
      final songs = ContentControl.instance.state.allSongs.songs;
      if (songs.isNotEmpty) {
        song = songs[0];
        await setSong(song);
        await play();
      }
    }
  }
}
