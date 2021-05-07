/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:convert';

import 'package:device_info/device_info.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// import 'package:quick_actions/quick_actions.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sweyer/sweyer.dart';

enum QuickAction {
  search,
  shuffleAll,
  playRecent,
}

extension QuickActionSerialization on QuickAction {
  String get value => EnumToString.convertToString(this);
} 

/// The description where the [QueueType.arbitrary] originates from.
/// 
/// Can be Cconverted to human readable text with [AppLocalizations.arbitraryQueueOrigin].
enum ArbitraryQueueOrigin {
  /// Correspnods
  allAlbums,
}

extension ArbitraryQueueOriginSerialization on ArbitraryQueueOrigin {
  String get value => EnumToString.convertToString(this);
}

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
  required V playlist,
  required V artist,
  V? fallback,
}) {
  switch (contentType ?? T) {
    case Song:
      return song;
    case Album:
      return album;
    case Playlist:
      return playlist;
    case Artist:
      return artist;
    case Content:
      if (fallback != null)
        return fallback;
      throw UnimplementedError();
    default:
      throw UnimplementedError();
  }
}

/// A [Map] container for the [Content] as key, and `T` as value entry.
class ContentMap<V> {
  /// Creates a content map from initial value [map].
  ///
  /// If none specified, will initialize the map with `null`s.
  ContentMap([this._map = const {}]);

  final Map<Type, V> _map;

  /// Map values.
  Iterable<V> get values => _map.values;

  /// Map entries.
  Iterable<MapEntry<Type, V>> get entries => _map.entries;

  /// Returs a [Sort] per `T` [Content] from the map.
  /// 
  /// If [key] was explicitly provided, will use it instead.
  V getValue<T extends Content>([Type? key]) {
    assert(
      Content.enumerate().contains(key ?? T),
      "Specified type must be a subtype of Content",
    );
    return _map[key ?? T]!;
  }

  /// Puts a [Sort] typed with `T` into the map.
  /// 
  /// If [key] was explicitly provided, will use it instead.
  void setValue<T extends Content>(V value, {Type? key}) {
    assert(
      Content.enumerate().contains(key ?? T),
      "Specified type must be a subtype of Content",
    );
    _map[key ?? T] = value;
  }
}


/// Enum used inside this file to have a pool of queues in a state-managment convenient form.
enum _PoolQueueType {
  /// Any queue type to be displayed (searched or album or etc.).
  queue,

  /// This queue is always produced from the other two.
  shuffled,
}

class _QueuePool {
  _QueuePool(Map<_PoolQueueType, Queue> map)
      : _map = map;

  final Map<_PoolQueueType, Queue> _map;

  /// Serializes [_PoolQueueType.queue].
  final QueueSerializer _queueSerializer = const QueueSerializer('queue.json');
  /// Serializes [_PoolQueueType.shuffled].
  final QueueSerializer _shuffledSerializer = const QueueSerializer('shuffled_queue.json');

  Future<void> init() {
    return Future.wait([
      _queueSerializer.init(),
      _shuffledSerializer.init(),
    ]);
  }

  Future<void> _saveCurrentQueue() {
    if (shuffled) {
      return Future.wait([
        _queueSerializer.save(_map[_PoolQueueType.queue]!.songs),
        _shuffledSerializer.save(_map[_PoolQueueType.shuffled]!.songs),
      ]);
    }
    return _queueSerializer.save(current.songs);
  }

  /// Actual type of the queue, that can be displayed to the user.
  QueueType get type => _type;
  QueueType _type = QueueType.all;

  _PoolQueueType get _internalType {
    if (shuffled) {
      return _PoolQueueType.shuffled;
    }
    return _PoolQueueType.queue;
  }

  Queue get current => _map[_internalType]!;
  Queue get _queue => _map[_PoolQueueType.queue]!;
  Queue get _shuffledQueue => _map[_PoolQueueType.shuffled]!;

  /// Current queue for [QueueType.persistent].
  /// If [type] is not [QueueType.persistent], will return `null`.
  PersistentQueue? get persistent => _persistent;
  PersistentQueue? _persistent;

  /// A search query for [QueueType.searched].
  /// If [type] is not [QueueType.searched], will return `null`.
  String? get searchQuery => _searchQuery;
  String? _searchQuery;

