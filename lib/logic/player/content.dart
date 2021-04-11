/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

// @dart = 2.12

import 'dart:async';
import 'dart:convert';

import 'package:device_info/device_info.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sweyer/sweyer.dart';

/// Picks some value based on the provided `T` type of [Content].
/// 
/// Instead of `T`, you can explicitly specify [contentType].
/// 
/// The [fallback] can be specified in cases when the type is [Content].
/// Generally, it's better never use it, but in some cases, like selection actions,
/// that can react to [ContentSelectionController]s of mixed types, it is relevant to use it.
V contentPick<T extends Content, V>({
  Type? contentType,
  required V song,
  required V album,
  V? fallback,
}) {
  assert(song != null && album != null);
  switch (contentType ?? T) {
    case Song:
      return song;
    case Album:
      return album;
    case Content:
      if (fallback != null)
        return fallback;
      throw UnimplementedError();
    default:
      throw UnimplementedError();
  }
}

/// Enum used inside this file to have a pool of queues in a state-managment convenient form.
enum _PoolQueueType {
  /// All songs.
  /// Value `null` on app start indicates that songs are being fetched.
  /// Should not be modified in any way and should be used only for composing other queues (or displaying its copy).
  all,

  /// Any queue type to be displayed (searched or album or etc.).
  /// Must never be null.
  custom,

  /// This queue is always produced from the other two.
  /// Must never be null.
  shuffled,
}

/// A [Map] container for the [Sort]s.
/// 
/// Initialazed with constant map that has to be replaced with actual data later.
///
/// Used to have a typed getter and setter, because [Map] uses [Object].
class _Sorts {
  /// Map that contains various [Sort]s of the application.
  /// Sorts of specific [Queues] like [Album]s might be stored separately.
  ///
  /// Values are restored in [ContentControl._restoreSorts].
  Map<Type, Sort?> _map = {
    Song: null,
    Album: null,
  };

  /// Returs a [Sort] per `T` [Content] from the map.
  /// 
  /// If [key] was explicitly provided, will use it instead.
  Sort<T> getValue<T extends Content>([Type? key]) => _map[key ?? T]! as Sort<T>;

  /// Puts a [Sort] typed with `T` into the map.
  /// 
  /// If [key] was explicitly provided, will use it instead.
  void setValue<T extends Content>(Sort<T> value, {Type? key}) {
    _map[key ?? T] = value;
  }
}

class _QueuePool {
  _QueuePool(Map<_PoolQueueType, Queue> map)
      : _map = map;

  final Map<_PoolQueueType, Queue> _map;

  /// Actual type of the queue, that can be displayed to the user.
  QueueType get type => _type;
  QueueType _type = QueueType.all;

  _PoolQueueType get _internalType {
    if (shuffled) {
      return _PoolQueueType.shuffled;
    }
    return _PoolQueueType.custom;
  }

  set _all(Queue value) => _map[_PoolQueueType.all] = value;
  /// All the songs of the application.
  Queue get all => _map[_PoolQueueType.all]!;
  Queue get current => _map[_internalType]!;
  Queue get _custom => _map[_PoolQueueType.custom]!;
  Queue get _shuffledQueue => _map[_PoolQueueType.shuffled]!;

  /// Returns current queue for [QueueType.persistent].
  /// If [type] is not [QueueType.persistent], will return null.
  PersistentQueue? get persistent => _persistent;
  PersistentQueue? _persistent;

  /// Returns a search query for [QueueType.searched].
  /// If [type] is not [QueueType.searched], will return null.
  String? get searchQuery => _searchQuery;
  String? _searchQuery;

  /// Whether the current queue is modified.
  ///
  /// Applied in certain conditions when user adds, removes
  /// or reorders songs in the queue.
  /// [QueueType.custom] cannot be modified.
  bool get modified => _modified;
  bool _modified = false;

  /// Whether the current queue is shuffled.
  bool get shuffled => _shuffled;
  bool _shuffled = false;
}

class _ContentState {
  final _QueuePool queues = _QueuePool({
    _PoolQueueType.all: Queue([]),
    _PoolQueueType.custom: Queue([]),
    _PoolQueueType.shuffled: Queue([]),
  });

  Map<int, Album> albums = {};

