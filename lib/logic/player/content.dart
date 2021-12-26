/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:device_info/device_info.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// import 'package:quick_actions/quick_actions.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sweyer/logic/logic.dart';
import 'package:sweyer/sweyer.dart';

// See content logic overview here
// https://docs.google.com/document/d/1QtF9koBcWuRE1lIYJ45cRMogAprb7xD83ImmI0cn3lQ/edit
// TODO: update it

enum QuickAction {
  search,
  shuffleAll,
  playRecent,
}

extension QuickActionSerialization on QuickAction {
  String get value => EnumToString.convertToString(this);
}

/// Picks some value based on the provided `T` type of [Content].
///
/// Instead of `T`, you can explicitly specify [contentType].
///
/// The [fallback] can be specified in cases when the type is [Content].
/// Generally, it's better never use it, but in some cases, like selection actions,
/// that can react to [ContentSelectionController]s of mixed types, it is relevant to use it.
///
/// The point of this function is to structurize and generalize the places where multiple contents
/// an be used. It also allows to ensure that every existing content in the app is supported in all
/// places it should be supported, this is extra useful when new content type is added.
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

/// Analogue of [contentPick] for [PersistentQueue]s.
V persistentQueuePick<T extends PersistentQueue, V>({
  Type? contentType,
  required V album,
  required V playlist,
  V? fallback,
}) {
  switch (contentType ?? T) {
    case Album:
      return album;
    case Playlist:
      return playlist;
    case Content:
      if (fallback != null)
        return fallback;
      throw UnimplementedError();
    default:
      throw UnimplementedError();
  }
}

/// A [Map] container for the [Content] as key, and `V` as value entry.
class ContentMap<V> {
  /// Creates a content map from initial value [map].
  ///
  /// If none specified, will initialize with empty map.
  ContentMap([Map<Type, V>? map]) : _map = map ?? {};

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

  /// This queue is always produced from the [queue].
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
  QueueType _type = QueueType.allSongs;

  _PoolQueueType get _internalType {
    if (shuffled) {
      return _PoolQueueType.shuffled;
    }
    return _PoolQueueType.queue;
  }

  Queue get current {
    final value = _map[_internalType]!;
    assert(value.isNotEmpty, "Current queue must not be empty");
    if (value.isEmpty) {
      ContentControl.resetQueue();
    }
    return _map[_internalType]!;
  }
  Queue get _queue => _map[_PoolQueueType.queue]!;
  Queue get _shuffledQueue => _map[_PoolQueueType.shuffled]!;

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
}

class ContentState {
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
  ///
  /// The key is string, because [jsonEncode] and [jsonDecode] can only
  /// work with `Map<String, dynamic>`. Convertion to int doesn't seem to be a
  /// benefit, so keeping this as string.
  /// 
  /// See [ContentUtils.deduplicateSong] for discussion about the
  /// logic behind this.
  IdMap idMap = {};

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

  /// Currently playing peristent queue when song is added via [ContentControl.playOriginNext]
  /// or [ContentControl.addOriginToQueue].
  ///
  /// Used for showing [CurrentIndicator] for [SongOrigin]s.
  ///
  /// See also [Song.origin].
  SongOrigin? get currentSongOrigin => currentSong.origin;