  /// A description where the [QueueType.arbitrary] originates from.
  ///
  /// May be `null`, then by default instead of description, in the interface queue should be just
  /// marked as [AppLocalizations.arbitraryQueue].
  ///
  /// If [type] is not [QueueType.arbitrary], will return `null`.
  ArbitraryQueueOrigin? get arbitraryQueueOrigin => _arbitraryQueueOrigin;
  ArbitraryQueueOrigin? _arbitraryQueueOrigin;

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
    _PoolQueueType.queue: Queue([]),
    _PoolQueueType.shuffled: Queue([]),
  });

  /// All songs in the application.
  /// This list should be modified in any way, except for sorting.
  Queue allSongs = Queue([]);

  Map<int, Album> albums = {};

  List<Playlist> playlists = [];

  List<Artist> artists = [];

  /// This is a map to store ids of duplicated songs in queue.
  /// Its key is always negative, so when a song has negative id, you must
  /// look up for the mapping of its actual id in here.
  Map<String, int> idMap = {};

  /// When true, [idMap] will be saved in the next [setQueue] call.
  bool idMapDirty = false;

  /// Contains various [Sort]s of the application.
  /// Sorts of specific [Queues] like [Album]s are stored separately. // TODO: this is currently not implemented - remove this todo when it will be
  ///
  /// Restored in [ContentContol._restoreSorts].
  late final ContentMap<Sort> sorts;

  /// Get current playing song.
  Song get currentSong {
    return _songSubject.value!;
  }

  /// Get current playing song.
  Song? get currentSongNullable {
    return _songSubject.value;
  }

  /// Returns index of [currentSong] in the current queue.
  ///
  /// If current song cannot be found for some reason, will fallback the state
  /// to the index `0` and return it.
  int get currentSongIndex {
    var index = queues.current.byId.getIndex(currentSong.id);
    if (index < 0) {
      final firstSong = queues.current.songs[0];
      changeSong(firstSong);
      index = 0;
    }
    return index;
  }

  /// Currently playing peristent queue when song is added via [playQueueNext]
  /// or [addQueueToQueue].
  ///
  /// Used for showing [CurrentIndicator] for [PersistenQueue]s.
  ///
  /// See [Song.origin] for more info.
  PersistentQueue? get currentSongOrigin => currentSong.origin;

  /// Changes current song id and emits change event.
  /// This allows to change the current id visually, separately from the player.
  ///
  /// Also, uses [Song.origin] to set [currentSongOrigin].
  void changeSong(Song song) {
    Prefs.songIdInt.set(song.id);
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

  /// Notifies when active selection controller changes.
  /// Will receive null when selection closes.
  ValueNotifier<ContentSelectionController?> selectionNotifier = ValueNotifier(null);

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
    // TODO: this might still deliver some pedning events to listeneres, see https://github.com/dart-lang/sdk/issues/45653
    _contentSubject.close();
    _songSubject.close();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      selectionNotifier.dispose();
    });
  }
}