  /// This is a map to store ids of duplicated songs in queue.
  /// Its key is always negative, so when a song has negative id, you must
  /// look up for the mapping of its actual id in here.
  Map<String, int> idMap = {};

  /// Contains various [Sort]s of the application.
  /// Sorts of specific [Queues] like [Album]s are stored separately. // TODO: this is currently not implemented - remove this todo when it will be
  ///
  /// Values are restored in [ContentControl._restoreSorts].
  final _Sorts sorts = _Sorts();

  /// Get current playing song.
  Song get currentSong {
    return _songSubject.value!;
  }

  /// Returns index of [currentSong] in the current queue.
  ///
  /// If current song cannot be found for some reason, will fallback the state
  /// to the index `0` and return it.
  int get currentSongIndex {
    var index = queues.current.byId.getSongIndex(currentSong.id);
    if (index < 0) {
      final firstSong = queues.current.songs[0];
      changeSong(firstSong);
      Prefs.songIdInt.set(firstSong.id);
      index = 0;
    }
    return index;
  }

  /// Currently playing peristent queue when song is added via [ContentControl.playQueueNext]
  /// or [ContentControl.addQueueToQueue].
  ///
  /// Used for showing [CurrentIndicator] for [PersistenQueue]s.
  ///
  /// See [Song.origin] for more info.
  PersistentQueue? get currentSongOrigin => _currentSongOrigin;
  PersistentQueue? _currentSongOrigin;

  /// Changes current song id and emits change event.
  /// This allows to change the current id visually, separately from the player.
  ///
  /// Also, uses [Song.origin] to set [currentSongOrigin].
  void changeSong(Song song) {
    if (song.origin == null) {
      _currentSongOrigin = null;
    } else {
      _currentSongOrigin = song.origin;
    }
    // Song id saved to prefs in the native play method.
    emitSongChange(song);
  }

  /// A stream of changes over content.
  /// Called whenever [Content] (queues, songs, albums, etc. changes).
  Stream<void> get onContentChange => _contentSubject.stream;
  final PublishSubject<void> _contentSubject = PublishSubject();

  /// A stream of changes on song.
  Stream<Song> get onSongChange => _songSubject.stream;
  final BehaviorSubject<Song> _songSubject = BehaviorSubject();

  /// Emit event to [onContentChange].
  ///
  /// Includes updates to queue and any other song list.
  void emitContentChange() {
    assert(!_disposed);
    _contentSubject.add(null);
  }

  /// Emits song change event.
  void emitSongChange(Song song) {
    assert(!_disposed);
    _songSubject.add(song);
  }

  bool _disposed = false;
  void dispose() {
    assert(!_disposed);
    _disposed = true;
    _contentSubject.close();
    _songSubject.close();
  }
}

/// A class to any content-related actions, e.g.:
/// 1. Fetch songs
/// 2. Control queue json
/// 3. Manage queues
/// 4. Search in queues
///
/// etc.
abstract class ContentControl {
  /// Content state.
  ///
  /// This getter only can be called when it's known for sure
  /// that this will be not `null`,  otherwise it will throw.
  static _ContentState get state => _stateSubject.value!;
  /// Same as [state], but can be `null`, which means that the state was disposed.
  static _ContentState? get stateNullable => _stateSubject.value;

  /// Notifies when [state] is changed created or disposed.
  static Stream<_ContentState?> get onStateCreateRemove => _stateSubject.stream;
  static final BehaviorSubject<_ContentState?> _stateSubject = BehaviorSubject();

  /// A helper to serialize the queue.
  static QueueSerializer queueSerializer = QueueSerializer.instance;
  static IdMapSerializer idMapSerializer = IdMapSerializer.instance;

  /// Represents songs fetch on app start
  static bool get initializing => _initializeCompleter != null;
  static Completer<void>? _initializeCompleter;

  static bool get _empty => stateNullable?.queues.all.isEmpty ?? true;
  static bool get _disposed => stateNullable == null;

  /// Android SDK integer.
  static late int _sdkInt;
  static int get sdkInt => _sdkInt;

  static ValueNotifier<bool> get devMode => _devMode;
  static late ValueNotifier<bool> _devMode;
  /// Sets dev mode.
  static void setDevMode(bool value) {
    devMode.value = value;
    Prefs.devModeBool.set(value);
  }