  /// Changes current song id and emits change event.
  /// This allows to change the current id visually, separately from the player.
  ///
  /// Also, uses [Song.origin] to set [currentSongOrigin].
  void changeSong(Song song) {
    if (song.id != currentSongNullable?.id)
      Prefs.songId.set(song.id);
    if (!identical(song, currentSongNullable))
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
  static ContentState get state => _stateSubject.value!;
  /// Same as [state], but can be `null`, which means that the state was disposed.
  static ContentState? get stateNullable => _stateSubject.value;

  /// Notifies when [state] is changed created or disposed.
  static Stream<ContentState?> get onStateCreateRemove => _stateSubject.stream;
  static final BehaviorSubject<ContentState?> _stateSubject = BehaviorSubject();

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

  /// The main data app initialization function, inits all queues.
  /// Also handles no-permissions situations.
  static Future<void> init() async {
    if (stateNullable == null) {
      _stateSubject.add(ContentState());
    }
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    _sdkInt = androidInfo.version.sdkInt;
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

  /// Must be called before the song is instreted to the current queue,
  /// calls [ContentUtils.deduplicateSong].
  static void _deduplicateSong(Song song) {
    final result = ContentUtils.deduplicateSong(
      song: song,
      list: state.queues.current.songs,
      idMap: state.idMap,
    );
    if (result) {
      state.idMapDirty = true;
    }
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

  /// Checks if current queue is [QueueType.origin], if yes, adds this queue as origin
  /// to all its songs. This is a required action for each addition to the queue.
  static void _setOrigins() {
    if (state.queues.type == QueueType.origin) {
      final songs = state.queues.current.songs;
      final songOrigin = state.queues.origin!;
      for (final song in songs) {
        song.origin = songOrigin;
      }
    }
  }

  /// Checks whether the current origin contains a song.
  /// If current queue is not origin, will always return `true`.
  /// Intended to be used in queue insertion operations, see [playNext] for example.
  static bool _doesOriginContain(Song song) {
    final queues = state.queues;
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
  static void playNext(List<Song> songs) {
    assert(songs.isNotEmpty);
    final queues = state.queues;
    // Save queue order
    _unshuffle();
    _setOrigins();
    final currentQueue = queues.current;
    if (songs.length == 1) {
      final song = songs[0];
      if (song.sourceId != state.currentSong.sourceId &&
          song.sourceId != currentQueue.getNext(state.currentSong)?.sourceId &&
          state.currentSongIndex != currentQueue.length - 1) {
        currentQueue.remove(song);
      }
    }
    bool contains = true;
    for (int i = 0; i < songs.length; i++) {
      final song = songs[i].copyWith();
      _deduplicateSong(song);
      currentQueue.insert(state.currentSongIndex + i + 1, song);
      if (contains) {
        contains = _doesOriginContain(song);
      }
    }
    setQueue(type: contains ? null : QueueType.arbitrary);
  }

  /// Queues the [song] to the last position in queue.
  ///
  /// Same as for [playNext]:
  /// * if current queue is [QueueType.origin] and the added [song] is present in it, will mark the queue as modified,
  /// else will traverse it into [QueueType.arbitrary]. All the other queues will be just marked as modified.
  /// * if current queue is shuffled, it will copy all songs (thus saving the order of shuffled songs), go back to be unshuffled,
  /// and add the [songs] there.
  static void addToQueue(List<Song> songs) {
    assert(songs.isNotEmpty);
    // Save queue order
    _unshuffle();
    _setOrigins();
    bool contains = true;
    for (var song in songs) {
      song = song.copyWith();
      _deduplicateSong(song);
      state.queues.current.add(song);
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
  static void playOriginNext(SongOrigin origin) {
    final songs = origin.songs;
    assert(songs.isNotEmpty);
    // Save queue order
    _unshuffle();
    _setOrigins();
    final currentQueue = state.queues.current;
    final currentIndex = state.currentSongIndex;
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
  static void addOriginToQueue(SongOrigin origin) {
    final songs = origin.songs;
    assert(songs.isNotEmpty);
    // Save queue order
    _unshuffle();
    _setOrigins();
    for (var song in songs) {
      song = song.copyWith();
      song.origin = origin;
      _deduplicateSong(song);
      state.queues.current.add(song);
    }
    setQueue(type: QueueType.arbitrary);
  }

  /// Inserts [songs] at [index] in the queue.
  static void insertToQueue(int index, List<Song> songs) {
    // Save queue order
    _unshuffle();
    _setOrigins();
    bool contains = true;
    for (var song in songs) {
      song = song.copyWith();
      _deduplicateSong(song);
      state.queues.current.insert(index, song);
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
  static bool removeFromQueue(Song song) {
    final queues = state.queues;
    final bool removed;
    if (queues.current.length == 1) {
      removed = queues.current.remove(song);
      if (removed) {
        resetQueueAsFallback();
      }
    } else {
      final current = song == state.currentSong;
      Song? nextSong;
      if (current) {
        nextSong = state.queues.current.getNext(song);
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
  static Song? removeFromQueueAt(int index) {
    final queues = state.queues;
    final Song? song;
    if (queues.current.length == 1) {
      song = queues.current.removeAt(0);
      resetQueueAsFallback();
    } else {
      if (index == state.currentSongIndex) {
        MusicPlayer.instance.pause();
        MusicPlayer.instance.setSong(state.queues.current.getNextAt(index));
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
  static void removeAllFromQueueAt(List<int> indexes) {
    final queues = state.queues;
    if (indexes.length >= queues.current.length) {
      resetQueueAsFallback();
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
        /// and imporove this
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

  /// A shorthand for setting [QueueType.origin].
  static void setOriginQueue({
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
  static void resetQueue() {
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
  static void resetQueueAsFallback() {
    setQueue(
      type: QueueType.allSongs,
      modified: false,
      shuffled: false,
    );
    MusicPlayer.instance.pause();
    MusicPlayer.instance.setSong(state.queues.current.songs[0]);
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
  static void setQueue({
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
      type != QueueType.origin ||
      queues._origin != null ||
      origin != null,
      "When you set `origin` queue and currently none set, you must provide the `origin` paramenter",
    );
    assert(
      type != QueueType.searched ||
      queues._searchQuery != null ||
      searchQuery != null,
      "When you set `searched` queue and currently none set, you must provide the `searchQuery` paramenter",
    );

    type ??= queues._type;
    if (type == QueueType.arbitrary) {
      modified = false;
    }

    if (type == QueueType.origin) {
      if (origin != null) {
        queues._origin = origin;
        Prefs.songOrigin.set(origin);
        if (setIdMapFromPlaylist && origin is Playlist) {
          state.idMap.clear();
          state.idMap.addAll(origin.idMap);
          state.idMapDirty = false;
        _idMapSerializer.save(state.idMap);
        }
      }
    } else {
      queues._origin = null;
      Prefs.songOrigin.delete();
    }

    if (type == QueueType.searched) {
      if (searchQuery != null) {
        queues._searchQuery = searchQuery;
        Prefs.searchQuery.set(searchQuery);
      }
    } else {
      queues._searchQuery = null;
      Prefs.searchQuery.delete();
    }

    modified ??= queues._modified;
    shuffled ??= queues._shuffled;

    queues._type = type;
    Prefs.queueType.set(type);

    queues._modified = modified;
    Prefs.queueModified.set(modified);

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
      } else if (type == QueueType.allSongs && !modified) {
        queues._queue.setSongs(List.from(state.allSongs.songs));
      }
    }

    queues._shuffled = shuffled;
    Prefs.queueShuffled.set(shuffled);

    if (save) {
      state.queues._saveCurrentQueue();
    }

    if (state.idMap.isNotEmpty &&
        !modified &&
        !shuffled &&
        type != QueueType.origin &&
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
        type: QueueType.allSongs,
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

  /// Returns content of specified type with ID.
  static T? getContentById<T extends Content>(int id, [Type? contentType]) {
    if ((contentType ?? T) == Album)
      return state.albums[id] as T?;
    return getContent<T>(contentType).firstWhereOrNull((el) => el.id == id);
  }

  /// Refetches all the content.
  static Future<void> refetchAll() async {
    await Future.wait([
      for (final contentType in Content.enumerate())
        refetch(contentType: contentType),
    ]);
    if (!disposed)
      await MusicPlayer.instance.restoreLastSong();
  }

  /// Refetches content by the `T` content type.
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
        if (disposed) {
          return;
        }
        final origin = state.queues.origin;
        if (origin is Album && state.albums[origin.id] == null) {
          resetQueueAsFallback();
        }
        sort<Album>(emitChangeEvent: false);
      },
      playlist: () async {
        state.playlists = await ContentChannel.retrievePlaylists();
        if (disposed) {
          return;
        }
        final origin = state.queues.origin;
        if (origin is Playlist && state.playlists.firstWhereOrNull((el) => el == origin) == null) {
          resetQueueAsFallback();
        }
        sort<Playlist>(emitChangeEvent: false);
      },
      artist: () async {
        state.artists = await ContentChannel.retrieveArtists();
        if (disposed) {
          return;
        }
        final origin = state.queues.origin;
        if (origin is Artist && state.artists.firstWhereOrNull((el) => el == origin) == null) {
          resetQueueAsFallback();
        }
        sort<Artist>(emitChangeEvent: false);
      },
    )();
    if (emitChangeEvent) {
      stateNullable?.emitContentChange();
    }
  }

  /// Searches for content by given [query] and the `T` content type.
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
  static void sort<T extends Content>({ Type? contentType, Sort<T>? sort, bool emitChangeEvent = true }) {
    final sorts = state.sorts;
    sort ??= sorts.getValue<T>(contentType) as Sort<T>;
    contentPick<T, VoidCallback>(
      contentType: contentType,
      song: () {
        final _sort = sort! as SongSort;
        sorts.setValue<Song>(_sort);
        Prefs.songSort.set(_sort);
        final comparator = _sort.comparator;
        state.allSongs.songs.sort(comparator);
      },
      album: () {
        final _sort = sort! as AlbumSort;
        sorts.setValue<Album>(_sort);
        Prefs.albumSort.set(_sort);
        final comparator = _sort.comparator;
        state.albums = Map.fromEntries(state.albums.entries.toList()
          ..sort((a, b) {
            return comparator(a.value, b.value);
          }));
      },
      playlist: () {
        final _sort = sort! as PlaylistSort;
        sorts.setValue<Playlist>(_sort);
        Prefs.playlistSort.set(_sort);
        final comparator = _sort.comparator;
        state.playlists.sort(comparator);
      },
      artist: () {
        final _sort = sort! as ArtistSort;
        sorts.setValue<Artist>(_sort);
        Prefs.artistSort.set(_sort);
        final comparator = _sort.comparator;
        state.artists.sort(comparator);
      },
    )();
    // Emit event to track change stream
    if (emitChangeEvent) {
      state.emitContentChange();
    }
  }

  /// Filters out non-source songs (with negative IDs), and asserts that.
  ///
  /// That ensure invalid items are never passed to platform and allows to catch
  /// invalid states in debug mode.
  static Set<Song> _ensureSongsAreSource(Set<Song> songs) {
    return songs.fold<Set<Song>>({}, (prev, el) {
      if (el.id >= 0) {
        prev.add(el);
      } else {
        assert(false, "All IDs must be source (non-negative)");
      }
      return prev;
    }).toSet();
  }

  /// Sets songs' favorite flag to [value].
  ///
  /// The songs must have a source ID (non-negative).
  static Future<void> setSongsFavorite(Set<Song> songs, bool value) async {
    // todo: implement
    songs = _ensureSongsAreSource(songs);
    if (sdkInt >= 30) {
      try {
        final result = await ContentChannel.setSongsFavorite(songs, value);
        if (result) {
          await refetch<Song>();
        }
      } catch (ex, stack) {
        FirebaseCrashlytics.instance.recordError(
          ex,
          stack,
          reason: 'in setSongsFavorite',
        );
        ShowFunctions.instance.showToast(
          msg: staticl10n.oopsErrorOccurred,
        );
        debugPrint('setSongsFavorite error: $ex');
      }
    } else {
     
    }
  }

  /// Deletes a set of songs.
  ///
  /// The songs must have a source ID (non-negative).
  static Future<void> deleteSongs(Set<Song> songs) async {
    songs = _ensureSongsAreSource(songs);

    void _removeFromState() {
      for (final song in songs)
        state.allSongs.byId.remove(song.id);
      removeObsolete();
    }

    // On Android R the deletion is performed with OS dialog.
    if (sdkInt < 30) {
      _removeFromState();
    }

    try {
      final result = await ContentChannel.deleteSongs(songs);
      await refetchAll();
      if (sdkInt >= 30 && result) {
        _removeFromState();
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
      debugPrint('deleteSongs error: $ex');
    }
  }

  /// When playlists are being updated in any way, there's a chance
  /// that after refetching a playlist, it will contain a song with
  /// ID that we don't know yet.
  ///
  /// To avoid this, both songs and playlists should be refetched.
  static Future<void> refetchSongsAndPlaylists() async {
    await Future.wait([
      refetch<Song>(emitChangeEvent: false),
      refetch<Playlist>(emitChangeEvent: false),
    ]);
    stateNullable?.emitContentChange();
  }

  /// Checks if there's are playlists with names like "name" and "name (1)" and:
  /// * if yes, increases the number by one from the max and returns string with it
  /// * else returns the string unmodified.
  static Future<String> correctPlaylistName(String name) async {
    // Update the playlist in case they are outdated
    await refetch<Playlist>(emitChangeEvent: false);

    // If such name already exists, find the max duplicate number and make the name
    // "name (max + 1)" instead.
    if (state.playlists.firstWhereOrNull((el) => el.name == name) != null) {
      // Regexp to search for names like "name" and "name (1)"
      // Things like "name (1)(1)" will not be matched
      //
      // Part of it is taken from https://stackoverflow.com/a/17779833/9710294
      //
      // Explanation:
      // * `name`: playlist name
      // * `(`: begin optional capturing group, because we need to match the name without parentheses
      // * ` `: match space
      // * `\(`: match an opening parentheses
      // * `(`: begin capturing group
      // * `[^)]+`: match one or more non ) characters
      // * `)`: end capturing group
      // * `\)` : match closing parentheses
      // * `)?`: close optional capturing group\
      // * `$`: match string end
      final regexp = RegExp(name.toString() + r'( \(([^)]+)\))?$');
      int? max; 
      for (final el in state.playlists) {
        final match = regexp.firstMatch(el.name);
        if (match != null) {
          final capturedNumber = match.group(2);
          final number = capturedNumber == null ? 0 : int.tryParse(capturedNumber);
          if (number != null && (max == null || max < number)) {
            max = number;
          }
        }
      }
      if (max != null) {
        name = '$name (${max + 1})';
      }
    }
  
    return name;
  }

  /// Creates a playlist with a given name and returns a corrected with [correctPlaylistName] name.
  static Future<String> createPlaylist(String name) async {
    name = await correctPlaylistName(name);
    await ContentChannel.createPlaylist(name);
    await refetchSongsAndPlaylists();
    return name;
  }

  /// Renames a playlist and:
  /// * if operation was successful returns a corrected with [correctPlaylistName] name
  /// * else returns null
  static Future<String?> renamePlaylist(Playlist playlist, String name) async {
    try {
      name = await correctPlaylistName(name);
      await ContentChannel.renamePlaylist(playlist, name);
      await refetchSongsAndPlaylists();
      return name;
    } on ContentChannelException catch(ex) {
      if (ex == ContentChannelException.playlistNotExists)
        return null;
      rethrow;
    }
  }

  /// Inserts songs in the playlist at the given [index].
  static Future<void> insertSongsInPlaylist({ required int index, required List<Song> songs, required Playlist playlist }) async {
    await ContentChannel.insertSongsInPlaylist(index: index, songs: songs, playlist: playlist);
    await refetchSongsAndPlaylists();
  }

  /// Moves song in playlist, returned value indicates whether the operation was successful.
  static Future<void> moveSongInPlaylist({ required Playlist playlist, required int from, required int to, bool emitChangeEvent = true }) async {
    if (from != to) {
      await ContentChannel.moveSongInPlaylist(playlist: playlist, from: from, to: to);
      if (emitChangeEvent)
        await refetchSongsAndPlaylists();
    }
  }

  /// Removes songs from playlist at given [indexes].
  static Future<void> removeFromPlaylistAt({ required List<int> indexes, required Playlist playlist }) async {
    await ContentChannel.removeFromPlaylistAt(indexes: indexes, playlist: playlist);
    await refetchSongsAndPlaylists();
  }

  /// Deletes playlists.
  static Future<void> deletePlaylists(List<Playlist> playlists) async {
    try {
      await ContentChannel.removePlaylists(playlists);
      await refetchSongsAndPlaylists();
    } catch (ex, stack) {
      FirebaseCrashlytics.instance.recordError(
        ex,
        stack,
        reason: 'in deletePlaylists',
      );
      ShowFunctions.instance.showToast(
        msg: staticl10n.deletionError,
      );
      debugPrint('deletePlaylists error: $ex');
    }
  }

  //****************** Private methods for restoration *****************************************************

  /// Restores [sorts] from [Prefs].
  static Future<void> _restoreSorts() async {
    state.sorts = ContentMap({
      Song: Prefs.songSort.get(),
      Album: Prefs.albumSort.get(),
      Playlist: Prefs.playlistSort.get(),
      Artist: Prefs.artistSort.get(),
    });
  }

  /// Restores saved queues.
  ///
  /// * If stored queue becomes empty after restoration (songs do not exist anymore), will fall back to not modified [QueueType.all].
  /// * If saved song origin songs are restored successfully, but the playlist itself cannot be found, will fall back to [QueueType.arbitrary].
  /// * In all other cases it will restore as it was.
  static Future<void> _restoreQueue() async {
    final shuffled = Prefs.queueShuffled.get();
    final modified = Prefs.queueModified.get();
    final songOrigin = Prefs.songOrigin.get();
    final type =  Prefs.queueType.get();
  
    state.idMap = await _idMapSerializer.read();

    final List<Song> queueSongs = [];
    try {
      final rawQueue = await state.queues._queueSerializer.read();
      for (final item in rawQueue) {
        final id = item.id;
        final origin = SongOrigin.originFromEntry(item.originEntry);
        var song = state.allSongs.byId.get(ContentUtils.getSourceId(id, origin: origin));
        if (song != null) {
          song = song.copyWith(id: id);
          song.duplicationIndex = item.duplicationIndex;
          song.origin = origin;
          queueSongs.add(song);
        }
      }
    } catch(ex, stack) {
      FirebaseCrashlytics.instance.recordError(
        ex,
        stack,
        reason: 'in rawQueue restoration',
      );
    }

    final List<Song> shuffledSongs = [];
    try {
      if (shuffled == true) {
        final rawShuffledQueue = await state.queues._shuffledSerializer.read();
        for (final item in rawShuffledQueue) {
          final id = item.id;
          final origin = SongOrigin.originFromEntry(item.originEntry);
          var song = state.allSongs.byId.get(ContentUtils.getSourceId(id, origin: origin));
          if (song != null) {
            song = song.copyWith(id: id);
            song.duplicationIndex = item.duplicationIndex;
            song.origin = origin;
            shuffledSongs.add(song);
          }
        }
      }
    } catch(ex, stack) {
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
        searchQuery: Prefs.searchQuery.get(),
        save: false,
      );
    }
  }
}


class ContentUtils {
  /// Android unknown artist.
  static const unknownArtist = '<unknown>';

  /// If artist is unknown returns localized artist.
  /// Otherwise returns artist as is.
  static String localizedArtist(String artist, AppLocalizations l10n) {
    return artist != unknownArtist ? artist : l10n.artistUnknown;
  }

  static const String dot = '•';

  /// Joins list with the [dot].
  static String joinDot(List list) {
    if (list.isEmpty)
      return '';
    var result = list.first;
    for (int i = 1; i < list.length; i++) {
      final string = list[i].toString();
      if (string.isNotEmpty) {
        result += ' $dot $string';
      }
    }
    return result;
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

  /// Checks whether a song origin is currently playing.
  static bool originIsCurrent(SongOrigin origin) {
    final queues = ContentControl.state.queues;
    return queues.type == QueueType.origin && origin == queues.origin ||
           queues.type != QueueType.origin && origin == ContentControl.state.currentSongOrigin;
  }

  /// Returns a default icon for a [PersistentQueue].
  static IconData persistentQueueIcon(PersistentQueue queue) {
    return persistentQueuePick<PersistentQueue, IconData>(
      contentType: queue.runtimeType,
      album: Album.icon,
      playlist: Playlist.icon,
    );
  }

  /// Computes the duration of mulitple [songs] and returs it as formatted string.
  static String bulkDuration(List<Song> songs) {
    final duration = Duration(milliseconds: songs.fold(0, (prev, el) => prev + el.duration));
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final buffer = StringBuffer();
    if (hours > 0) {
      if (hours.toString().length < 2) {
        buffer.write(0);
      }
      buffer.write(hours);
      buffer.write(':');
    }
    if (minutes > 0) {
      if (minutes.toString().length < 2) {
        buffer.write(0);
      }
      buffer.write(minutes);
      buffer.write(':');
    }
    if (seconds > 0) {
      if (seconds.toString().length < 2) {
        buffer.write(0);
      }
      buffer.write(seconds);
    }
    return buffer.toString();
  }

  /// Joins and returns a list of all songs of specified [origins] list.
  static List<Song> joinSongOrigins(List<SongOrigin> origins) {
    final List<Song> songs = [];
    for (final origin in origins) {
      for (final song in origin.songs) {
        song.origin = origin;
        songs.add(song);
      }
    }
    return songs;
  }

  /// Joins specified [origins] list and returns a list of all songs and a
  /// shuffled variant of it.
  static ShuffleResult shuffleSongOrigins(List<SongOrigin> origins) {
    final List<Song> songs = joinSongOrigins(origins);
    final List<Song> shuffledSongs = [];
    for (final origin in List<SongOrigin>.from(origins)..shuffle()) {
      for (final song in origin.songs) {
        song.origin = origin;
        shuffledSongs.add(song);
      }
    }
    return ShuffleResult(
      songs,
      shuffledSongs,
    );
  }

  /// Accepts a collection of content, exctracts songs from each entry
  /// and returns a one flattened array of songs.
  static List<Song> flatten(List<Content> collection) {
    final List<Song> songs = [];
    for (final content in collection) {
      if (content is Song) {
        songs.add(content);
      } else if (content is Album) {
        songs.addAll(content.songs);
      } else if (content is Playlist) {
        songs.addAll(content.songs);
      } else if (content is Artist) {
        songs.addAll(content.songs);
      } else {
        throw UnimplementedError();
      }
      assert(() {
        contentPick<Song, void>(
          song: null,
          album: null,
          playlist: null,
          artist: null,
        );
        return true;
      }());
    }
    return songs;
  }

  /// Receives a selection data set, extracts all types of contents,
  /// sorts them by index in ascending order and returns the result.
  ///
  /// See also discussion in [SelectionEntry].
  static SortAndPackResult selectionSortAndPack(Set<SelectionEntry<Content>> data) {
    final List<SelectionEntry<Song>> songs = [];
    final List<SelectionEntry<Album>> albums = [];
    final List<SelectionEntry<Playlist>> playlists = [];
    final List<SelectionEntry<Artist>> artists = [];
    for (final entry in data) {
      if (entry is SelectionEntry<Song>) {
        songs.add(entry);
      } else if (entry is SelectionEntry<Album>) {
        albums.add(entry);
      } else if (entry is SelectionEntry<Playlist>) {
        playlists.add(entry);
      } else if (entry is SelectionEntry<Artist>) {
        artists.add(entry);
      } else {
        throw UnimplementedError();
      }
    }
    assert(() {
      contentPick<Song, void>(
        song: null,
        album: null,
        playlist: null,
        artist: null,
      );
      return true;
    }());
    songs.sort((a, b) => a.index.compareTo(b.index));
    albums.sort((a, b) => a.index.compareTo(b.index));
    playlists.sort((a, b) => a.index.compareTo(b.index));
    artists.sort((a, b) => a.index.compareTo(b.index));
    return SortAndPackResult(
      songs.map((el) => el.data).toList(),
      albums.map((el) => el.data).toList(),
      playlists.map((el) => el.data).toList(),
      artists.map((el) => el.data).toList(),
    );
  }

  /// Returns the source song ID based of the provided id map.
  ///
  /// If [idMap] is null, [ContentState.idMap] will be used.
  static int getSourceId(int id, {required SongOrigin? origin, IdMap? idMap}) {
    return id < 0
      ? (idMap ?? ContentControl.state.idMap)[IdMapKey(id: id, originEntry: origin?.toSongOriginEntry())]!
      : id;
  }

  /// Checks the [song] for being a duplicate within the [origin], and if
  /// it is, changes its ID and saves the mapping to the original source ID to
  /// an [idMap].
  ///
  /// The [list] is the list of songs contained in this origin.
  ///
  /// This must be called before the song is inserted to the queue, otherwise
  /// the song might be conidiered as a duplicate of itself, which will be incorrect.
  /// The function asserts that.
  ///
  /// Marks the queue as dirty, so the next [setQueue] will save it.
  /// 
  /// The returned value indicates whether the duplicate song was found and
  /// [source] was changed.
  static bool deduplicateSong({
    required Song song,
    required List<Song> list,
    required IdMap idMap,
  }) {
    assert(() {
      final sourceSong = ContentControl.state.allSongs.byId.get(song.sourceId);
      if (identical(sourceSong, song)) {
        throw ArgumentError(
          "Tried to handle duplicate on the source song in `allSongs`. This may lead " 
          "to that the source song ID is lost, copy the song first",
        );
      }
      return true;
    }());
    assert(() {
      final sameSong = list.firstWhereOrNull((el) => identical(el, song));
      if (identical(sameSong, song)) {
        throw ArgumentError(
          "The provided `song` is contained in the given `list`. This is incorrect " 
          "usage of this function, it should be called before the song is inserted to "
          "the `list`",
        );
      }
      return true;
    }());
    final candidates = list.where((el) => el.id == song.id);
    if (candidates.isNotEmpty) {
      final map = idMap;
      final newId = -(map.length + 1);
      map[IdMapKey(
        id: newId,
        originEntry: song.origin?.toSongOriginEntry(),
      )] = song.sourceId;
      song.id = newId;
      return true;
    }
    return false;
  }
}

/// Result of [ContentUtils.shuffleSongOrigins].
class ShuffleResult {
  const ShuffleResult(this.songs, this.shuffledSongs);
  final List<Song> songs;
  final List<Song> shuffledSongs;
}


/// Result of [ContentUtils.selectionSortAndPack].
class SortAndPackResult {
  final List<Song> songs;
  final List<Album> albums;
  final List<Playlist> playlists;
  final List<Artist> artists;

  SortAndPackResult(this.songs, this.albums, this.playlists, this.artists);

  List<Content> get merged => [
    ...songs,
    ...albums,
    ...playlists,
    ...artists,
  ];
}