// class _WidgetsBindingObserver extends WidgetsBindingObserver {
//   @override
//   void didChangeLocales(List<Locale>? locales) {
//     ContentControl._setQuickActions();
//   }
// }

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

  // /// Recently pressed quick action.
  // static final quickAction = BehaviorSubject<QuickAction>();
  // static final QuickActions _quickActions = QuickActions();
  // static final bindingObserver = _WidgetsBindingObserver();

  static final IdMapSerializer _idMapSerializer = IdMapSerializer.instance;

  /// Represents songs fetch on app start
  static bool get initializing => _initializeCompleter != null;
  static Completer<void>? _initializeCompleter;

  static bool get _empty => stateNullable?.allSongs.isEmpty ?? true;
  static bool get disposed => stateNullable == null;

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
      // TODO: prevent initalizing if already initizlied
      _initializeCompleter = Completer();
      state.emitContentChange(); // update ui to show "Searching songs" screen
      await Future.wait([
        state.queues.init(),
        _idMapSerializer.init(),
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
        // _initQuickActions();
        await _restoreQueue();
        await MusicPlayer.instance.init();
      }
      _initializeCompleter = null;
    }
    // Emit event to track change stream
    stateNullable?.emitContentChange();
  }

  /// Disposes the [state] and stops the currently going [init] process,
  /// if any.
  static void dispose() {
    if (!disposed) {
      // WidgetsBinding.instance!.removeObserver(bindingObserver);
      // _quickActions.clearShortcutItems();
      _initializeCompleter?.complete();
      _initializeCompleter = null;
      stateNullable!.dispose();
      _stateSubject.add(null);
      MusicPlayer.instance.dispose();
    }
  }

  // static void _initQuickActions() {
  //   WidgetsBinding.instance!.addObserver(bindingObserver);
  //   _quickActions.initialize((stringAction) {
  //     final action = EnumToString.fromString(QuickAction.values, stringAction)!;
  //     quickAction.add(action);
  //     // switch (action) {
  //     //   case QuickAction.search:
  //     //     break;
  //     //   case QuickAction.shuffleAll:
  //     //     break;
  //     //   case QuickAction.playRecent:
  //     //     break;
  //     //   default:
  //     //     throw UnimplementedError();
  //     // }
  //   });
  //   _setQuickActions();
  // }

  // static Future<void> _setQuickActions() {
  //   return _quickActions.setShortcutItems(<ShortcutItem>[
  //     ShortcutItem(type: QuickAction.search.value, localizedTitle: staticl10n.search, icon: 'round_search_white_36'),
  //     ShortcutItem(type: QuickAction.shuffleAll.value, localizedTitle: staticl10n.shuffleAll, icon: 'round_shuffle_white_36'),
  //     ShortcutItem(type: QuickAction.playRecent.value, localizedTitle: staticl10n.playRecent, icon: 'round_play_arrow_white_36')
  //   ]);
  // }

  //****************** Queue manipulation methods *****************************************************

  /// Should be called whenever song is added to queue.
  /// Sets [ContentState.idMapDirty] to `true`, so id map will be saved in the next call of [setQueue].
  static void _handleDuplicate(Song song) {
    assert(() {
      final originalSong = state.allSongs.byId.get(song.sourceId);
      if (identical(originalSong, song)) {
        throw ArgumentError('Tried to handle duplicate on the original song');
      }
      return true;
    }());
    final map = state.idMap;
    final newId = -(map.length + 1);
    map[newId.toString()] = song.sourceId;
    song.id = newId;
    state.idMapDirty = true;
  }

  /// Marks queues modified and traverses it to be unshuffled, preseving the shuffled
  /// queue contents.
  static void _unshuffle() {
    setQueue(
      emitChangeEvent: false,
      modified: true,
      shuffled: false,
      songs: state.queues._shuffled
          ? List.from(state.queues._shuffledQueue.songs)
          : null,
    );
  }

  /// Cheks if current queue is persistent, if yes, adds this queue as origin
  /// to all its songs. This is a required actions for each addition to the queue. 
  static void _setOrigins() {
    // Adding origin to the songs in the current persistent playlist.
    if (state.queues.type == QueueType.persistent) {
      final songs = state.queues.current.songs;
      final persistentQueue = state.queues.persistent!;
      for (final song in songs) {
        song.origin = persistentQueue;
      }
    }
  }

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
    // Save queue order
    _unshuffle();
    _setOrigins();
    final currentQueue = queues.current;
    if (songs.length == 1) {
      final song = songs[0];
      if (song != state.currentSong &&
          song != currentQueue.getNext(state.currentSong) &&
          state.currentSongIndex != currentQueue.length - 1) {
        currentQueue.remove(song);
      }
    }
    bool contains = true;
    for (int i = 0; i < songs.length; i++) {
      final song = songs[i].copyWith();
      _handleDuplicate(song);
      currentQueue.insert(state.currentSongIndex + i + 1, song);
      if (queues._type == QueueType.persistent && contains) {
        final persistentSongs = queues.persistent!.songs;
        final index = persistentSongs.indexWhere((el) => el.sourceId == song.sourceId);
        contains = index >= 0;
      }
    }
    setQueue(type: contains ? null : QueueType.arbitrary);
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
    // Save queue order
    _unshuffle();
    _setOrigins();
    bool contains = true;
    for (var song in songs) {
      song = song.copyWith();
      _handleDuplicate(song);
      state.queues.current.add(song);
      if (queues._type == QueueType.persistent && contains) {
        final persistentSongs = queues.persistent!.songs;
        final index = persistentSongs.indexWhere((el) => el.sourceId == song.sourceId);
        contains = index >= 0;
      }
    }
    setQueue(type: contains ? null : QueueType.arbitrary);
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
    final songs = queue.songs;
    assert(songs.isNotEmpty);
    // Save queue order
    _unshuffle();
    _setOrigins();
    final currentQueue = state.queues.current;
    final currentIndex = state.currentSongIndex;
    int i = 0;
    for (var song in songs) {
      song = song.copyWith();
      _handleDuplicate(song);
      song.origin = queue;
      currentQueue.insert(currentIndex + i + 1, song);
      i++;
    }
    setQueue(type: QueueType.arbitrary);
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
    final songs = queue.songs;
    assert(songs.isNotEmpty);
    // Save queue order
    _unshuffle();
    _setOrigins();
    for (var song in songs) {
      song = song.copyWith();
      _handleDuplicate(song);
      song.origin = queue;
      state.queues.current.add(song);
    }
    setQueue(type: QueueType.arbitrary);
  }

  /// Inserts [song] at [index] in the queue.
  static void insertToQueue(int index, Song song) {
    // Save queue order
    _unshuffle();
    _setOrigins();
    final queues = state.queues;
    song = song.copyWith();
    _handleDuplicate(song);
    queues.current.insert(index, song);
    bool contains = true;
    if (queues._type == QueueType.persistent) {
      final persistentSongs = queues.persistent!.songs;
      final index = persistentSongs.indexWhere((el) => el.sourceId == song.sourceId);
      contains = index >= 0;
    }
    setQueue(type: contains ? null : QueueType.arbitrary);
  }

  /// Removes the [song] from the queue.
  ///
  /// If this was the last item in current queue, will:
  /// * fall back to the first song in [QueueType.all]
  /// * fall back to [QueueType.all]
  /// * stop the playback
  static void removeFromQueue(Song song) {
    final queues = state.queues;
    if (queues.current.length == 1) {
      resetQueue();
      MusicPlayer.instance.setSong(state.queues.current.songs[0]);
      MusicPlayer.instance.pause();
    } else {
      if (song == state.currentSong) {
        MusicPlayer.instance.setSong(state.queues.current.getPrev(song));
        MusicPlayer.instance.pause();
      }
      queues.current.remove(song);
      setQueue(modified: true);
    }
  }

  /// Removes a song at given [index] from the queue.
  ///
  /// If this was the last item in current queue, will:
  /// * fall back to the first song in [QueueType.all]
  /// * fall back to [QueueType.all]
  /// * stop the playback
  static void removeFromQueueAt(int index) {
    final queues = state.queues;
    if (queues.current.length == 1) {
      resetQueue();
      MusicPlayer.instance.setSong(state.queues.current.songs[0]);
      MusicPlayer.instance.pause();
    } else {
      if (index == state.currentSongIndex) {
        MusicPlayer.instance.setSong(state.queues.current.getNextAt(index));
        MusicPlayer.instance.pause();
      }
      queues.current.removeAt(index);
      setQueue(modified: true);
    }
  }

  /// Removes all items at given [indexes] from the queue.
  ///
  /// If the [indexes] list has length bigger than or equal to current queue
  /// length, will:
  /// * fall back to the first song in [QueueType.all]
  /// * fall back to [QueueType.all]
  /// * stop the playback
  static void removeAllFromQueueAt(List<int> indexes) {
    final queues = state.queues;
    if (indexes.length >= queues.current.length) {
      resetQueue();
      MusicPlayer.instance.setSong(state.queues.current.songs[0]);
      MusicPlayer.instance.pause();
    } else {
      final containsCurrent = indexes.contains(state.currentSongIndex);
      if (containsCurrent) {
        MusicPlayer.instance.pause();
      }
      for (int i = indexes.length - 1; i >= 0; i--) {
        queues.current.removeAt(indexes[i]);
      }
      if (containsCurrent) {
        /// TODO: add to [Queue] something like relative indexing, that allows negative indexes
        /// and imporvie this
        MusicPlayer.instance.setSong(state.queues.current.songs[0]);
      }
      setQueue(modified: true);
    }
  }

  /// A shorthand for setting [QueueType.searched].
  static void setSearchedQueue(String query, List<Song> songs) {
     setQueue(
      type: QueueType.searched,
      searchQuery: query,
      modified: false,
      shuffled: false,
      songs: songs,
    );
  }

  /// A shorthand for setting [QueueType.persistent].
  /// 
  /// By default sets [shuffled] queue.
  static void setPersistentQueue({
    required PersistentQueue queue,
    required List<Song> songs,
    bool shuffled = false,
  }) {
    List<Song>? shuffledSongs;
    if (shuffled) {
      shuffledSongs = Queue.shuffleSongs(songs);
    }
    setQueue(
      type: QueueType.persistent,
      persistentQueue: queue,
      modified: false,
      shuffled: shuffled,
      songs: shuffledSongs ?? songs,
      shuffleFrom: songs,
    );
  }

  /// Resets queue to all songs.
  static void resetQueue() {
    setQueue(
      type: QueueType.all,
      modified: false,
      shuffled: false,
    );
  }

  /// Sets the queue with specified [type] and other parameters.
  /// Most of the parameters are updated separately and almost can be omitted,
  /// unless differently specified:
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
  /// * [persistentQueue] is the persistent queue being set,
  ///   only applied when [type] is [QueueType.persistent].
  ///   When [QueueType.persistent] is set and currently it's not persistent, this parameter is required.
  ///   Otherwise it can be omitted and for updating other paramters only.
  /// * [searchQuery] is the search query the playlist was searched by,
  ///   only applied when [type] is [QueueType.searched].
  ///   Similarly as for [persistentQueue], when [QueueType.searched] is set and currently it's not searched,
  ///   this parameter is required. Otherwise it can be omitted for updating other paramters only.
  /// * [arbitraryQueueOrigin] is the description where the [QueueType.arbitrary] originates from,
  ///   ignored with other types of queues. If none specified, by default instead of description,
  ///   queue is just marked as [AppLocalizations.arbitraryQueue].
  ///   It always must be localized, so [AppLocalizations] getter must be returned from this function.
  /// 
  ///   Because this parameter can be null with [QueueType.arbitrary], to reset to back to `null`
  ///   after it's set, you need to pass [type] explicitly.
  /// * [emitChangeEvent] is whether to emit a song list change event
  /// * [save] parameter can be used to disable redundant writing to JSONs when,
  ///   for example, when we restore the queue from this exact json.
  /// * [copied] indicates that [songs] was already copied,
  ///   by default set to `false` and will copy it with [List.from]
  static void setQueue({
    QueueType? type,
    bool? shuffled,
    bool? modified,
    List<Song>? songs,
    List<Song>? shuffleFrom,
    PersistentQueue? persistentQueue,
    String? searchQuery,
    ArbitraryQueueOrigin? arbitraryQueueOrigin,
    bool save = true,
    bool copied = false,
    bool emitChangeEvent = true,
  }) {
    final queues = state.queues;

    @pragma('vm:prefer-inline')
    List<Song> copySongs(List<Song> _songs) {
      return copied ? _songs : List.from(_songs);
    }

    assert(
      songs == null || songs.isNotEmpty,
      "It's invalid to set empty songs queue",
    );
    assert(
      type != QueueType.persistent ||
      queues._persistent != null ||
      persistentQueue != null,
      "When you set `persistent` queue and currently none set, you must provide the `persistentQueue` paramenter",
    );
    assert(
      type != QueueType.searched ||
      queues._searchQuery != null ||
      searchQuery != null,
      "When you set `searched` queue and currently none set, you must provide the `searchQuery` paramenter",
    );

    final typeArg = type;
    type ??= queues._type;
    if (type == QueueType.arbitrary) {
      modified = false;
      if (arbitraryQueueOrigin != null) {
        // Set once and don't change thereafter until type is passed explicitly.
        state.queues._arbitraryQueueOrigin = arbitraryQueueOrigin;
        Prefs.arbitraryQueueOrigin.set(arbitraryQueueOrigin.value);
      }
    }
    if (type != QueueType.arbitrary ||
        // Reset when queue type is passed explicitly.
        typeArg == QueueType.arbitrary && arbitraryQueueOrigin == null) {  
      state.queues._arbitraryQueueOrigin = null;
      Prefs.arbitraryQueueOrigin.delete();
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
        songs != null
          ? copySongs(songs)
          : Queue.shuffleSongs(shuffleFrom ?? queues.current.songs),
      );
      if (shuffleFrom != null) {
        queues._queue.setSongs(copySongs(shuffleFrom));
      }
    } else {
      queues._shuffledQueue.clear();
      if (songs != null) {
        queues._queue.setSongs(copySongs(songs));
      } else if (type == QueueType.all && !modified) {
        queues._queue.setSongs(List.from(state.allSongs.songs));
      }
    }

    queues._shuffled = shuffled;
    Prefs.queueShuffledBool.set(shuffled);

    if (save) {
      state.queues._saveCurrentQueue();
    }

    if (state.idMap.isNotEmpty &&
        !modified &&
        !shuffled &&
        type != QueueType.persistent &&
        type != QueueType.arbitrary) {
      state.idMap.clear();
      state.idMapDirty = false;
      _idMapSerializer.save(state.idMap);
    } else if (state.idMapDirty) {
      state.idMapDirty = false;
      _idMapSerializer.save(state.idMap);
    }

    if (emitChangeEvent) {
      state.emitContentChange();
    }
  }

  /// Checks queue pool and removes obsolete songs - that are no longer on all songs data.
  static void removeObsolete({ bool emitChangeEvent = true }) {
    state.queues._queue.compareAndRemoveObsolete(state.allSongs);
    state.queues._shuffledQueue.compareAndRemoveObsolete(state.allSongs);

    if (state.queues.current.isEmpty) {
      //  Set queue to global if searched or shuffled are happened to be zero-length
      setQueue(
        type: QueueType.all,
        modified: false,
        shuffled: false,
        emitChangeEvent: false,
      );
    } else {
      state.queues._saveCurrentQueue();
    }

    if (_empty) {
      dispose();
      return;
    }

    // Update current song
    if (state.queues.current.get(state.currentSong) == null) {
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
  
  /// Returns content of specified type.
  static List<T> getContent<T extends Content>([Type? contentType]) {
    return contentPick<T, ValueGetter<List<T>>>(
      contentType: contentType,
      song: () => state.allSongs.songs as List<T>,
      album: () => state.albums.values.toList() as List<T>,
      playlist: () => state.playlists as List<T>,
      artist: () => state.artists as List<T>,
    )();
  }

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
    if (disposed)
      return;
    await contentPick<T, AsyncCallback>(
      contentType: contentType,
      song: () async {
        state.allSongs.setSongs(await ContentChannel.retrieveSongs());
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
        state.albums = await ContentChannel.retrieveAlbums();
        if (disposed)
          return;
        sort<Album>(emitChangeEvent: false);
      },
      playlist: () async {
        state.playlists = await ContentChannel.retrievePlaylists();
        if (disposed)
          return;
        sort<Playlist>(emitChangeEvent: false);
      },
      artist: () async {
        state.artists = await ContentChannel.retrieveArtists();
        if (disposed)
          return;
        sort<Artist>(emitChangeEvent: false);
      },
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

    // TODO: add filter by year, and perhaps make a whole filter system, so it would be easy to filter by any parameter
    // this should be some option in the UI like "Search by year",
    // i disabled it because it filtered out searches like "28 days later soundtrack".
    //
    // final year = int.tryParse(words[0]);

    /// Splits string by spaces, or dashes, or bar, or paranthesis
    final abbreviationRegexp = RegExp(r'[\s\-\|\(\)]');
    final l10n = staticl10n;
    /// Checks whether a [string] is abbreviation for the [query].
    /// For example: "big baby tape - bbt"
    bool isAbbreviation(String string) {
      return string.toLowerCase()
            .split(abbreviationRegexp)
            .map((word) => word.isNotEmpty ? word[0] : '')
            .join()
            .contains(query);
    }
    final contentInterable = contentPick<T, ValueGetter<Iterable<T>>>(
      contentType: contentType,
      song: () {
        return state.allSongs.songs.where((song) {
          // Exact query search
          final wordsTest = words.map<bool>((word) =>
            song.title.toLowerCase().contains(word) ||
            ContentUtils.localizedArtist(song.artist, l10n).toLowerCase().contains(word) ||
            (song.album?.toLowerCase().contains(word) ?? false)
          ).toList();
          final fullQuery = wordsTest.every((e) => e);
          // Abbreviation search
          final abbreviation = isAbbreviation(song.title);
          return fullQuery || abbreviation;
        }).cast<T>();
      },
      album: () {
        return state.albums.values.where((album) {
          // Exact query search
          final wordsTest = words.map<bool>((word) =>
            ContentUtils.localizedArtist(album.artist, l10n).toLowerCase().contains(word) ||
            album.album.toLowerCase().contains(word),
          ).toList();
          final fullQuery = wordsTest.every((e) => e);
          // Abbreviation search
          final abbreviation = isAbbreviation(album.album);
          return fullQuery || abbreviation;
        }).cast<T>();
      },
      playlist: () {
        return state.playlists.where((playlist) {
          // Exact query search
          final wordsTest = words.map<bool>((word) =>
            playlist.name.toLowerCase().contains(word),
          ).toList();
          final fullQuery = wordsTest.every((e) => e);
          // Abbreviation search
          final abbreviation = isAbbreviation(playlist.name);
          return fullQuery || abbreviation;
        }).cast<T>();
      },
      artist: () {
        return state.artists.where((artist) {
          // Exact query search
          final wordsTest = words.map<bool>((word) =>
            artist.artist.toLowerCase().contains(word),
          ).toList();
          final fullQuery = wordsTest.every((e) => e);
          // Abbreviation search
          final abbreviation = isAbbreviation(artist.artist);
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
    sort ??= sorts.getValue<T>() as Sort<T>;
    contentPick<T, VoidCallback>(
      song: () {
        final _sort = sort! as SongSort;
        sorts.setValue<Song>(_sort);
        Prefs.songSortString.set(jsonEncode(sort.toMap()));
        final comparator = _sort.comparator;
        state.allSongs.songs.sort(comparator);
      },
      album: () {
        final _sort = sort! as AlbumSort;
        sorts.setValue<Album>(_sort);
        Prefs.albumSortString.set(jsonEncode(_sort.toMap()));
        final comparator = _sort.comparator;
        state.albums = Map.fromEntries(state.albums.entries.toList()
          ..sort((a, b) {
            return comparator(a.value, b.value);
          }));
      },
      playlist: () {
        final _sort = sort! as PlaylistSort;
        sorts.setValue<Playlist>(_sort);
        Prefs.playlistSortString.set(jsonEncode(sort.toMap()));
        final comparator = _sort.comparator;
        state.playlists.sort(comparator);
      },
      artist: () {
        final _sort = sort! as ArtistSort;
        sorts.setValue<Artist>(_sort);
        Prefs.artistSortString.set(jsonEncode(sort.toMap()));
        final comparator = _sort.comparator;
        state.artists.sort(comparator);
      },
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
    if (sdkInt >= 30) {
      for (final id in idSet) {
        final song = state.allSongs.byId.get(id);
        if (song != null) {
          songsSet.add(song);
        }
      }
    } else {
      for (final id in idSet) {
        final song = state.allSongs.byId.get(id);
        if (song != null) {
          songsSet.add(song);
        }
        state.allSongs.byId.remove(id);
      }
      removeObsolete();
    }

    try {
      final result = await ContentChannel.deleteSongs(songsSet);
      await refetchAll();
      if (sdkInt >= 30 && result) {
        idSet.forEach(state.allSongs.byId.remove);
        removeObsolete();
      }
    } catch (ex, stack) {
      FirebaseCrashlytics.instance.recordError(
        ex,
        stack,
        reason: 'in deleteSongs',
      );
      ShowFunctions.instance.showToast(
        msg: staticl10n.deletionError,
      );
      print('Deletion error: $ex');
    }
  }

  //****************** Private methods for restoration *****************************************************

  /// Restores [sorts] from [Prefs].
  static Future<void> _restoreSorts() async {
    state.sorts = ContentMap({
      Song: SongSort.fromMap(jsonDecode(await Prefs.songSortString.get())),
      Album: AlbumSort.fromMap(jsonDecode(await Prefs.albumSortString.get())),
      Playlist: PlaylistSort.fromMap(jsonDecode(await Prefs.playlistSortString.get())),
      Artist: ArtistSort.fromMap(jsonDecode(await Prefs.artistSortString.get())),
    });
  }

  /// Restores saved queues.
  ///
  /// * If stored queue becomes empty after restoration (songs do not exist anymore), will fall back to not modified [QueueType.all].
  /// * If saved persistent queue songs are restored successfully, but the playlist itself cannot be found, will fall back to [QueueType.arbitrary].
  /// * In all other cases it will restore as it was.
  static Future<void> _restoreQueue() async {
    final shuffled = await Prefs.queueShuffledBool.get();
    final modified = await Prefs.queueModifiedBool.get();
    final persistentQueueId = await Prefs.persistentQueueId.get();
    final type = EnumToString.fromString(
      QueueType.values,
      await Prefs.queueTypeString.get(),
    )!;
    state.idMap = await _idMapSerializer.read();

    final List<Song> queueSongs = [];
    final rawQueue = await state.queues._queueSerializer.read();
    for (final item in rawQueue) {
      final id = item['id'];
      var song = state.allSongs.byId.get(Song.getSourceId(id));
      if (song != null) {
        song = song.copyWith(id: id);
        final origin = item['origin_type'];
        if (origin != null) {
          if (origin == 'album') {
            song.origin = state.albums[item['origin_id']];
          } else {
            assert(false);
          }
        }
        queueSongs.add(song);
      }
    }

    final List<Song> shuffledSongs = [];
    if (shuffled == true) {
      final rawShuffledQueue = await state.queues._shuffledSerializer.read();
      for (final item in rawShuffledQueue) {
        final id = item['id'];
        var song = state.allSongs.byId.get(Song.getSourceId(id));
        if (song != null) {
          song = song.copyWith(id: id);
          final origin = item['origin_type'];
          if (origin != null) {
            if (origin == 'album') {
              song.origin = state.albums[item['origin_id']];
            } else {
              assert(false);
            }
          }
          shuffledSongs.add(song);
        }
      }
    }

    final songs = shuffled && shuffledSongs.isNotEmpty ? shuffledSongs : queueSongs;

    if (songs.isEmpty) {
      setQueue(
        type: QueueType.all,
        modified: false,
        // we must save it, so do not `save: false`
      );
    } else if (type == QueueType.persistent) {
      if (persistentQueueId != null &&
          state.albums[persistentQueueId] != null) {
        setQueue(
          type: type,
          modified: modified,
          shuffled: shuffled,
          songs: songs,
          shuffleFrom: queueSongs,
          persistentQueue: state.albums[persistentQueueId],
          save: false,
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
      final arbitraryQueueOrigin = await Prefs.arbitraryQueueOrigin.get();
      setQueue(
        type: type,
        shuffled: shuffled,
        modified: modified,
        songs: songs,
        shuffleFrom: queueSongs,
        searchQuery: await Prefs.searchQueryString.get(),
        arbitraryQueueOrigin: arbitraryQueueOrigin == null
          ? null
          : EnumToString.fromString(
              ArbitraryQueueOrigin.values,
              arbitraryQueueOrigin,
            ),
        save: false,
      );
    }
  }
}


class ContentUtils {
  /// If artist is unknown returns localized artist.
  /// Otherwise returns artist as is.
  static String localizedArtist(String artist, AppLocalizations l10n) {
    return artist != '<unknown>' ? artist : l10n.artistUnknown;
  }

  static const String dot = '•';

  /// Joins list with the [dot].
  static String joinDot(List list) {
    return list.join(dot);
  }

  /// Appends dot and year to [string].
  static String appendYearWithDot(String string, int year) {
    return '$string $dot $year'; 
  }

  /// Checks whether a [Song] is currently playing.
  /// Compares by [Song.sourceId].
  static bool songIsCurrent(Song song) {
    return song.sourceId == ContentControl.state.currentSong.sourceId;
  }

  /// Checks whether a [PersistentQueue] is currently playing.
  static bool persistentQueueIsCurrent(PersistentQueue queue) {
    return queue == ContentControl.state.currentSongOrigin ||
           queue == ContentControl.state.queues.persistent;
  }
}
