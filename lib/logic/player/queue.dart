import 'package:collection/collection.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sweyer/sweyer.dart';

/// The type of currently playing queue.
enum QueueType {
  /// Queue of all songs.
  allSongs,

  /// Queue of all albums.
  allAlbums,

  /// Queue of all playlists.
  allPlaylists,

  /// Queue of all artistt.
  allArtists,

  /// Queue of searched tracks.
  searched,

  /// Queue that has same [SongOrigin].
  origin,

  /// Some arbitrary queue. Сannot have modified state.
  ///
  /// Made up when:
  /// * user adds a song to [persistent] queue, that’s not included in it
  /// * after restoring shuffled queue (as the info about the queue it was shuffled from is lost on app restart)
  /// * in any other ways not described yet
  arbitrary,
}

/// Class, representing a queue in application
///
/// It is array-like, as it has shuffle methods and explicit indexing.
class Queue implements _QueueOperations<Song> {
  /// Creates queue from songs list.
  Queue(this._songs) {
    byId = _QueueOperationsById(this);
  }

  /// Queue songs.
  List<Song> get songs => _songs;
  List<Song> _songs;

  /// Sets songs.
  void setSongs(List<Song> value) {
    _songs = value;
  }

  /// Provides operations on queue by [Song.id].
  late final _QueueOperationsById byId;

  /// Returns a shuffled copy of songs.
  static List<Song> shuffleSongs(List<Song> songsToShuffle) {
    final List<Song> shuffledSongs = List.from(songsToShuffle);
    shuffledSongs.shuffle();
    return shuffledSongs;
  }

  // TODO: docs
  int? _nextIndex(int index) {
    if (index < 0) {
      return null;
    }
    final nextIndex = index + 1;
    if (nextIndex >= songs.length) {
      return 0;
    }
    return nextIndex;
  }

  int? _prevIndex(int index) {
    if (index < 0) {
      return null;
    }
    final prevIndex = index - 1;
    if (prevIndex < 0) {
      return songs.length - 1;
    }
    return prevIndex;
  }

  int get length => songs.length;
  bool get isEmpty => songs.isEmpty;
  bool get isNotEmpty => songs.isNotEmpty;

  /// Clears the songs list.
  void clear() {
    songs.clear();
  }

  /// Adds the [song] (a copy of it) to a queue.
  void add(Song song) {
    songs.add(song.copyWith());
  }

  /// Inserts the [song] (a copy of it) to a given position in queue.
  void insert(int index, Song song) {
    songs.insert(index, song.copyWith());
  }

  /// Removes a song from the queue at given [index] and returns
  /// the removed object.
  Song removeAt(int index) {
    return songs.removeAt(index);
  }

  @override
  bool contains(Song song) {
    return byId.contains(song.id);
  }

  @override
  bool remove(Song song) {
    return byId.remove(song.id);
  }

  @override
  Song? get(Song song) {
    return byId.get(song.id);
  }

  @override
  int getIndex(Song song) {
    return byId.getIndex(song.id);
  }

  @override
  Song? getNext(Song song) {
    return byId.getNext(song.id);
  }

  // TODO: docs
  Song getNextAt(int index) {
    return songs[_nextIndex(index)!];
  }

  @override
  Song? getPrev(Song song) {
    return byId.getPrev(song.id);
  }

  Song getPrevAt(int index) {
    return songs[_prevIndex(index)!];
  }

  /// Searches each song of this queue in another [queue] and removes
  /// it if doesn't find it.
  void compareAndRemoveObsolete(Queue queue) {
    songs.removeWhere((song) {
      return queue.songs.firstWhereOrNull((el) => el.sourceId == song.sourceId) == null;
    });
  }
}

/// Describes generic operations on the song queue.
abstract class _QueueOperations<T> {
  /// Checks if queue contains song.
  bool contains(T arg);

  /// Removes song.
  bool remove(T arg);

  /// Retruns song.
  Song? get(T arg);

  /// Returns song index.
  int getIndex(T arg);

  /// Returns next song.
  Song? getNext(T arg);

  /// Returns prev song.
  Song? getPrev(T arg);
}

