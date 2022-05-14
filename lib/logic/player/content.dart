import 'dart:async';

import 'package:collection/collection.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:quick_actions/quick_actions.dart';
import 'package:rxdart/rxdart.dart';
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

  /// Returs a value per `T` [Content] from the map.
  /// 
  /// If [key] was explicitly provided, will use it instead.
  V? getValue<T extends Content>([Type? key]) {
    assert(
      Content.enumerate().contains(key ?? T),
      "Specified type must be a subtype of Content",
    );
    return _map[key ?? T];
  }

  /// Puts a [value] typed with `T` into the map.
  ///
  /// If [key] was explicitly provided, will use it instead.
  void setValue<T extends Content>(V value, {Type? key}) {
    assert(
      Content.enumerate().contains(key ?? T),
      "Specified type must be a subtype of Content",
    );
    _map[key ?? T] = value;
  }

  /// Look up the value of [key], or add a new entry if it isn't there.
  ///
  /// If [key] was explicitly provided, will use it instead.
  V putIfAbsent<T extends Content>(V Function() ifAbsent, {Type? key}) {
    assert(
      Content.enumerate().contains(key ?? T),
      "Specified type must be a subtype of Content",
    );
    return _map.putIfAbsent(key ?? T, ifAbsent);
  }

  /// Removes all entries from the map.
  void clear() {
    _map.clear();
  }
}

/// A container for list of all content types.
///
/// This is like a [ContentMap] that contains lists and
/// always guarantees to have a value in it for given content type.
class ContentTuple {
  final _map = ContentMap<List<Content>>();

  ContentTuple(
    List<Song> songs,
    List<Album> albums,
    List<Playlist> playlists,
    List<Artist> artists,
  ) : assert(() {
        contentPick<Song, void>(
          song: null,
          album: null,
          playlist: null,
          artist: null,
        );
        return true;
      }()) {
        _map.setValue<Song>(songs);
        _map.setValue<Album>(albums);
        _map.setValue<Playlist>(playlists);
        _map.setValue<Artist>(artists);
      }

  List<Song> get songs => _map.getValue<Song>()! as List<Song>;
  List<Album> get albums => _map.getValue<Album>()! as List<Album> ;
  List<Playlist> get playlists => _map.getValue<Playlist>()! as List<Playlist>;
  List<Artist> get artists => _map.getValue<Artist>()! as List<Artist>;

  List<T> get<T extends Content>([Type? contentType]) => _map.getValue<T>(contentType)! as List<T>;

  List<Content> get merged => [
    for (final content in _map.values)
      ...content,
  ];

  bool get empty => _map.values.every((element) => element.isEmpty);
  bool get notEmpty => _map.values.any((element) => element.isNotEmpty);

  bool any(bool Function(Content element) test) {
    for (final contentList in _map.values) {
      for (final content in contentList) {
        if (test(content)) {
          return true;
        }
      }
    }
    return false;
  }
}

/// Represents the state in [ContentControl].
@visibleForTesting
class ContentState {
  /// All songs in the application.
  /// This list not should be modified in any way, except for sorting.
  Queue allSongs = Queue(<Song>[]);
  Map<int, Album> albums = <int, Album>{};
  List<Playlist> playlists = <Playlist>[];
  List<Artist> artists = <Artist>[];

  /// Contains various [Sort]s of the application.
  /// Sorts of specific [Queues] like [Album]s are stored separately. // TODO: this is currently not implemented - remove this todo when it will be
  ///
  /// Restored in [ContentControl._restoreSorts].
  late final ContentMap<Sort> sorts;
}

@visibleForTesting
class ContentRepository {
  final songSort = Prefs.songSort;
  final albumSort = Prefs.albumSort;
  final playlistSort = Prefs.playlistSort;
  final artistSort = Prefs.artistSort;
}

// class _WidgetsBindingObserver extends WidgetsBindingObserver {
//   @override
//   void didChangeLocales(List<Locale>? locales) {
//     ContentControl._setQuickActions();
//   }
// }