  /// The main data app initialization function, inits all queues.
  /// Also handles no-permissions situations.
  static Future<void> init() async {
    if (stateNullable == null) {
      _stateSubject.add(_ContentState());
    }
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    _sdkInt = androidInfo.version.sdkInt;
    _devMode = ValueNotifier(await Prefs.devModeBool.get());
    if (Permissions.granted) {
      _initializeCompleter = Completer();
      state.emitContentChange(); // update ui to show "Searching songs screen"
      await Future.wait([
        queueSerializer.init(),
        idMapSerializer.init(),
        _restoreSorts(),
      ]);
      await Future.any([
        _initializeCompleter!.future,
        Future.wait([
          for (final contentType in Content.enumerate())
            refetch(contentType: contentType, updateQueues: false, emitChangeEvent: false),
        ]),
      ]);
      if (!_empty && _initializeCompleter != null && !_initializeCompleter!.isCompleted) {
        await _restoreQueue();
        await MusicPlayer.instance.init();
      }
      _initializeCompleter = null;
    }
    // Emit event to track change stream
    stateNullable?.emitContentChange();
  }

  /// Diposes the [state] and stops the currently going [init] process,
  /// if any.
  static void dispose() {
    if (!_disposed) {
      _initializeCompleter?.complete();
      _initializeCompleter = null;
      stateNullable?.dispose();
      _stateSubject.add(null);
      MusicPlayer.instance.dispose();
    }
  }

  /// Should be called if played song is duplicated in the current queue.
  static void handleDuplicate(Song song) {
    final map = state.idMap;
    final newId = -(map.length + 1);
    map[newId.toString()] = song.id;
    song.id = newId;
    state.changeSong(song);
    queueSerializer.save(state.queues.current.songs);
    idMapSerializer.save(state.idMap);
  }

  //****************** Queue manipulation methods *****************************************************

  /// If the [song] is next (or currently playing), will duplicate it and queue it to be played next,
  /// else will move it to be next. After that it can be duplicated to be played more.
  ///
  /// Same as for [addToQueue]:
  /// * if current queue is [QueueType.persistent] and the added [song] is present in it, will mark the queue as modified,
  /// else will traverse it into [QueueType.arbitrary]. All the other queues will be just marked as modified.
  /// * if current queue is shuffled, it will copy all songs (thus saving the order of shuffled songs), go back to be unshuffled,
  /// and add the [songs] there.
  static void playNext(List<Song> songs) {
    assert(songs.isNotEmpty);
    final queues = state.queues;
    setQueue(
      modified: true,
      shuffled: false,
      songs: queues._shuffled && queues._type != QueueType.all
          ? List.from(queues._shuffledQueue.songs)
          : null,
    );
    final currentQueue = queues.current;
    if (songs.length == 1) {
      final song = songs[0];
      if (song != state.currentSong &&
          song != currentQueue.getNextSong(state.currentSong) &&
          state.currentSongIndex != currentQueue.length - 1) {
        currentQueue.removeSong(song);
      }
    }
    bool contains = true;
    for (int i = 0; i < songs.length; i++) {
      currentQueue.insert(state.currentSongIndex + i + 1, songs[i]);
      if (queues._type == QueueType.persistent && contains) {
        final persistentSongs = queues.persistent!.songs;
        final index = persistentSongs.indexWhere((el) => el.sourceId == songs[i].sourceId);
        contains = index >= 1;
      }
    }
    setQueue(type: contains ? null : QueueType.arbitrary);
    state.emitContentChange();
  }

  /// Queues the [song] to the last position in queue.
  ///
  /// Same as for [playNext]:
  /// * if current queue is [QueueType.persistent] and the added [song] is present in it, will mark the queue as modified,
  /// else will traverse it into [QueueType.arbitrary]. All the other queues will be just marked as modified.
  /// * if current queue is shuffled, it will copy all songs (thus saving the order of shuffled songs), go back to be unshuffled,
  /// and add the [songs] there.
  static void addToQueue(List<Song> songs) {
    assert(songs.isNotEmpty);
    final queues = state.queues;
    setQueue(
      modified: true,
      shuffled: false,
      songs: queues._shuffled && queues._type != QueueType.all
          ? List.from(queues._shuffledQueue.songs)
          : null,
    );
    bool contains = true;
    for (final song in songs) {
      state.queues.current.add(song);
      if (queues._type == QueueType.persistent && contains) {
        final persistentSongs = queues.persistent!.songs;
        final index = persistentSongs.indexWhere((el) => el.sourceId == song.sourceId);
        contains = index >= 1;
      }
    }
    setQueue(type: contains ? null : QueueType.arbitrary);
    state.emitContentChange();
  }