/// Implements opertions on [queue] by IDs of the [Song]s.
class _QueueOperationsById implements _QueueOperations<int> {
  const _QueueOperationsById(this.queue);
  final Queue queue;

  @override
  bool contains(int id) {
    return queue.songs.firstWhereOrNull((el) => el.id == id) != null;
  }

  @override
  bool remove(int id) {
    bool removed = false;
    queue.songs.removeWhere((el) {
      if (el.id == id) {
        removed = true;
        return true;
      }
      return false;
    });
    return removed;
  }

  @override
  Song? get(int id) {
    return queue.songs.firstWhereOrNull((el) => el.id == id);
  }

  @override
  int getIndex(int id) {
    return queue.songs.indexWhere((el) => el.id == id);
  }

  @override
  Song? getNext(int id) {
    final index = queue._nextIndex(getIndex(id));
    return index == null ? null : queue.songs[index];
  }

  @override
  Song? getPrev(int id) {
    final index = queue._prevIndex(getIndex(id));
    return index == null ? null : queue.songs[index];
  }
}

/// Enum used inside this file to use in [QueuesState._pool].
@visibleForTesting
enum PoolQueueType {
  /// Any queue type to be displayed (searched or album or etc.).
  queue,

  /// Shuffled queue always produced from the [queue].
  shuffled,
}

/// Represents the state in [QueueControl].
@visibleForTesting
class QueuesState {
  QueuesState(Map<PoolQueueType, Queue> pool) : _pool = pool;

  final Map<PoolQueueType, Queue> _pool;

  /// Actual type of the queue, that can be displayed to the user.
  QueueType get type => _type;
  QueueType _type = QueueType.allSongs;

  PoolQueueType get _internalType {
    if (shuffled) {
      return PoolQueueType.shuffled;
    }
    return PoolQueueType.queue;
  }

  Queue get current {
    final value = _pool[_internalType]!;
    assert(value.isNotEmpty, "Current queue must not be empty");
    if (value.isEmpty) {
      QueueControl.instance.resetQueue();
    }
    return _pool[_internalType]!;
  }

  Queue get _queue => _pool[PoolQueueType.queue]!;
  Queue get _shuffledQueue => _pool[PoolQueueType.shuffled]!;

  /// Current queue for [QueueType.origin].
  /// If [type] is not [QueueType.origin], will return `null`.
  SongOrigin? get origin => _origin;
  SongOrigin? _origin;

  /// A search query for [QueueType.searched].
  /// If [type] is not [QueueType.searched], will return `null`.
  String? get searchQuery => _searchQuery;
  String? _searchQuery;

  /// Whether the current queue is modified.
  ///
  /// Applied in certain conditions when user adds, removes
  /// or reorders songs in the queue.
  ///
  /// [QueueType.arbitrary] cannot be modified.
  bool get modified => _modified;
  bool _modified = false;

  /// Whether the current queue is shuffled.
  bool get shuffled => _shuffled;
  bool _shuffled = false;

  /// This is a map to store ids of duplicated songs in queue.
  ///
  /// The key is string, because [jsonEncode] and [jsonDecode] can only
  /// work with `Map<String, dynamic>`. Convertion to int doesn't seem to be a
  /// benefit, so keeping this as string.
  ///
  /// See [ContentUtils.deduplicateSong] for discussion about the
  /// logic behind this.
  IdMap idMap = {};

  /// When true, [idMap] will be saved in the next [QueueControl.setQueue] call.
  bool idMapDirty = false;
}

@visibleForTesting
class QueuesRepository {
  QueuesRepository(this._state);
  final QueuesState _state;

  Future<void> init() {
    return Future.wait([
      queue.init(),
      shuffled.init(),
      idMap.init(),
    ]);
  }

  final songOrigin = Prefs.songOrigin;
  final searchQuery = Prefs.searchQuery;
  final queueType = Prefs.queueType;
  final queueModified = Prefs.queueModified;
  final queueShuffled = Prefs.queueShuffled;

  /// Serializes [PoolQueueType.queue].
  final QueueSerializerType queue = const QueueSerializer('queue.json');

  /// Serializes [PoolQueueType.shuffled].
  final QueueSerializerType shuffled = const QueueSerializer('shuffled_queue.json');

  /// Serializes [QueuesState.idMap].
  final IdMapSerializerType idMap = const IdMapSerializer();

