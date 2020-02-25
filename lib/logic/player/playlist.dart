/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'package:sweyer/sweyer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweyer/api.dart' as API;

/// Features to sort by
enum SortFeature { date, title }

/// Features to filter playlist by
enum FilterFeature { duration, fileSize }

/// What playlist is now playing? type
enum PlaylistType {
  /// Playlist for songs
  global,

  /// Playlist used to save searched tracks
  searched,

  /// Shuffled version of any other playlist
  shuffled
}

/// Class, representing a single playlist in application
///
/// It is more array-like, as it has shuffle methods and explicit indexing
/// Though it doesn't allow to have two songs with a unique id (it is possible only via constructor, but e.g. [add] method will do a check)
///
class Playlist {
  List<Song> _songs;

  // Constructors

  Playlist(List<Song> songs) : this._songs = songs;

  /// Creates playlist and shuffles specified songs array
  Playlist.shuffled(List<Song> songs)
      : this._songs = Playlist.shuffleSongs(songs);

  // Statics

  /// Returns a shuffled copy of songs
  /// It is static because we don't want accidentally shuffle the original playlist
  /// Rather we want to make a copy and save it somewhere
  static List<Song> shuffleSongs(List<Song> songsToShuffle) {
    List<Song> shuffledSongs = List.from(songsToShuffle);
    shuffledSongs.shuffle();
    return shuffledSongs;
  }

  // Getters
  List<Song> get songs => _songs;

  /// Get playlist length
  int get length => _songs.length;
  bool get isEmpty => _songs.isEmpty;
  bool get isNotEmpty => _songs.isNotEmpty;

  // Methods

  /// Checks if playlist contains song
  bool contains(Song song) {
    for (var _song in _songs) {
      if (_song.id == song.id) return true;
    }
    return false;
  }

  /// Adds song to a playlist
  /// Returns a boolean result of the operation
  bool add(Song song) {
    var success = !contains(song);
    if (success) _songs.add(song);
    return success;
  }

  void removeSongById(int id) {
    _songs.removeWhere((el) => el.id == id);
  }

  /// Returns the removed object
  Song removeSongAt(int index) {
    return _songs.removeAt(index);
  }

  /// Returns song object by song id
  Song getSongById(int id) {
    return _songs.firstWhere((el) => el.id == id, orElse: () => null);
  }

  /// Returns song index in array by its id
  int getSongIndexById(int id) {
    return _songs.indexWhere((el) => el.id == id);
  }

  /// Returns next song id
  int getNextSongId(int id) {
    final int nextSongIndex = getSongIndexById(id) + 1;
    if (nextSongIndex >= length) {
      return _songs[0].id;
    }
    return _songs[nextSongIndex].id;
  }

  /// Returns prev song id
  int getPrevSongId(int id) {
    final int prevSongIndex = getSongIndexById(id) - 1;
    if (prevSongIndex < 0) {
      return _songs[length - 1].id;
    }
    return _songs[prevSongIndex].id;
  }

  // TODO: implement file size filter
  void filter(FilterFeature feature, {Duration duration}) {
    if (feature == FilterFeature.duration) {
      assert(duration != null);
      _songs = _songs
          .where((el) => Duration(milliseconds: el.duration) > duration)
          .toList();
    }
  }
}

/// A class to
/// 1. Fetch songs
/// 2. Control playlist json
/// 3. Manage playlists
/// 4. Search in playlists
///
/// etc.
abstract class PlaylistControl {
  static Map<PlaylistType, Playlist> playlists = {};

  /// What playlist is now playing?
  static PlaylistType playlistType = PlaylistType.global;

  /// What playlist was before shuffling
  static PlaylistType playlistTypeBeforeShuffle = PlaylistType.global;

  /// Sort feature
  static SortFeature sortFeature = SortFeature.date;

  /// Minimum duration when files is considered to be a song
  static Duration settingMinDuration = Duration(seconds: 30);

  /// An object to serialize songs
  static SongsSerialization songsSerializer = SongsSerialization();