  /// Queues the persistent [queue] to be played next.
  ///
  /// Saves it to [Song.origin] in its items, and so when the item is played,
  /// this peristent queue will be also shown as playing.
  ///
  /// If currently some persistent queue is already playing, will first save the current queue to
  /// [Song.origin] in its items.
  /// 
  /// In difference with [playNext], always traverses the playlist into [QueueType.arbitrary].
  static void playQueueNext(PersistentQueue queue) {
    // assert(queue.isNotEmpty);
    // Adding origin to the songs in the current persistent playlist.
    if (state.queues.type == QueueType.persistent) {
      final persistentQueue = state.queues.persistent;
      for (final song in persistentQueue!.songs) {
        song.origin = persistentQueue;
      }
      state._currentSongOrigin = persistentQueue;
    }
    final currentQueue = state.queues.current;
    final currentIndex = state.currentSongIndex;
    int i = 0;
    for (final song in queue.songs) {
      song.origin = queue;
      currentQueue.insert(currentIndex + i + 1, song);
      i++;
    }
    setQueue(type: QueueType.arbitrary);
    state.emitContentChange();
  }

  /// Queues the persistent [queue] to the last position in queue.
  ///
  /// Saves it to [Song.origin] in its items, and so when the item is played,
  /// this peristent queue will be also shown as playing.
  ///
  /// If currently some persistent queue is already playing, will first save the current queue to
  /// [Song.origin] in its items.
  ///
  /// In difference with [addToQueue], always traverses the playlist into [QueueType.arbitrary].
  static void addQueueToQueue(PersistentQueue queue) {
    // assert(queue.isNotEmpty);
    // Adding origin to the songs in the current persistent playlist.
    if (state.queues.type == QueueType.persistent) {
      final persistentQueue = state.queues.persistent;
      for (final song in persistentQueue!.songs) {
        song.origin = persistentQueue;
      }
      state._currentSongOrigin = persistentQueue;
    }
    for (final song in queue.songs) {
      song.origin = queue;
      state.queues.current.add(song);
    }
    setQueue(type: QueueType.arbitrary);
    state.emitContentChange();
  }