  Future<void> saveCurrentQueue() {
    if (_state.shuffled) {
      return Future.wait([
        queue.save(_state._queue.songs),
        shuffled.save(_state._shuffledQueue.songs),
      ]);
    }
    return queue.save(_state.current.songs);
  }

  Future<void> saveIdMap() {
    return idMap.save(_state.idMap);
  }
}

/// Controls queues state and allows to perform related actions.
class QueueControl extends Control {
  static QueueControl instance = QueueControl();

  @override
  Future<void> init() async {
    super.init();
    _onQueueChangeSubject = PublishSubject();
    await repository.init();
    await _restoreQueue();
  }

  @override
  void dispose() {
    if (!disposed.value) {
      _onQueueChangeSubject.close();
    }
    super.dispose();
  }

  @visibleForTesting
  late final repository = QueuesRepository(state);

  /// The state of the queues - themselves and meta information about them.
  final QueuesState state = QueuesState({
    PoolQueueType.queue: Queue([]),
    PoolQueueType.shuffled: Queue([]),
  });

  /// A stream of changes over the [state].
  /// Receives an event whenever [setState] is called.
  Stream<void> get onQueueChanged => _onQueueChangeSubject.stream;
  late PublishSubject<void> _onQueueChangeSubject;

  void emitQueueChange() {
    _onQueueChangeSubject.add(null);
  }

  /// Must be called before the song is instreted to the current queue,
  /// calls [ContentUtils.deduplicateSong].
  void _deduplicateSong(Song song) {
    final result = ContentUtils.deduplicateSong(
      song: song,
      list: state.current.songs,
      idMap: state.idMap,
    );
    if (result) {
      state.idMapDirty = true;
    }
  }

  /// Marks queues modified and traverses it to be unshuffled, preseving the shuffled
  /// queue contents.
  void _unshuffle() {
    setQueue(
      emitChangeEvent: false,
      modified: true,
      shuffled: false,
      songs: state._shuffled ? List.from(state._shuffledQueue.songs) : null,
    );
  }

  /// Checks if current queue is [QueueType.origin], if yes, adds this queue as origin
  /// to all its songs. This is a required action for each addition to the queue.
  void _setOrigins() {
    if (state.type == QueueType.origin) {
      final songs = state.current.songs;
      final songOrigin = state.origin!;
      for (final song in songs) {
        song.origin = songOrigin;
      }
    }
  }

  /// Checks whether the current origin contains a song.
  /// If current queue is not origin, will always return `true`.
  /// Intended to be used in queue insertion operations, see [playNext] for example.
  bool _doesOriginContain(Song song) {
    final queues = state;
    if (queues._type == QueueType.origin) {
      final currentOrigin = queues.origin!;
      final originSongs = currentOrigin.songs;
      final int index;
      if (currentOrigin is DuplicatingSongOriginMixin) {
        // Duplicating song origins should be a unique container, so that songs that are outside them
        // are considered to be not contained in them, even if they have the same source IDs.
        index = originSongs.indexWhere((el) => el.sourceId == song.sourceId && currentOrigin == song.origin);
      } else {
        index = originSongs.indexWhere((el) => el.sourceId == song.sourceId);
      }
      return index >= 0;
    }
    return true;
  }

  /// If the [song] is next (or currently playing), will duplicate it and queue it to be played next,
  /// else will move it to be next. After that it can be duplicated to be played more.
  ///
  /// Same as for [addToQueue]:
  /// * if current queue is [QueueType.origin] and the added [song] is present in it, will mark the queue as modified,
  /// else will traverse it into [QueueType.arbitrary]. All the other queues will be just marked as modified.
  /// * if current queue is shuffled, it will copy all songs (thus saving the order of shuffled songs), go back to be unshuffled,
  /// and add the [songs] there.
  void playNext(List<Song> songs) {
    assert(songs.isNotEmpty);
    final queues = state;
    // Save queue order
    _unshuffle();
    _setOrigins();
    final currentQueue = queues.current;
    if (songs.length == 1) {
      final song = songs[0];
      final currentSong = PlaybackControl.instance.currentSong;
      if (song.sourceId != currentSong.sourceId &&
          song.sourceId != currentQueue.getNext(currentSong)?.sourceId &&
          PlaybackControl.instance.currentSongIndex != currentQueue.length - 1) {
        currentQueue.remove(song);
      }
    }
    bool contains = true;
    for (int i = 0; i < songs.length; i++) {
      final song = songs[i].copyWith();
      _deduplicateSong(song);
      currentQueue.insert(PlaybackControl.instance.currentSongIndex + i + 1, song);
      if (contains) {
        contains = _doesOriginContain(song);
      }
    }
    setQueue(type: contains ? null : QueueType.arbitrary);
  }

