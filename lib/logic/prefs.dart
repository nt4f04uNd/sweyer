import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as constants;

/// Class to save and get [SharedPreferences].
///
/// It is a unite container for all the shared preferences of the application,
/// though it doesn't contain settings prefs, that are used in the settings route,
/// they can be found in [Settings] class.
///
/// It also contains prefs that aren't used in dart side directly, but only on native.
abstract class Prefs {
  /// Search history list.
  static const searchHistory = StringListPref('search_history', []);

  /// Track position, stored in seconds.
  static const songPosition = IntPref('song_position', 0);

  /// Last playing track id.
  static const songId = NullableIntPref('song_id');

  /// Loop mode.
  static const loopMode = BoolPref('loop_mode', false);

  //****************** Sorts ***********************

  /// Sort feature used for song list.
  static final songSort = JsonPref<SongSort>(
    'songs_sort',
    SongSort.defaultOrder(SongSortFeature.dateModified),
    fromJson: (value) => SongSort.fromMap(value as Map),
    toJson: (value) => value.toMap(),
  );

  /// Sort feature used for album list.
  static final albumSort = JsonPref<AlbumSort>(
    'album_sort',
    AlbumSort.defaultOrder(AlbumSortFeature.year),
    fromJson: (value) => AlbumSort.fromMap(value as Map),
    toJson: (value) => value.toMap(),
  );

  /// Sort feature used for playlist list.
  static final playlistSort = JsonPref<PlaylistSort>(
    'playlist_sort',
    PlaylistSort.defaultOrder(PlaylistSortFeature.dateAdded),
    fromJson: (value) => PlaylistSort.fromMap(value as Map),
    toJson: (value) => value.toMap(),
  );

  /// Sort feature used for artist list.
  static final artistSort = JsonPref<ArtistSort>(
    'artist_sort',
    ArtistSort.defaultOrder(ArtistSortFeature.name),
    fromJson: (value) => ArtistSort.fromMap(value as Map),
    toJson: (value) => value.toMap(),
  );

  /// Last played [QueueType].
  static final queueType = EnumPref<QueueType>(
    'queue_type',
    QueueType.values,
    QueueType.allSongs,
  );

  /// Last [SongOrigin].
  static final songOrigin = NullableJsonPref<SongOrigin>(
    'song_origin',
    fromJson: (value) => value == null ? null : SongOrigin.originFromEntry(SongOriginEntry.fromMap(value as Map)),
    toJson: (value) => value?.toSongOriginEntry().toMap(),
  );

  /// Last search query.
  static const searchQuery = NullableStringPref('search_query');

  /// Whether the saved queue is modified.
  static const queueModified = BoolPref('queue_modified', false);

  /// Whether the saved queue is shuffled.
  static const queueShuffled = BoolPref('queue_shuffled', false);

  /// Developer mode pref.
  ///
  /// When `true`:
  /// * special dev menu in the drawer gets unlocked
  /// * error snackbars are shown
  /// * song info button available in the top right menu of [PlayerRoute].
  static final devMode = PrefNotifier(
    const BoolPref('dev_mode', false),
  );
}

class SearchHistory {
  SearchHistory._();
  static final instance = SearchHistory._();

  /// Before accessing this variable, you mast call [load].
  List<String>? history;

  /// Loads the history.
  Future<void> load() async {
    history ??= List.from(Prefs.searchHistory.get());
  }

  /// Clears the history.
  Future<void> clear() async {
    if (history != null) {
      history!.clear();
    } else {
      history = [];
    }
    await Prefs.searchHistory.set(const []);
  }

  /// Removes an entry from history at [index].
  Future<void> removeAt(int index) async {
    await load();
    history!.removeAt(index);
    await Prefs.searchHistory.set(history!);
  }

  /// Adds an [entry] to history.
  /// Automatically calls [load].
  Future<void> add(String entry) async {
    entry = entry.trim();
    if (entry.isNotEmpty) {
      await load();
      // Remove if this input is in array
      history!.removeWhere((el) => el == entry);
      history!.insert(0, entry);
      if (history!.length > constants.Config.searchHistoryLength) {
        history!.removeLast();
      }
      await Prefs.searchHistory.set(history!);
    }
  }
}

/// Prefs specially for settings route.
abstract class Settings {
  /// Stores theme brightness.
  ///
  /// * `true` means light
  /// * `false` means dark
  static final lightThemeBool = PrefNotifier(
    const BoolPref('setting_light_theme', false),
  );

  /// Stores primary color int value.
  static final primaryColorInt = PrefNotifier(
    IntPref('setting_primary_color', constants.Theme.defaultPrimaryColor.value),
  );

  /// Whether a confirmation toast should be displayed when exiting
  /// the app with back button.
  static final confirmExitingWithBackButton = PrefNotifier(
    const BoolPref('confirm_exiting_with_back_button', true),
  );

  /// Whether to use `MediaStore` to save favorite songs on Android 11 and above.
  static final useMediaStoreForFavoriteSongs = PrefNotifier(
    const BoolPref('use_media_store_for_favorite_songs', true),
  );

  static final playerInterfaceColorStyle = PrefNotifier(
    EnumPref(
      'player_interface_color_style',
      PlayerInterfaceColorStyle.values,
      PlayerInterfaceColorStyle.artColor,
    ),
  );
}