  /// Sets the queue with specified [type] and other parameters.
  /// Most of the parameters are updated separately and almost can be omitted,
  /// unless differently specified:
  ///
  /// * [shuffled] can be used to shuffle / unshuffle the queue
  /// * [modified] can be used to mark current queue as modified
  /// * [songs] is the songs list to set to the queue
  /// * [persistentQueue] is the persistent queue being set,
  ///   only applied when [type] is [QueueType.persistent].
  ///   When [QueueType.persistent] is set and currently it's not persistent, this parameter is required.
  ///   Otherwise it can be omitted and for updating other paramters only.
  /// * [searchQuery] is the search query the playlist was searched by,
  ///   only applied when [type] is [QueueType.searched].
  ///   Similarly as for [persistentQueue], when [QueueType.searched] is set and currently it's not searched,
  ///   this parameter is required. Otherwise it can be omitted for updating other paramters only.
  /// * [emitChangeEvent] is whether to emit a song list change event
  /// * [save] parameter can be used to disable redundant writing to JSONs when,
  ///   for example, when we restore the queue from this exact json.
  /// * [copied] is set to true that indicates that songs is already unique,
  ///   otherwise it will copy it with [List.from]
  static void setQueue({
    QueueType? type,
    bool? shuffled,
    bool? modified,
    List<Song>? songs,
    PersistentQueue? persistentQueue,
    String? searchQuery,
    bool emitChangeEvent = true,
    bool save = true,
    bool copied = false,
  }) {
    final queues = state.queues;

    @pragma('vm:prefer-inline')
    List<Song> copySongs(List<Song> _songs) {
      return copied ? _songs : List.from(_songs);
    }

    assert(
      type != QueueType.persistent ||
      queues._persistent != null ||
      persistentQueue != null,
      'When you set `persistent` queue and currently none set, you must provide the `persistentQueue` paramenter',
    );
    assert(
      type != QueueType.searched ||
      queues._searchQuery != null ||
      searchQuery != null,
      'When you set `searched` queue and currently none set, you must provide the `searchQuery` paramenter',
    );

    type ??= queues._type;
    if (type == QueueType.arbitrary) {
      modified = false;
    }

    if (type == QueueType.persistent) {
      if (persistentQueue != null) {
        queues._persistent = persistentQueue;
        Prefs.persistentQueueId.set(persistentQueue.id);
      }
    } else {
      queues._persistent = null;
      Prefs.persistentQueueId.delete();
    }

    if (type == QueueType.searched) {
      if (searchQuery != null) {
        queues._searchQuery = searchQuery;
        Prefs.searchQueryString.set(searchQuery);
      }
    } else {
      queues._searchQuery = null;
      Prefs.searchQueryString.delete();
    }

    modified ??= queues._modified;
    shuffled ??= queues._shuffled;

    queues._type = type;
    Prefs.queueTypeString.set(type.value);

    queues._modified = modified;
    Prefs.queueModifiedBool.set(modified);

    if (shuffled) {
      queues._shuffledQueue.setSongs(
        songs != null ? copySongs(songs) : Queue.shuffleSongs(queues.current.songs),
      );
      if (save) {
        queueSerializer.save(queues._shuffledQueue.songs);
      }
    } else {
      queues._shuffledQueue.clear();
      if (songs != null) {
        queues._custom.setSongs(copySongs(songs));
      } else if (type == QueueType.all && !modified) {
        queues._custom.setSongs(List.from(queues.all.songs));
      }
      if (save) {
        queueSerializer.save(queues._custom.songs);
      }
    }
    queues._shuffled = shuffled;
    Prefs.queueShuffledBool.set(shuffled);

    if (state.idMap.isNotEmpty &&
        !modified &&
        !shuffled &&
        type != QueueType.persistent &&
        type != QueueType.arbitrary) {
      state.idMap.clear();
      idMapSerializer.save(state.idMap);
    }

    if (emitChangeEvent) {
      state.emitContentChange();
    }
  }

  /// Checks queue pool and removes obsolete songs - that are no longer on all songs data.
  static void removeObsolete({ bool emitChangeEvent = true }) {
    state.queues._custom.compareAndRemoveObsolete(state.queues.all);
    state.queues._shuffledQueue.compareAndRemoveObsolete(state.queues.all);

    if (state.queues.current.isEmpty) {
      //  Set queue to global if searched or shuffled are happened to be zero-length
      setQueue(
        type: QueueType.all,
        modified: false,
        shuffled: false,
        emitChangeEvent: false,
      );
    } else {
      switch (state.queues._internalType) {
        case _PoolQueueType.custom:
          queueSerializer.save(state.queues._custom.songs);
          break;
        case _PoolQueueType.shuffled:
          queueSerializer.save(state.queues._shuffledQueue.songs);
          break;
        default:
          throw InvalidCodePathError();
      }
    }

    // Update current song
    if (state.queues.current.isNotEmpty &&
        state.currentSongIndex < 0) {
      final player = MusicPlayer.instance;
      if (player.playing) {
        player.pause();
        player.setSong(state.queues.current.songs[0]);
      }
    }

    if (emitChangeEvent) {
      state.emitContentChange();
    }
  }

  //****************** Content manipulation methods *****************************************************

  /// Refetches all the content.
  static Future<void> refetchAll() async {
    await Future.wait([
      for (final contentType in Content.enumerate())
        refetch(contentType: contentType),
    ]);
    return MusicPlayer.instance.restoreLastSong();
  }