  /// Queues the [songs] to the last position in queue.
  ///
  /// Same as for [playNext]:
  /// * if current queue is [QueueType.origin] and the added [song] is present in it, will mark the queue as modified,
  /// else will traverse it into [QueueType.arbitrary]. All the other queues will be just marked as modified.
  /// * if current queue is shuffled, it will copy all songs (thus saving the order of shuffled songs), go back to be unshuffled,
  /// and add the [songs] there.
  void addToQueue(List<Song> songs) {
    assert(songs.isNotEmpty);
    // Save queue order
    _unshuffle();
    _setOrigins();
    bool contains = true;
    for (var song in songs) {
      song = song.copyWith();
      _deduplicateSong(song);
      state.current.add(song);
      if (contains) {
        contains = _doesOriginContain(song);
      }
    }
    setQueue(type: contains ? null : QueueType.arbitrary);
  }

  /// Queues the song origin to be played next.
  ///
  /// Saves it to [Song.origin] in its items, and so when the item is played,
  /// this song origin will be also shown as playing.
  ///
  /// If currently some song origin is already playing, will first save the current queue to
  /// [Song.origin] in its items.
  ///
  /// In difference with [playNext], always traverses the playlist into [QueueType.arbitrary].
  void playOriginNext(SongOrigin origin) {
    final songs = origin.songs;
    assert(songs.isNotEmpty);
    // Save queue order
    _unshuffle();
    _setOrigins();
    final currentQueue = state.current;
    final currentIndex = PlaybackControl.instance.currentSongIndex;
    int i = 0;
    for (var song in songs) {
      song = song.copyWith();
      song.origin = origin;
      _deduplicateSong(song);
      currentQueue.insert(currentIndex + i + 1, song);
      i++;
    }
    setQueue(type: QueueType.arbitrary);
  }

  /// Queues the song origin to the last position in queue.
  ///
  /// Saves it to [Song.origin] in its items, and so when the item is played,
  /// this song origin will be also shown as playing.
  ///
  /// If currently some song origin is already playing, will first save the current queue to
  /// [Song.origin] in its items.
  ///
  /// In difference with [addToQueue], always traverses the playlist into [QueueType.arbitrary].
  void addOriginToQueue(SongOrigin origin) {
    final songs = origin.songs;
    assert(songs.isNotEmpty);
    // Save queue order
    _unshuffle();
    _setOrigins();
    for (var song in songs) {
      song = song.copyWith();
      song.origin = origin;
      _deduplicateSong(song);
      state.current.add(song);
    }
    setQueue(type: QueueType.arbitrary);
  }

  /// Inserts [songs] at [index] in the queue.
  void insertToQueue(int index, List<Song> songs) {
    // Save queue order
    _unshuffle();
    _setOrigins();
    bool contains = true;
    for (var song in songs) {
      song = song.copyWith();
      _deduplicateSong(song);
      state.current.insert(index, song);
      if (contains) {
        contains = _doesOriginContain(song);
      }
    }
    setQueue(type: contains ? null : QueueType.arbitrary);
  }

  /// Removes the [song] from the queue.
  ///
  /// If this was the last item in current queue, will:
  /// * fall back to the first song in [QueueType.all]
  /// * fall back to [QueueType.all]
  /// * stop the playback
  bool removeFromQueue(Song song) {
    final queues = state;
    final bool removed;
    if (queues.current.length == 1) {
      removed = queues.current.remove(song);
      if (removed) {
        resetQueueAsFallback();
      }
    } else {
      final current = song == PlaybackControl.instance.currentSong;
      Song? nextSong;
      if (current) {
        nextSong = state.current.getNext(song);
      }
      removed = queues.current.remove(song);
      if (removed && current) {
        MusicPlayer.instance.pause();
        MusicPlayer.instance.setSong(nextSong);
      }
      setQueue(modified: true);
    }
    return removed;
  }