/// Contols content state and allows to perform related actions, for example:
///
/// * fetch songs
/// * search
/// * sort
/// * create playlist
/// * delete songs
/// * etc.
///
class ContentControl extends Control {
  static ContentControl instance = ContentControl();

  @visibleForTesting
  late final repository = ContentRepository();

  ContentState get state => _state!;
  ContentState? _state;
  ContentState? get stateNullable => _state;
  bool get _empty => stateNullable?.allSongs.isEmpty ?? true;

  /// A stream of changes over content.
  /// Called whenever [Content] (queues, songs, albums, etc. changes).
  Stream<void> get onContentChange => _contentSubject.stream;
  late PublishSubject<void> _contentSubject;

  /// Notifies when active selection controller changes.
  /// Will receive null when selection closes.
  late ValueNotifier<ContentSelectionController?> selectionNotifier;

  /// Emit event to [onContentChange].
  void emitContentChange() {
    if (!disposed.value)
      _contentSubject.add(null);
  }

  // /// Recently pressed quick action.
  // final quickAction = BehaviorSubject<QuickAction>();
  // final QuickActions _quickActions = QuickActions();
  // final bindingObserver = _WidgetsBindingObserver();

  /// Represents songs fetch on app start.
  bool get initializing => _initializeCompleter != null;
  Completer<void>? _initializeCompleter;

  /// The main data app initialization function, inits all queues.
  /// Also handles no-permissions situations.
  @override
  Future<void> init() async {
    super.init();
    if (stateNullable == null) {
      _state = ContentState();
      _contentSubject = PublishSubject();
      selectionNotifier = ValueNotifier(null);
    }
    if (Permissions.instance.granted) {
      // TODO: prevent initalizing if already initizlied
      _initializeCompleter = Completer();
      emitContentChange(); // update UI to show "Searching songs" screen
      _restoreSorts();
      await Future.any([
        _initializeCompleter!.future,
        Future.wait([
          for (final contentType in Content.enumerate())
            refetch(contentType: contentType, updateQueues: false, emitChangeEvent: false),
        ]),
      ]);
      if (!_empty && _initializeCompleter != null && !_initializeCompleter!.isCompleted) {
        // _initQuickActions();
        await QueueControl.instance.init();
        PlaybackControl.instance.init();
        await MusicPlayer.instance.init();
        await FavoritesControl.instance.init();
      }
      _initializeCompleter = null;
    }
    // Emit event to track change stream
    emitContentChange();
  }