  /// Refetches content by the `T` content type.
  ///
  /// Instead of `T`, you can explicitly specify [contentType].
  ///
  /// When [updateQueues] is `true`, checks checks the queues for obsolete songs by calling [removeObsolete].
  /// (only works with [Song]s).
  static Future<void> refetch<T extends Content>({
    Type? contentType,
    bool updateQueues = true,
    bool emitChangeEvent = true,
  }) async {
    await contentPick<T, AsyncCallback>(
      contentType: contentType,
      song: () async {
        final json = await ContentChannel.retrieveSongs();
        final List<Song> songs = [];
        for (final songStr in json) {
          songs.add(Song.fromJson(jsonDecode(songStr)));
        }
        state.queues.all.setSongs(songs);
        if (_empty) {
          dispose();
          return;
        }
        sort<Song>(emitChangeEvent: false);
        if (updateQueues) {
          removeObsolete(emitChangeEvent: false);
        }
      },
      album: () async {
        if (_disposed) {
          return;
        }
        final json = await ContentChannel.retrieveAlbums();
        state.albums = {};
        for (final albumStr in json) {
          final albumJson = jsonDecode(albumStr);
          state.albums[albumJson['id'] as int] = Album.fromJson(albumJson);
        }
        sort<Album>(emitChangeEvent: false);
      }
    )();
    if (emitChangeEvent) {
      stateNullable?.emitContentChange();
    }
  }

  /// Searches for content by given [query] and the `T` content type.
  ///
  /// Instead of `T`, you can explicitly specify [contentType]..
  static List<T> search<T extends Content>(String query, { Type? contentType }) {
    // Lowercase to bring strings to one format
    query = query.toLowerCase();
    final words = query.split(' ');
    final year = int.tryParse(words[0]);
    /// Splits string by spaces, or dashes, or bar, or paranthesis
    final abbreviationRegexp = RegExp(r'[\s\-\|\(\)]');
    /// Checks whether a [string] is abbreviation.
    /// For example: "big baby tape - bbt"
    bool isAbbreviation(String string) {
      return string.toLowerCase()
            .split(abbreviationRegexp)
            .map((word) => word.isNotEmpty ? word[0] : '')
            .join()
            .contains(query);
    }
    final contentInterable = contentPick<T, Iterable<T> Function()>(
      contentType: contentType,
      song: () {
        return state.queues.all.songs.where((song) {
          // Exact query search
          bool fullQuery;
          final wordsTest = words.map<bool>((word) =>
            song.title.toLowerCase().contains(word) ||
            song.artist.toLowerCase().contains(word) ||
            song.album.toLowerCase().contains(word)
          ).toList();
          // Exclude the year from query word tests
          if (year != null) {
            wordsTest.removeAt(0);
          }
          fullQuery = wordsTest.every((e) => e);
          final abbreviation = isAbbreviation(song.title);
          // Filter by year
          if (year != null && year != song.getAlbum().year)
            return false;
          return fullQuery || abbreviation;
        }).cast<T>();
      },
      album: () {
        return state.albums.values.where((album) {
          // Exact query search
          bool fullQuery;
          final wordsTest = words.map<bool>((word) =>
            album.artist.toLowerCase().contains(word) ||
            album.album.toLowerCase().contains(word),
          ).toList();
          // Exclude the year from query word tests
          if (year != null) {
            wordsTest.removeAt(0);
          }
          fullQuery = wordsTest.every((e) => e);
          final abbreviation = isAbbreviation(album.album);
          // Filter by year
          if (year != null && year != album.year)
            return false;
          return fullQuery || abbreviation;
        }).cast<T>();
      },
    )();
    return contentInterable.toList();
  }

  /// Sorts songs, albums, etc.
  /// See [ContentState.sorts].
  static void sort<T extends Content>({ Sort<T>? sort, bool emitChangeEvent = true }) {
    final sorts = state.sorts;
    sort ??= sorts.getValue<T>();
    contentPick<T, VoidCallback>(
      song: () {
        final _sort = sort! as SongSort;
        sorts.setValue<Song>(_sort);
        Prefs.songSortString.set(jsonEncode(sort.toJson()));
        final comparator = _sort.comparator;
        state.queues.all.songs.sort(comparator);
      },
      album: () {
        final _sort = sort! as AlbumSort;
        sorts.setValue(_sort);
        Prefs.albumSortString.set(jsonEncode(_sort.toJson()));
        final comparator = _sort.comparator;
        state.albums = Map.fromEntries(state.albums.entries.toList()
          ..sort((a, b) {
            return comparator(a.value, b.value);
          }));
      }
    )();
    // Emit event to track change stream
    if (emitChangeEvent) {
      state.emitContentChange();
    }
  }