  /// Removes a song at given [index] from the queue.
  ///
  /// If this was the last item in current queue, will:
  /// * fall back to the first song in [QueueType.all]
  /// * fall back to [QueueType.all]
  /// * stop the playback
  Song? removeFromQueueAt(int index) {
    final queues = state;
    final Song? song;
    if (queues.current.length == 1) {
      song = queues.current.removeAt(0);
      resetQueueAsFallback();
    } else {
      if (index == PlaybackControl.instance.currentSongIndex) {
        MusicPlayer.instance.pause();
        MusicPlayer.instance.setSong(state.current.getNextAt(index));
      }
      song = queues.current.removeAt(index);
      setQueue(modified: true);
    }
    return song;
  }

  /// Removes all items at given [indexes] from the queue.
  ///
  /// If the [indexes] list has length bigger than or equal to current queue
  /// length, will:
  /// * fall back to the first song in [QueueType.all]
  /// * fall back to [QueueType.all]
  /// * stop the playback
  ///
  /// TODO: add return value ?
  void removeAllFromQueueAt(List<int> indexes) {
    final queues = state;
    if (indexes.length >= queues.current.length) {
      resetQueueAsFallback();
    } else {
      final containsCurrent = indexes.contains(PlaybackControl.instance.currentSongIndex);
      if (containsCurrent) {
        MusicPlayer.instance.pause();
      }
      for (int i = indexes.length - 1; i >= 0; i--) {
        queues.current.removeAt(indexes[i]);
      }
      if (containsCurrent) {
        /// TODO: add to [Queue] something like relative indexing, that allows negative indexes
        /// and imporove this
        MusicPlayer.instance.setSong(state.current.songs[0]);
      }
      setQueue(modified: true);
    }
  }

  /// A shorthand for setting [QueueType.searched].
  void setSearchedQueue(String query, List<Song> songs) {
    setQueue(
      type: QueueType.searched,
      searchQuery: query,
      modified: false,
      shuffled: false,
      songs: songs,
    );
  }

  /// A shorthand for setting [QueueType.origin].
  void setOriginQueue({
    required SongOrigin origin,
    required List<Song> songs,
    bool shuffled = false,
    List<Song>? shuffledSongs,
  }) {
    if (shuffled) {
      shuffledSongs ??= Queue.shuffleSongs(songs);
    }
    setQueue(
      type: QueueType.origin,
      origin: origin,
      modified: false,
      shuffled: shuffled,
      songs: shuffledSongs ?? songs,
      shuffleFrom: songs,
    );
  }

  /// Resets queue to all songs.
  void resetQueue() {
    setQueue(
      type: QueueType.allSongs,
      modified: false,
      shuffled: false,
    );
  }

  /// Resets queue to all songs, pauses the player and sets the first song as
  /// current.
  ///
  /// This fucntion should be called if queue is found to be broken
  /// and there's no straight way to figure out where to fallback.
  void resetQueueAsFallback() {
    setQueue(
      type: QueueType.allSongs,
      modified: false,
      shuffled: false,
    );
    MusicPlayer.instance.pause();
    MusicPlayer.instance.setSong(state.current.songs[0]);
  }

