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
enum PlaylistType { global, searched, shuffled }

/// Class, representing a single playlist in application
///
/// It is more array-like, as it has shuffle methods and explicit indexing
/// Though it doesn't allow to have two songs with a unique id (it is possible only via constructor, but e.g. `add` method will do a check)
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

  /// Returns song object by index in songs array
  Song getSongAt(int index) {
    return length > 0 ? _songs[index] : null;
  }

  /// Returns song object by song id
  Song getSongById(int id) {
    return _songs.firstWhere((el) => el.id == id, orElse: () => null);
  }

  /// Returns song id in by its index in songs array
  int getSongIdAt(int index) {
    return _songs[index].id;
  }

  /// Returns song index in array by its id
  int getSongIndexById(int id) {
    return _songs.indexWhere((el) => el.id == id);
  }

  /// Returns next song id
  int getNextSongId(int id) {
    final int nextSongIndex = getSongIndexById(id) + 1;
    if (nextSongIndex >= length) {
      return getSongIdAt(0);
    }
    return getSongIdAt(nextSongIndex);
  }

  /// Returns prev song id
  int getPrevSongId(int id) {
    final int prevSongIndex = getSongIndexById(id) - 1;
    if (prevSongIndex < 0) {
      return getSongIdAt(length - 1);
    }
    return getSongIdAt(prevSongIndex);
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
///
/// This class consciously doesn't expose playlists and songs themselves.
/// This is done for sake of optimization and avoiding mistakes, e.g. `getSongById` should always be searched in `_globalPlaylist`
abstract class PlaylistControl {
  /// Playlist for songs
  static Playlist _globalPlaylist;

  /// Playlist used to save searched tracks
  static Playlist _searchedPlaylist;

  /// Shuffled version of global playlist
  static Playlist _shuffledPlaylist;

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

  /// Get current playing song (always being searched in _globalPlaylist)
  static Song get currentSong {
    return _globalPlaylist.getSongById(_playingSongIdState) ??
        _globalPlaylist.getSongAt(0);
  }

  /// Get current playing id
  static int get currentSongId {
    return _playingSongIdState;
  }

  /// Changes current songs id and emits song change event
  static void changeSong(int songId) {
    _playingSongIdState = songId;
  }

  /// Util function to select playlist by `argPlaylistType`
  ///
  /// Returns current playlist if `argPlaylistType` is `null`
  static Playlist _selectPlaylist([PlaylistType argPlaylistType]) {
    if (argPlaylistType == null) argPlaylistType = playlistType;
    switch (argPlaylistType) {
      case PlaylistType.global:
        return _globalPlaylist;
      case PlaylistType.searched:
        return _searchedPlaylist;
      case PlaylistType.shuffled:
        return _shuffledPlaylist;
      default:
        throw Exception('Invalid playlist type');
    }
  }

  /// Returns a `currentSong` index in current playlist (by default)
  ///
  /// If optional `playlistType` is specified, then returns index in selected playlist type
  static int currentSongIndex([PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType)
        .getSongIndexById(_playingSongIdState);
  }

  /// Returns `length` of current playlist (by default)
  ///
  /// If optional `playlistType` is specified, then returns `length` of selected playlist type
  static int length([PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).length;
  }

  /// Returns `isEmpty` of current playlist (by default)
  ///
  /// If optional `playlistType` is specified, then returns `isEmpty` of selected playlist type
  static bool songsEmpty([PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).isEmpty;
  }

  /// Whether playlist control is ready to provide player instance sources to play tracks
  static bool get playReady => _globalPlaylist != null;

  /// A stream of changes on playlist
  static Stream<void> get onPlaylistListChange =>
      _songsListChangeStreamController.stream;

  /// Emit event to `onPlaylistListChange`
  static void emitPlaylistChange() {
    _songsListChangeStreamController.add(null);
  }

  // Methods from playlist class

  /// Searches always on `_globalPlaylist`
  static Song getSongById(int id) {
    return _globalPlaylist.getSongById(id);
  }

  static Song getSongAt(int index, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).getSongAt(index);
  }

  static int getSongIdAt(int index, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).getSongIdAt(index);
  }

  static int getSongIndexById(int id, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).getSongIndexById(id);
  }

  static int getNextSongId(int id, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).getNextSongId(id);
  }

  static int getPrevSongId(int id, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).getPrevSongId(id);
  }

  static Song removeSongAt(int index, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).removeSongAt(index);
  }

  /// The main data app initialization function
  /// Inits all playlists
  /// Also handles no-permissions situations
  static Future<void> init() async {
    if (Permissions.granted) {
      _globalPlaylist = null; // Reset `playReady`
      emitPlaylistChange();

      initFetching = true;
      await Future.wait([
        songsSerializer.initJson(), // Init songs json
        playlistSerializer.initJson() // Init playlist json
      ]);
      // Get songs from json and create global playlist
      _globalPlaylist = Playlist(await songsSerializer.readJson());
      await _restoreSortFeature();
      await filterSongs();

      // print(Song.test().toJson());
      // print(
      //     "1111111111111111111111111111111111111111111111111111111111 ${_globalPlaylist.add(Song.test())}");

      sortSongs();

      await _restoreLastSong();
      await _restorePlaylist();

      // Emit event to track change stream
      emitPlaylistChange();

      _globalPlaylist =
          Playlist(await songsFetcher.fetchSongs()); // Fetch songs
      await filterSongs();
      sortSongs();

      // Retry do all the same as before fetching songs (set duration, set track url) if it hadn't been performed before (_playingSongIdState == null)
      if (_playingSongIdState == null) {
        await _restoreLastSong();
      }
    } else {
      // Init empty playlist if no permission granted
      if (!playReady) _globalPlaylist = Playlist([]);
    }

    initFetching = false;
    // Emit event to track change stream
    emitPlaylistChange();
  }

  /// TODO: add usage for this method
  static void dispose() {
    _songsListChangeStreamController.close();
  }

  /// Refetch songs and update playlist
  static Future<void> refetchSongs() async {
    _globalPlaylist = Playlist(await songsFetcher.fetchSongs());
    await filterSongs();
    sortSongs();
    emitPlaylistChange();
  }

  /// Sets searched playlist
  ///
  /// @param `songs` — can be omitted and if so, then playlist is not changed, only switched to it
  static void setSearchedPlaylist([List<Song> songs]) {
    if (songs != null) {
      _searchedPlaylist = Playlist(songs);
      playlistSerializer.saveJson(songs);
    }
    playlistType = PlaylistType.searched;
    Prefs.byKey.playlistTypeInt.setPref(1);
    emitPlaylistChange();
  }

  /// Shuffles from current playlist (by default)
  ///
  /// @param `argPlaylistType` if specified - shuffles from it
  /// @param `songs` if specified - sets them
  static void setShuffledPlaylist(
      [PlaylistType argPlaylistType, List<Song> songs]) {
    argPlaylistType ??= playlistType;

    playlistTypeBeforeShuffle = argPlaylistType;
    playlistType = PlaylistType.shuffled;

    Prefs.byKey.playlistTypeInt.setPref(2);

    if (songs == null)
      _shuffledPlaylist =
          Playlist.shuffled(_selectPlaylist(argPlaylistType).songs);
    else
      _shuffledPlaylist = Playlist(songs);
    playlistSerializer.saveJson(_shuffledPlaylist.songs);
    emitPlaylistChange();
  }

  /// Returns playlist that was before shuffle and clears `shuffledPlaylist`
  ///
  /// @param `argPlaylistType` if specified - returns to it
  static void returnFromShuffledPlaylist([PlaylistType argPlaylistType]) {
    argPlaylistType ??= playlistTypeBeforeShuffle;
    if (argPlaylistType == PlaylistType.global)
      resetPlaylists();
    else if (argPlaylistType == PlaylistType.searched) setSearchedPlaylist();
    _shuffledPlaylist = Playlist([]);
  }

  /// Switches tp global Resets all playlists except it
  static void resetPlaylists() {
    if (playlistType != PlaylistType.global) {
      Prefs.byKey.playlistTypeInt.setPref(0); // Save to prefs
      playlistSerializer.saveJson([]);
      playlistType = PlaylistType.global;
      _searchedPlaylist = Playlist([]);
      _shuffledPlaylist = Playlist([]);
      emitPlaylistChange();
    }
  }

  /// Search in playlist song array by query
  static Iterable<Song> searchSongs(String query) {
    if (query != '') {
      // Lowercase to bring strings to one format
      query = query.toLowerCase();
      return _globalPlaylist.songs.where((el) {
        return el.title.toLowerCase().contains(query) ||
            el.artist.toLowerCase().contains(query) ||
            el.album.toLowerCase().contains(query) ||
            RegExp('\\b\\w')
                .allMatches(el.title.toLowerCase())
                .fold("", (a, b) => a += b.group(0))
                .contains(
                    query); // Find abbreviations (big baby tape - bbt) //TODO: this is not working as expected, probably delete
      });
    }
    return null;
  }

  /// Sort songs list by feature
  ///
  /// If no argument has passed then will sort by current sort feature
  static void sortSongs([SortFeature feature]) {
    feature ??= sortFeature;
    switch (feature) {
      case SortFeature.date:
        _globalPlaylist.songs
            .sort((b, a) => a.dateModified.compareTo(b.dateModified));
        sortFeature = feature;
        Prefs.byKey.sortFeatureInt.setPref(0);
        break;
      case SortFeature.title:
        _globalPlaylist.songs.sort((a, b) => a.title.compareTo(b.title));
        sortFeature = feature;
        Prefs.byKey.sortFeatureInt.setPref(1);
        break;
      default:
        throw Exception('In sortSongs - invalid sort feature: $feature');
        break;
    }

    // Emit event to track change stream
    emitPlaylistChange();
  }

  /// Filter songs by min duration (for now, in future by size will be implemented)
  static Future<void> filterSongs() async {
    _globalPlaylist.filter(FilterFeature.duration,
        duration: Duration(
            seconds:
                await Prefs.byKey.settingMinFileDurationInt.getPref() ?? 30));
    // Emit event to track change stream
    emitPlaylistChange();
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
    // _globalPlaylist.removeSongById(id);
    // }
    // emitPlaylistChange();
    // try {
    //   await Future.wait(futures);
    // } catch (e) {
    //   ShowFunctions.showToast(msg: "Ошибка при удалении");
    //   debugPrint("Deleting error: $e");
    // }
  }

  /// Gets saved sort feature from `SharedPreferences`
  ///
  /// Default value is `SortFeature.date`
  static Future<void> _restoreSortFeature() async {
    int savedSortFeature = await Prefs.byKey.sortFeatureInt.getPref() ?? 0;
    if (savedSortFeature == 0) {
      sortSongs(SortFeature.date);
    } else if (savedSortFeature == 1) {
      sortSongs(SortFeature.title);
    } else
      throw Exception(
          "_restoreSortFeature: wrong saved sortFeatureInt: $savedSortFeature");
  }

  /// Restores saved playlist from json if `playlistTypeInt` (saved `playlistType`) is not global
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
        final Song songEl = _globalPlaylist.getSongById(id);
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
    if (!songsEmpty()) {
      // Get saved data
      SharedPreferences prefs = await Prefs.getSharedInstance();

      int savedSongId = await Prefs.byKey.songIdInt.getPref(prefs) ??
          _selectPlaylist().getSongIdAt(0);

      // Setup initial playing state index from prefs
      _playingSongIdState = savedSongId;
      await API.ServiceHandler.sendSong(PlaylistControl.currentSong);
      // Set url of first track in player instance
      await MusicPlayer.setUrl(currentSong.trackUri);
    }
  }
}