  /// Deletes songs by specified [idSet].
  ///
  /// Ids must be source (not negative).
  static Future<void> deleteSongs(Set<int> idSet) async {
    final Set<Song> songsSet = {};
    // On Android R the deletion is performed with OS dialog.
    if (_sdkInt >= 30) {
      for (final id in idSet) {
        final song = state.queues.all.byId.getSong(id);
        if (song != null) {
          songsSet.add(song);
        }
      }
    } else {
      for (final id in idSet) {
        final song = state.queues.all.byId.getSong(id);
        if (song != null) {
          songsSet.add(song);
        }
        state.queues.all.byId.removeSong(id);
      }
      removeObsolete();
    }

    try {
      final result = await ContentChannel.deleteSongs(songsSet);
      if (sdkInt >= 30 && result) {
        idSet.forEach(state.queues.all.byId.removeSong);
        removeObsolete();
      }
    } catch (ex, stack) {
      FirebaseCrashlytics.instance.recordError(
        ex,
        stack,
        reason: 'in deleteSongs',
      );
      ShowFunctions.instance.showToast(
        msg: getl10n(AppRouter.instance.navigatorKey.currentContext).deletionError,
      );
      print('Deletion error: $ex');
    }
  }

  //****************** Private methods for restoration *****************************************************

  /// Restores [sorts] from [Prefs].
  static Future<void> _restoreSorts() async {
    state.sorts._map = {
      Song: SongSort.fromJson(jsonDecode(await Prefs.songSortString.get())),
      Album: AlbumSort.fromJson(jsonDecode(await Prefs.albumSortString.get())),
    };
  }

  /// Restores saved queue from json if [queueTypeInt] (saved [_queues.type]) is not [QueueType.all].
  ///
  /// * Shuffled parameter is not restored. Any [shuffled] queue will be restored as [QueueType.arbitrary].
  ///   An exception from this is [QueueType.all], which can be, but only if it's not modified.
  ///   Modified will become [QueueType.arbitrary].
  /// * If stored queue becomes empty after restoration (songs do not exist anymore), will fall back to not modified [QueueType.all].
  /// * If saved persistent queue songs are restored successfully, but the playlist itself cannot be found, will fall back to [QueueType.arbitrary].
  /// * In all other cases it will restore as it was.
  static Future<void> _restoreQueue() async {
    final shuffled = await Prefs.queueShuffledBool.get();
    final modified = await Prefs.queueModifiedBool.get();
    final type = EnumToString.fromString(
      QueueType.values,
      await Prefs.queueTypeString.get(),
    )!;
    state.queues._type = type;
    state.idMap = await idMapSerializer.read();

    /// Get songs ids from json
    final songIds = await queueSerializer.read();
    final List<Song> songs = [];
    for (final id in songIds) {
      final song = state.queues.all.byId.getSong(Song.getSourceId(id));
      if (song != null) {
        songs.add(song.copyWith(id: id));
      }
    }
    final persistentQueueId = await Prefs.persistentQueueId.get();
    if (songs.isEmpty) {
      setQueue(
        type: QueueType.all,
        modified: false,
        // we must save it, so do not `save: false`
      );
    } else if (shuffled!) {
      if (type == QueueType.all && !modified!) {
        setQueue(
          type: QueueType.all,
          shuffled: shuffled,
          songs: songs,
          save: false,
        );
      } else {
        setQueue(
          type: QueueType.arbitrary,
          songs: songs,
          save: false,
        );
      }
    } else if (type == QueueType.persistent) {
      if (persistentQueueId != null &&
          state.albums[persistentQueueId] != null) {
        setQueue(
          type: type,
          modified: modified,
          persistentQueue: state.albums[persistentQueueId],
          songs: songs,
          save: false,
        );
      } else {
        setQueue(
          type: QueueType.arbitrary,
          songs: songs,
          save: false,
        );
      }
    } else {
      setQueue(
        type: type,
        searchQuery: await Prefs.searchQueryString.get(),
        modified: modified,
        songs: songs,
        save: false,
      );
    }
  }
}