  /// An object to serialize playlist
  static PlaylistSerialization playlistSerializer = PlaylistSerialization();

  /// Songs fetcher class instance
  static final SongsFetcher songsFetcher =
      SongsFetcher(songsSerializer.saveJson);

  /// Current id of playing song
  static int _playingSongIdState;

  /// Controller for stream of playlist changes
  static StreamController<void> _songsListChangeStreamController =
      StreamController<void>.broadcast();

  /// Represents songs fetch on app start
  static bool initFetching = true;

  /// Get current playing song (always being searched in globalPlaylist)
  static Song get currentSong {
    return playlists[PlaylistType.global].getSongById(_playingSongIdState) ??
        playlists[PlaylistType.global].songs[0];
  }

  /// Get current playing id
  static int get currentSongId {
    return _playingSongIdState;
  }

  /// Changes current songs id and emits song change event
  static void changeSong(int songId) {
    _playingSongIdState = songId;
  }

  /// Util function to select playlist by [argPlaylistType]
  ///
  /// Returns current playlist if [argPlaylistType] is [null]
  static Playlist getPlaylist([PlaylistType argPlaylistType]) {
    if (argPlaylistType == null) argPlaylistType = playlistType;
    switch (argPlaylistType) {
      case PlaylistType.global:
        return playlists[PlaylistType.global];
      case PlaylistType.searched:
        return playlists[PlaylistType.searched];
      case PlaylistType.shuffled:
        return playlists[PlaylistType.shuffled];
      default:
        throw Exception('Invalid playlist type');
    }
  }

  /// Returns a [currentSong] index in current playlist (by default)
  ///
  /// If optional [playlistType] is specified, then returns index in selected playlist type
  static int currentSongIndex([PlaylistType argPlaylistType]) {
    return getPlaylist(argPlaylistType).getSongIndexById(_playingSongIdState);
  }

  /// Whether playlist control is ready to provide player instance sources to play tracks
  static bool get playReady => playlists[PlaylistType.global] != null;

  /// A stream of changes on playlist
  static Stream<void> get onPlaylistListChange =>
      _songsListChangeStreamController.stream;

  /// Emit event to [onPlaylistListChange]
  ///
  /// Should be only called when user can see playlist change, i.e. songs sort.
  /// Shouldn't be called, e.g. on tile click, when playlist changes, but user can't actually see it
  static void emitPlaylistChange() {
    _songsListChangeStreamController.add(null);
  }

  /// The main data app initialization function
  /// Inits all playlists
  /// Also handles no-permissions situations
  static Future<void> init() async {
    if (Permissions.granted) {
      // await Future.delayed(Duration(seconds: 2));

      playlists[PlaylistType.global] = null; // Reset [playReady]
     // emitPlaylistChange();

      initFetching = true;
      await Future.wait([
        songsSerializer.initJson(), // Init songs json
        playlistSerializer.initJson() // Init playlist json
      ]);
      // Get songs from json and create global playlist
      playlists[PlaylistType.global] =
          Playlist(await songsSerializer.readJson());
      await _restoreSortFeature();
      await filterSongs();
      sortSongs(silent: true);

      await _restoreLastSong();
      await _restorePlaylist();

      _initialSongsFetch();
    } else {
      // Init empty playlist if no permission granted
      if (!playReady) playlists[PlaylistType.global] = Playlist([]);
    }

    // Emit event to track change stream
    emitPlaylistChange();
  }

  /// TODO: add usage for this method
  static void dispose() {
    _songsListChangeStreamController.close();
  }

  /// Refetch songs and update playlist
  static Future<void> refetchSongs() async {
    playlists[PlaylistType.global] = Playlist(await songsFetcher.fetchSongs());
    await filterSongs(silent: true);
    sortSongs(silent: true);
    emitPlaylistChange();
  }

  /// Sets searched playlist
  ///
  /// This functions doesn't call [emitPlaylistChange()]
  ///
  /// @param [songs] — can be omitted and if so, then playlist is not changed, only switched to it
  static Future<void> setSearchedPlaylist([List<Song> songs]) async {
    if (songs != null) {
      playlists[PlaylistType.searched] = Playlist(songs);
      playlistSerializer.saveJson(songs);
    }
    playlistType = PlaylistType.searched;
    Prefs.byKey.playlistTypeInt.setPref(1);
  }