  /// Disposes the [state] and stops the currently going [init] process,
  /// if any.
  @override
  void dispose() {
    if (!disposed.value) {
      // WidgetsBinding.instance!.removeObserver(bindingObserver);
      // _quickActions.clearShortcutItems();
      _initializeCompleter?.complete();
      _initializeCompleter = null;
      // TODO: this might still deliver some pedning events to listeneres, see https://github.com/dart-lang/sdk/issues/45653
      _contentSubject.close();
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        selectionNotifier.dispose();
      });
      _state = null;
      QueueControl.instance.dispose();
      PlaybackControl.instance.dispose();
      MusicPlayer.instance.dispose();
      FavoritesControl.instance.dispose();
    }
    super.dispose();
  }

  /// Restores [sorts] from [Prefs].
  Future<void> _restoreSorts() async {
    state.sorts = ContentMap({
      Song: repository.songSort.get(),
      Album: repository.albumSort.get(),
      Playlist: repository.playlistSort.get(),
      Artist: repository.artistSort.get(),
    });
  }

  // void _initQuickActions() {
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

  // Future<void> _setQuickActions() {
  //   return _quickActions.setShortcutItems(<ShortcutItem>[
  //     ShortcutItem(type: QuickAction.search.value, localizedTitle: staticl10n.search, icon: 'round_search_white_36'),
  //     ShortcutItem(type: QuickAction.shuffleAll.value, localizedTitle: staticl10n.shuffleAll, icon: 'round_shuffle_white_36'),
  //     ShortcutItem(type: QuickAction.playRecent.value, localizedTitle: staticl10n.playRecent, icon: 'round_play_arrow_white_36')
  //   ]);
  // }
  
  /// Returns content of specified type.
  List<T> getContent<T extends Content>({
    Type? contentType,
    bool filterFavorite = false,
  }) {
    if (filterFavorite) {
      return contentPick<T, ValueGetter<List<T>>>(
        contentType: contentType,
        song: () => ContentUtils.filterFavorite(state.allSongs.songs).toList() as List<T>,
        album: () => ContentUtils.filterFavorite(state.albums.values).toList() as List<T>,
        playlist: () => ContentUtils.filterFavorite(state.playlists).toList() as List<T>,
        artist: () => ContentUtils.filterFavorite(state.artists).toList() as List<T>,
      )();
    }
    return contentPick<T, ValueGetter<List<T>>>(
      contentType: contentType,
      song: () => state.allSongs.songs as List<T>,
      album: () => state.albums.values.toList() as List<T>,
      playlist: () => state.playlists as List<T>,
      artist: () => state.artists as List<T>,
    )();
  }

  /// Returns content of specified type with ID.
  T? getContentById<T extends Content>(int id, [Type? contentType]) {
    if ((contentType ?? T) == Album)
      return state.albums[id] as T?;
    return getContent<T>(contentType: contentType).firstWhereOrNull((el) => el.id == id);
  }

  /// Refetches all the content.
  Future<void> refetchAll() async {
    await Future.wait([
      for (final contentType in Content.enumerate())
        refetch(contentType: contentType),
    ]);
    if (!disposed.value)
      await MusicPlayer.instance.restoreLastSong();
  }

  /// Refetches content by the `T` content type.
  ///
  /// When [updateQueues] is `true`, checks checks the queues for obsolete songs by calling [QueueControl.removeObsolete].
  /// (only works with [Song]s).
  Future<void> refetch<T extends Content>({
    Type? contentType,
    bool updateQueues = true,
    bool emitChangeEvent = true,
  }) async {
    if (disposed.value)
      return;
    await contentPick<T, AsyncCallback>(
      contentType: contentType,
      song: () async {
        state.allSongs.setSongs(await ContentChannel.instance.retrieveSongs());
        if (_empty) {
          dispose();
          return;
        }
        sort<Song>(emitChangeEvent: false);
        if (updateQueues) {
          QueueControl.instance.removeObsolete(emitChangeEvent: false);
        }
      },
      album: () async {
        state.albums = await ContentChannel.instance.retrieveAlbums();
        if (disposed.value) {
          return;
        }
        final origin = QueueControl.instance.state.origin;
        if (origin is Album && state.albums[origin.id] == null) {
          QueueControl.instance.resetQueueAsFallback();
        }
        sort<Album>(emitChangeEvent: false);
      },
      playlist: () async {
        state.playlists = await ContentChannel.instance.retrievePlaylists();
        if (disposed.value) {
          return;
        }
        final origin = QueueControl.instance.state.origin;
        if (origin is Playlist && state.playlists.firstWhereOrNull((el) => el == origin) == null) {
          QueueControl.instance.resetQueueAsFallback();
        }
        sort<Playlist>(emitChangeEvent: false);
      },
      artist: () async {
        state.artists = await ContentChannel.instance.retrieveArtists();
        if (disposed.value) {
          return;
        }
        final origin = QueueControl.instance.state.origin;
        if (origin is Artist && state.artists.firstWhereOrNull((el) => el == origin) == null) {
          QueueControl.instance.resetQueueAsFallback();
        }
        sort<Artist>(emitChangeEvent: false);
      },
    )();
    if (emitChangeEvent) {
      emitContentChange();
    }
  }

  /// Searches for content by given [query] and the `T` content type.
  List<T> search<T extends Content>(String query, { Type? contentType }) {
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
  void sort<T extends Content>({ Type? contentType, Sort<T>? sort, bool emitChangeEvent = true }) {
    final sorts = state.sorts;
    sort ??= sorts.getValue<T>(contentType) as Sort<T>;
    contentPick<T, VoidCallback>(
      contentType: contentType,
      song: () {
        final _sort = sort! as SongSort;
        sorts.setValue<Song>(_sort);
        repository.songSort.set(_sort);
        final comparator = _sort.comparator;
        state.allSongs.songs.sort(comparator);
      },
      album: () {
        final _sort = sort! as AlbumSort;
        sorts.setValue<Album>(_sort);
        repository.albumSort.set(_sort);
        final comparator = _sort.comparator;
        state.albums = Map.fromEntries(state.albums.entries.toList()
          ..sort((a, b) {
            return comparator(a.value, b.value);
          }));
      },
      playlist: () {
        final _sort = sort! as PlaylistSort;
        sorts.setValue<Playlist>(_sort);
        repository.playlistSort.set(_sort);
        final comparator = _sort.comparator;
        state.playlists.sort(comparator);
      },
      artist: () {
        final _sort = sort! as ArtistSort;
        sorts.setValue<Artist>(_sort);
        repository.artistSort.set(_sort);
        final comparator = _sort.comparator;
        state.artists.sort(comparator);
      },
    )();
    // Emit event to track change stream
    if (emitChangeEvent) {
      emitContentChange();
    }
  }

  /// Filters out non-source songs (with negative IDs), and asserts that.
  ///
  /// That ensures invalid items are never passed to platform and allows to catch
  /// invalid states in debug mode.
  Set<Song> _ensureSongsAreSource(Set<Song> songs) {
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
  Future<void> setSongsFavorite(Set<Song> songs, bool value) async {
    if (DeviceInfoControl.instance.useScopedStorageForFileModifications) {
      try {
        final result = await ContentChannel.instance.setSongsFavorite(songs, value);
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
    }
  }

  /// Deletes a set of songs.
  ///
  /// The songs must have a source ID (non-negative).
  Future<void> deleteSongs(Set<Song> songs) async {
    songs = _ensureSongsAreSource(songs);

    void _removeFromState() {
      for (final song in songs)
        state.allSongs.byId.remove(song.id);
      if (songs.isEmpty) {
        dispose();
      } else {
        QueueControl.instance.removeObsolete();
      }
    }

    // On Android R the deletion is performed with OS dialog.
    if (DeviceInfoControl.instance.sdkInt < 30) {
      _removeFromState();
    }

    try {
      final result = await ContentChannel.instance.deleteSongs(songs);
      await refetchAll();
      if (DeviceInfoControl.instance.useScopedStorageForFileModifications && result) {
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
  Future<void> refetchSongsAndPlaylists() async {
    await Future.wait([
      refetch<Song>(emitChangeEvent: false),
      refetch<Playlist>(emitChangeEvent: false),
    ]);
    emitContentChange();
  }

  /// Checks if there's are playlists with names like "name" and "name (1)" and:
  /// * if yes, increases the number by one from the max and returns string with it
  /// * else returns the string unmodified.
  Future<String> correctPlaylistName(String name) async {
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
  Future<String> createPlaylist(String name) async {
    name = await correctPlaylistName(name);
    await ContentChannel.instance.createPlaylist(name);
    await refetchSongsAndPlaylists();
    return name;
  }

  /// Renames a playlist and:
  /// * if operation was successful returns a corrected with [correctPlaylistName] name
  /// * else returns null
  Future<String?> renamePlaylist(Playlist playlist, String name) async {
    try {
      name = await correctPlaylistName(name);
      await ContentChannel.instance.renamePlaylist(playlist, name);
      await refetchSongsAndPlaylists();
      return name;
    } on ContentChannelException catch(ex) {
      if (ex == ContentChannelException.playlistNotExists)
        return null;
      rethrow;
    }
  }

  /// Inserts songs in the playlist at the given [index].
  Future<void> insertSongsInPlaylist({ required int index, required List<Song> songs, required Playlist playlist }) async {
    await ContentChannel.instance.insertSongsInPlaylist(index: index, songs: songs, playlist: playlist);
    await refetchSongsAndPlaylists();
  }

  /// Moves song in playlist, returned value indicates whether the operation was successful.
  Future<void> moveSongInPlaylist({ required Playlist playlist, required int from, required int to, bool emitChangeEvent = true }) async {
    if (from != to) {
      await ContentChannel.instance.moveSongInPlaylist(playlist: playlist, from: from, to: to);
      if (emitChangeEvent)
        await refetchSongsAndPlaylists();
    }
  }

  /// Removes songs from playlist at given [indexes].
  Future<void> removeFromPlaylistAt({ required List<int> indexes, required Playlist playlist }) async {
    await ContentChannel.instance.removeFromPlaylistAt(indexes: indexes, playlist: playlist);
    await refetchSongsAndPlaylists();
  }

  /// Deletes playlists.
  Future<void> deletePlaylists(List<Playlist> playlists) async {
    try {
      await ContentChannel.instance.removePlaylists(playlists);
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
}


abstract class ContentUtils {
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
    return song.sourceId == PlaybackControl.instance.currentSong.sourceId;
  }

  /// Checks whether a song origin is currently playing.
  static bool originIsCurrent(SongOrigin origin) {
    final queues = QueueControl.instance.state;
    return queues.type == QueueType.origin && origin == queues.origin ||
           queues.type != QueueType.origin && origin == PlaybackControl.instance.currentSongOrigin;
  }

  /// Returns a default icon for a [Content].
  static IconData contentIcon<T extends Content>([Type? contentType]) {
    return contentPick<T, IconData>(
      contentType: contentType,
      song: Song.icon,
      album: Album.icon, 
      playlist: Playlist.icon,
      artist: Artist.icon,
    );
  }

  /// Returns a string which represents a given content type.
  static String contentTypeString<T extends Content>([Type? contentType]) {
    return contentPick<T, String>(
      contentType: contentType,
      song: 'song',
      album: 'album', 
      playlist: 'playlist',
      artist: 'artist',
    );
  }

  /// Computes the duration of mulitple [songs] and returs it as formatted string.
  static String bulkDuration(Iterable<Song> songs) {
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
  static List<Song> joinSongOrigins(Iterable<SongOrigin> origins) {
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
  static ShuffleResult shuffleSongOrigins(Iterable<SongOrigin> origins) {
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
  static List<Song> flatten(Iterable<Content> collection) {
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

  /// Filter content collection by favorite.
  static Iterable<T> filterFavorite<T extends Content>(Iterable<T> content) {
    return content.where((el) => el.isFavorite);
  }

  /// Receives a selection data set, extracts all types of contents,
  /// and returns the result.
  static ContentTuple selectionPack(Set<SelectionEntry<Content>> data) {
    return _selectionPack(
      data: data,
      sort: false,
    );
  }

  /// Receives a selection data set, extracts all types of contents,
  /// sorts them by index in ascending order and returns the result.
  ///
  /// See also discussion in [SelectionEntry].
  static ContentTuple selectionPackAndSort(Set<SelectionEntry<Content>> data) {
    return _selectionPack(
      data: data,
      sort: true,
    );
  }

  static ContentTuple _selectionPack({
    required Set<SelectionEntry<Content>> data,
    required bool sort,
  }) {
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
    if (sort) {
      songs.sort((a, b) => a.index.compareTo(b.index));
      albums.sort((a, b) => a.index.compareTo(b.index));
      playlists.sort((a, b) => a.index.compareTo(b.index));
      artists.sort((a, b) => a.index.compareTo(b.index));
    }
    return ContentTuple(
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
      ? (idMap ?? QueueControl.instance.state.idMap)[IdMapKey(id: id, originEntry: origin?.toSongOriginEntry())]!
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
      final sourceSong = ContentControl.instance.state.allSongs.byId.get(song.sourceId);
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