  /// Sets the queue with specified [type] and other parameters.
  /// Most of the parameters are updated separately and can be omitted, unless
  /// differently specified:
  ///
  /// * [shuffled] can be used to shuffle / unshuffle the queue
  /// * [modified] can be used to mark current queue as modified
  /// * [songs] is the songs list to set to the queue.
  ///   This array will be copied (unless [copied] is true) and set
  ///   as a source to queue, that function is switching to.
  ///   For example that way when [shuffled] is `true`, this array
  ///   will be used as new queue, without being shuffled.
  /// * [shuffleFrom] is a list of songs to fall back when [shuffle]
  ///   thereafter will be set to `false`.
  ///
  ///   By default it will also be shuffled and set to shuffled queue,
  ///   unless [songs] are specified, which will override this value.
  ///
  ///   If both [songs] and [shuffleFrom] is not specified, will shuffle
  ///   from current queue.
  /// * [origin] is the song origin being set, only applied when [type] is [QueueType.origin].
  ///   When [QueueType.origin] is set and currently it's not origin, this parameter is required.
  ///   Otherwise it can be omitted and for updating other paramters only.
  ///
  ///   With playlist origin the [Playlist.idMap] will be used to update the
  ///   [ContentState.idMap].
  /// * [searchQuery] is the search query the playlist was searched by,
  ///   only applied when [type] is [QueueType.searched].
  ///   Similarly as for [origin], when [QueueType.searched] is set and currently it's not searched,
  ///   this parameter is required. Otherwise it can be omitted for updating other paramters only.
  /// * [emitChangeEvent] is whether to emit a song list change event
  /// * [setIdMapFromPlaylist] allows to configure whether to set the [Playlist.idMap]
  ///   when set [origin] is playlist. Needed to not override the map at the app start.
  /// * [save] parameter can be used to disable redundant writing to JSONs when,
  ///   for example, when we restore the queue from this exact json.
  /// * [copied] indicates that [songs] was already copied,
  ///   by default set to `false` and will copy it with [List.from]
  void setQueue({
    QueueType? type,
    bool? shuffled,
    bool? modified,
    List<Song>? songs,
    List<Song>? shuffleFrom,
    SongOrigin? origin,
    String? searchQuery,
    bool save = true,
    bool setIdMapFromPlaylist = true,
    bool copied = false,
    bool emitChangeEvent = true,
  }) {
    final queues = state;

    @pragma('vm:prefer-inline')
    List<Song> copySongs(List<Song> songs) {
      return copied ? songs : List.from(songs);
    }

    assert(
      songs == null || songs.isNotEmpty,
      "It's invalid to set empty songs queue",
    );
    assert(
      type != QueueType.origin || queues._origin != null || origin != null,
      "When you set `origin` queue and currently none set, you must provide the `origin` paramenter",
    );
    assert(
      type != QueueType.searched || queues._searchQuery != null || searchQuery != null,
      "When you set `searched` queue and currently none set, you must provide the `searchQuery` paramenter",
    );

    type ??= queues._type;
    if (type == QueueType.arbitrary) {
      modified = false;
    }

    if (type == QueueType.origin) {
      if (origin != null) {
        queues._origin = origin;
        repository.songOrigin.set(origin);
        if (setIdMapFromPlaylist && origin is Playlist) {
          state.idMap.clear();
          state.idMap.addAll(origin.idMap);
          state.idMapDirty = false;
          repository.saveIdMap();
        }
      }
    } else {
      queues._origin = null;
      repository.songOrigin.delete();
    }

    if (type == QueueType.searched) {
      if (searchQuery != null) {
        queues._searchQuery = searchQuery;
        repository.searchQuery.set(searchQuery);
      }
    } else {
      queues._searchQuery = null;
      repository.searchQuery.delete();
    }

    modified ??= queues._modified;
    shuffled ??= queues._shuffled;

    queues._type = type;
    repository.queueType.set(type);

    queues._modified = modified;
    repository.queueModified.set(modified);

    if (shuffled) {
      queues._shuffledQueue.setSongs(
        songs != null ? copySongs(songs) : Queue.shuffleSongs(shuffleFrom ?? queues.current.songs),
      );
      if (shuffleFrom != null) {
        queues._queue.setSongs(copySongs(shuffleFrom));
      }
    } else {
      queues._shuffledQueue.clear();
      if (songs != null) {
        queues._queue.setSongs(copySongs(songs));
      } else if (type == QueueType.allSongs && !modified) {
        queues._queue.setSongs(List.from(ContentControl.instance.state.allSongs.songs));
      }
    }

    queues._shuffled = shuffled;
    repository.queueShuffled.set(shuffled);

    if (save) {
      repository.saveCurrentQueue();
    }

    if (state.idMap.isNotEmpty && !modified && !shuffled && type != QueueType.origin && type != QueueType.arbitrary) {
      state.idMap.clear();
      state.idMapDirty = false;
      repository.saveIdMap();
    } else if (state.idMapDirty) {
      state.idMapDirty = false;
      repository.saveIdMap();
    }

    if (emitChangeEvent) {
      emitQueueChange();
    }
  }

