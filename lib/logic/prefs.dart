/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:convert';

import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Class to save and get [SharedPreferences].
///
/// It is a unite container for all the shared preferences of the application,
/// though it doesn't contain settings prefs, that are used in the settings route,
/// they can be found in [Settings] class.
///
/// It also contains prefs that aren't used in dart side directly, but only on native.
abstract class Prefs {
  /// Search history list.
  static final Pref<List<String>> searchHistoryStringList =
      Pref<List<String>>(key: 'search_history', defaultValue: <String>[]);

  /// Track position.
  /// Stored in seconds.
  static final Pref<int> songPositionInt =
      Pref<int>(key: 'song_position', defaultValue: 0);

  /// Last playing track id.
  static final Pref<int?> songIdInt =
      Pref<int>(key: 'song_id', defaultValue: null);

  /// Loop mode.
  static final Pref<bool> loopModeBool =
      Pref<bool>(key: 'loop_mode', defaultValue: false);

  //****************** Sorts ***********************

  /// Sort feature used for song list.
  static final Pref<String> songSortString = Pref<String>(
    key: 'songs_sort',
    defaultValue: jsonEncode(
      SongSort.defaultOrder(SongSortFeature.dateModified).toMap(),
    ),
  );

  /// Sort feature used for album list.
  static final Pref<String> albumSortString = Pref<String>(
    key: 'album_sort',
    defaultValue: jsonEncode(
      AlbumSort.defaultOrder(AlbumSortFeature.year).toMap(),
    ),
  );

  /// Sort feature used for playlist list.
  static final Pref<String> playlistSortString = Pref<String>(
    key: 'playlist_sort',
    defaultValue: jsonEncode(
      PlaylistSort.defaultOrder(PlaylistSortFeature.dateAdded).toMap(),
    ),
  );

  /// Sort feature used for artist list.
  static final Pref<String> artistSortString = Pref<String>(
    key: 'artist_sort',
    defaultValue: jsonEncode(
      ArtistSort.defaultOrder(ArtistSortFeature.name).toMap(),
    ),
  );

  /// Last played [QueueType].
  static final Pref<String> queueTypeString = Pref<String>(
    key: 'queue_type',
    defaultValue: QueueType.all.value,
  );

  /// Last persistent queue.
  static final Pref<int?> persistentQueueId =
      Pref<int>(key: 'persistent_queue_id', defaultValue: null);

  /// Last search query.
  static final Pref<String?> searchQueryString =
      Pref<String>(key: 'search_query', defaultValue: null);

  /// Last [ArbitraryQueueOrigin].
  static final Pref<String?> arbitraryQueueOrigin =
      Pref<String>(key: 'arbitrary_queue_origin', defaultValue: null);

  /// Whether the saved queue is modified or not.
  static final Pref<bool> queueModifiedBool =
      Pref<bool>(key: 'queue_modified', defaultValue: false);

  /// Whether the saved queue is shuffled or not.
  static final Pref<bool> queueShuffledBool =
      Pref<bool>(key: 'queue_shuffled', defaultValue: false);

  /// Developer mode pref.
  /// 
  /// When `true`:
  /// * special dev menu in the drawer gets unlocked
  /// * error snackbars are shown
  /// * song info button available in the top right menu of [PlayerRoute].
  static final Pref<bool> devModeBool =
      Pref<bool>(key: 'dev_mode', defaultValue: false);
}

class SearchHistory {
  SearchHistory._();
  static final instance = SearchHistory._();

  /// Before accessing this variable, you mast call [load].
  List<String>? history;

  /// Loads the history.
  Future<void> load() async {
    history ??= await Prefs.searchHistoryStringList.get();
  }

  /// Clears the history.
  Future<void> clear() async {
    if (history != null) {
      history!.clear();
    } else {
      history = [];
    }
    await Prefs.searchHistoryStringList.set(const []);
  }

  /// Removes an entry from history at [index].
  Future<void> removeAt(int index) async {
    await load();
    history!.removeAt(index);
    await Prefs.searchHistoryStringList.set(history!);
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
      if (history!.length > Constants.Config.SEARCH_HISTORY_LENGTH) {
        history!.removeLast();
      }
      await Prefs.searchHistoryStringList.set(history!);
    }
  }
}

/// Prefs specially for settings route.
abstract class Settings {
  /// Stores theme brightness.
  ///
  /// * `true` means light
  /// * `false` means dark
  static final Pref<bool> lightThemeBool =
      Pref<bool>(key: 'setting_light_theme', defaultValue: false);

  /// Stores primary color int value.
  static final Pref<int> primaryColorInt = Pref<int>(
    key: 'setting_primary_color',
    defaultValue: Constants.Theme.defaultPrimaryColor.value,
  );
}