  /// Shuffles from current playlist (by default)
  ///
  /// @param [argPlaylistType] if specified - shuffles from it
  /// @param [songs] if specified - sets them
  static void setShuffledPlaylist(
      [PlaylistType argPlaylistType, List<Song> songs]) {
    argPlaylistType ??= playlistType;

    playlistTypeBeforeShuffle = argPlaylistType;
    playlistType = PlaylistType.shuffled;
    Prefs.byKey.playlistTypeInt.setPref(2);

    if (songs == null)
      playlists[PlaylistType.shuffled] =
          Playlist.shuffled(getPlaylist(argPlaylistType).songs);
    else
      playlists[PlaylistType.shuffled] = Playlist(songs);
    playlistSerializer.saveJson(playlists[PlaylistType.shuffled].songs);
    emitPlaylistChange();
  }

  /// Returns playlist that was before shuffle and clears [shuffledPlaylist]
  ///
  /// @param [argPlaylistType] if specified - returns to it
  static void returnFromShuffledPlaylist([PlaylistType argPlaylistType]) {
    argPlaylistType ??= playlistTypeBeforeShuffle;
    if (argPlaylistType == PlaylistType.global)
      resetPlaylists();
    else if (argPlaylistType == PlaylistType.searched) setSearchedPlaylist();
    playlists[PlaylistType.shuffled] = Playlist([]);
  }

  /// Switches tp global Resets all playlists except it
  ///
  /// This functions doesn't call [emitPlaylistChange()]
  static void resetPlaylists() {
    if (playlistType != PlaylistType.global) {
      Prefs.byKey.playlistTypeInt.setPref(0); // Save to prefs
      playlistSerializer.saveJson([]);
      playlistType = PlaylistType.global;
      playlists[PlaylistType.searched] = Playlist([]);
      playlists[PlaylistType.shuffled] = Playlist([]);
    }
  }

  /// Search in playlist song array by query
  static Iterable<Song> searchSongs(String query) {
    if (query != '') {
      // Lowercase to bring strings to one format
      query = query.toLowerCase();
      return playlists[PlaylistType.global].songs.where((el) {
        return el.title.toLowerCase().contains(query) ||
            el.artist.toLowerCase().contains(query) ||
            el.album.toLowerCase().contains(query) ||
            RegExp('\\b\\w')
                // Find abbreviations (big baby tape - bbt)
                //TODO: this is not working as expected for cyrillic
                .allMatches(el.title.toLowerCase())
                .fold("", (a, b) => a += b.group(0))
                .contains(query);
      });
    }
    return null;
  }

  /// Sort songs list by feature
  ///
  /// If no [feature] has passed then will sort by current sort feature
  ///
  /// If [silent] is true, [emitPlaylistChange] won't be called
  static void sortSongs({SortFeature feature, bool silent = false}) {
    feature ??= sortFeature;
    switch (feature) {
      case SortFeature.date:
        playlists[PlaylistType.global]
            .songs
            .sort((b, a) => a.dateModified.compareTo(b.dateModified));
        sortFeature = feature;
        Prefs.byKey.sortFeatureInt.setPref(0);
        break;
      case SortFeature.title:
        playlists[PlaylistType.global]
            .songs
            .sort((a, b) => a.title.compareTo(b.title));
        sortFeature = feature;
        Prefs.byKey.sortFeatureInt.setPref(1);
        break;
      default:
        throw Exception('In sortSongs - invalid sort feature: $feature');
        break;
    }

    // Emit event to track change stream
    if (!silent) emitPlaylistChange();
  }

  /// Filter songs by min duration (for now, in future by size will be implemented)
  ///
  /// If [silent] is true, [emitPlaylistChange] won't be called
  static Future<void> filterSongs({bool silent = false}) async {
    playlists[PlaylistType.global].filter(FilterFeature.duration,
        duration: Duration(
            seconds:
                await Prefs.byKey.settingMinFileDurationInt.getPref() ?? 30));
    // Emit event to track change stream
    if (!silent) emitPlaylistChange();
  }