  /// Checks queue pool and removes obsolete songs - that are no longer on all songs data.
  void removeObsolete({bool emitChangeEvent = true}) {
    final allSongs = ContentControl.instance.state.allSongs;
    assert(allSongs.isNotEmpty);
    state._queue.compareAndRemoveObsolete(allSongs);
    state._shuffledQueue.compareAndRemoveObsolete(allSongs);

    if (state.current.isEmpty) {
      // Set queue to global if searched or shuffled are happened to be zero-length.
      setQueue(
        type: QueueType.allSongs,
        modified: false,
        shuffled: false,
        emitChangeEvent: false,
      );
    } else {
      repository.saveCurrentQueue();
    }

    // Update current song.
    if (state.current.get(PlaybackControl.instance.currentSong) == null) {
      final player = MusicPlayer.instance;
      if (player.playing) {
        player.pause();
        player.setSong(state.current.songs[0]);
      }
    }

    if (emitChangeEvent) {
      emitQueueChange();
    }
  }

  /// Restores saved queues.
  ///
  /// * If stored queue becomes empty after restoration (songs do not exist anymore), will fall back to not modified [QueueType.all].
  /// * If saved song origin songs are restored successfully, but the playlist itself cannot be found, will fall back to [QueueType.arbitrary].
  /// * In all other cases it will restore as it was.
  Future<void> _restoreQueue() async {
    final shuffled = repository.queueShuffled.get();
    final modified = repository.queueModified.get();
    final songOrigin = repository.songOrigin.get();
    final type = repository.queueType.get();

    state.idMap = await repository.idMap.read();

    final List<Song> queueSongs = [];
    try {
      final rawQueue = await repository.queue.read();
      for (final item in rawQueue) {
        final id = item.id;
        final origin = SongOrigin.originFromEntry(item.originEntry);
        var song = ContentControl.instance.state.allSongs.byId.get(ContentUtils.getSourceId(id, origin: origin));
        if (song != null) {
          song = song.copyWith(id: id);
          song.duplicationIndex = item.duplicationIndex;
          song.origin = origin;
          queueSongs.add(song);
        }
      }
    } catch (ex, stack) {
      FirebaseCrashlytics.instance.recordError(
        ex,
        stack,
        reason: 'in rawQueue restoration',
      );
    }

    final List<Song> shuffledSongs = [];
    try {
      if (shuffled == true) {
        final rawShuffledQueue = await repository.shuffled.read();
        for (final item in rawShuffledQueue) {
          final id = item.id;
          final origin = SongOrigin.originFromEntry(item.originEntry);
          var song = ContentControl.instance.state.allSongs.byId.get(ContentUtils.getSourceId(id, origin: origin));
          if (song != null) {
            song = song.copyWith(id: id);
            song.duplicationIndex = item.duplicationIndex;
            song.origin = origin;
            shuffledSongs.add(song);
          }
        }
      }
    } catch (ex, stack) {
      FirebaseCrashlytics.instance.recordError(
        ex,
        stack,
        reason: 'in rawShuffledQueue restoration',
      );
    }

    final songs = shuffled && shuffledSongs.isNotEmpty ? shuffledSongs : queueSongs;

    if (songs.isEmpty) {
      setQueue(
        type: QueueType.allSongs,
        modified: false,
        // we must save it, so do not `save: false`
      );
    } else if (type == QueueType.origin) {
      if (songOrigin != null) {
        setQueue(
          type: type,
          modified: modified,
          shuffled: shuffled,
          songs: songs,
          shuffleFrom: queueSongs,
          origin: songOrigin,
          save: false,
          setIdMapFromPlaylist: false,
        );
      } else {
        setQueue(
          type: QueueType.arbitrary,
          shuffled: shuffled,
          songs: songs,
          shuffleFrom: queueSongs,
          save: false,
        );
      }
    } else {
      setQueue(
        type: type,
        shuffled: shuffled,
        modified: modified,
        songs: songs,
        shuffleFrom: queueSongs,
        searchQuery: repository.searchQuery.get(),
        save: false,
      );
    }
  }
}