  /// Deletes song from device by id
  static Future<void> deleteSongFromDevice(int id) async {
    // final File file = File(getSongById(id).trackUri);
    // await file.delete();
  }

  /// Deletes songs by specified id set
  static Future<void> deleteSongs(Set<int> idSet) async {
    // List<Future<void>> futures = [];
    // for (var id in idSet) {
    // Switch playing track in silent mode if it is playing now
    // if (_playingSongIdState == id) MusicPlayer.playNext(silent: true);
    // print(getSongById(id).title);
    // futures.add(deleteSongFromDevice(id));
    // globalPlaylist.removeSongById(id);
    // }
    // emitPlaylistChange();
    // try {
    //   await Future.wait(futures);
    // } catch (e) {
    //   ShowFunctions.showToast(msg: "Ошибка при удалении");
    //   debugPrint("Deleting error: $e");
    // }
  }

  /// Gets saved sort feature from [SharedPreferences]
  ///
  /// Default value is `SortFeature.date`
  static Future<void> _restoreSortFeature() async {
    int savedSortFeature = await Prefs.byKey.sortFeatureInt.getPref() ?? 0;
    if (savedSortFeature == 0) {
      sortSongs(feature: SortFeature.date, silent: true);
    } else if (savedSortFeature == 1) {
      sortSongs(feature: SortFeature.title, silent: true);
    } else
      throw Exception(
          "_restoreSortFeature: wrong saved sortFeatureInt: $savedSortFeature");
  }

  /// Restores saved playlist from json if [playlistTypeInt] (saved [playlistType]) is not global
  static Future<void> _restorePlaylist() async {
    int savedPlaylistType = await Prefs.byKey.playlistTypeInt.getPref() ?? 0;

    if (savedPlaylistType == 0) {
      playlistType = PlaylistType.global;
    } else if (savedPlaylistType == 1) {
      playlistType = PlaylistType.searched;
    } else if (savedPlaylistType == 2) {
      playlistType = PlaylistType.shuffled;
    } else
      throw Exception(
          "_restorePlaylist: wrong saved playlistTypeInt: $savedPlaylistType");

    if (playlistType != PlaylistType.global) {
      /// Get songs ids from json
      List<int> songIds = await playlistSerializer.readJson();
      List<Song> restoredSongs = [];
      songIds.forEach((id) {
        final Song songEl = playlists[PlaylistType.global].getSongById(id);
        if (songEl != null) restoredSongs.add(songEl);
      });
      if (playlistType == PlaylistType.searched)
        setSearchedPlaylist(restoredSongs);
      else if (playlistType == PlaylistType.shuffled)
        setShuffledPlaylist(PlaylistType.global, restoredSongs);
    }
  }

  /// Function that fires right after json has fetched and when initial songs fetch has done
  ///
  /// Its main purpose to setup player to work with playlists
  static Future<void> _restoreLastSong() async {
    // songsEmpty condition is here to avoid errors when trying to get first song index
    if (getPlaylist().isNotEmpty) {
      // Get saved data
      SharedPreferences prefs = await Prefs.getSharedInstance();

      int savedSongId = await Prefs.byKey.songIdInt.getPref(prefs) ??
          getPlaylist().songs[0].id;

      // Setup initial playing state index from prefs
      _playingSongIdState = savedSongId;
      await API.ServiceHandler.sendSong(PlaylistControl.currentSong);
      // Set url of first track in player instance
      await MusicPlayer.setUri(currentSongId);
    }
  }

  /// Function to fetch all songs from user devices
  static Future<void> _initialSongsFetch() async {
    await refetchSongs();

    // Retry do all the same as before fetching songs (set duration, set track url) if it hadn't been performed before (_playingSongIdState == null)
    if (_playingSongIdState == null) {
      await _restoreLastSong();
    }
    initFetching = false;
  }
}
