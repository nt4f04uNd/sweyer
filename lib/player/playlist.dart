import 'dart:async';
import 'dart:io';
import 'package:app/components/show_functions.dart';
import 'package:app/player/fetcher.dart';
import 'package:app/player/permissions.dart';
import 'package:app/player/player.dart';
import 'package:app/player/prefs.dart';
import 'package:app/player/serialization.dart';
import 'package:app/player/song.dart';
import 'package:app/utils/async.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Features to sort by
enum SortFeature { date, title }

/// Features to filter playlist by
enum FilterFeature { duration, fileSize }

/// What playlist is now playing? type
enum PlaylistType { global, searched, shuffled }

class Playlist {
  List<Song> _songs;
  Playlist(List<Song> songs) : this._songs = songs;

  /// Creates playlist and shuffles specified songs array
  Playlist.shuffled(List<Song> songs)
      : this._songs = Playlist.shuffleSongs(songs);

  List<Song> get songs => _songs;

  /// Returns a shuffled copy of songs
  static List<Song> shuffleSongs(List<Song> songs) {
    List<Song> shuffledSongs = List.from(songs);
    shuffledSongs.shuffle();
    return shuffledSongs;
  }

  /// Getters
  ///
  /// Get playlist length
  int get length => songs.length;

  bool get isEmpty => songs.isEmpty;

  void removeSongById(int id) {
    _songs.removeWhere((el) => el.id == id);
  }

  void removeSongByIndex(int index) {
    _songs.removeAt(index);
  }

  /// Returns song object by index in songs array
  Song getSongByIndex(int index) {
    return length > 0 ? songs[index] : null;
  }

  /// Returns song object by song id
  Song getSongById(int id) {
    return songs.firstWhere((el) => el.id == id, orElse: () => null);
  }

  /// Returns song id in by its index in songs array
  int getSongIdByIndex(int index) {
    return songs[index].id;
  }

  /// Returns song index in array by its id
  int getSongIndexById(int id) {
    return songs.indexWhere((el) => el.id == id);
  }

  /// Returns next song id
  int getNextSongId(int id) {
    final int nextSongIndex = getSongIndexById(id) + 1;
    if (nextSongIndex >= length) {
      return getSongIdByIndex(0);
    }
    return getSongIdByIndex(nextSongIndex);
  }

  /// Returns prev song id
  int getPrevSongId(int id) {
    final int prevSongIndex = getSongIndexById(id) - 1;
    if (prevSongIndex < 0) {
      return getSongIdByIndex(length - 1);
    }
    return getSongIdByIndex(prevSongIndex);
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
  static ManualStreamController _songsListChangeStreamController =
      ManualStreamController();

  /// Controller for stream of current song changes
  static ManualStreamController _songChangeStreamController =
      ManualStreamController();

  /// Represents songs fetch on app start
  static bool initFetching = true;

  /// Returns current playlist (by default)
  ///
  /// If optional `argPlaylistType` is specified, then returns playlist respectively to it
  static Playlist currentPlaylist([PlaylistType argPlaylistType]) {
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

  /// Get current playing song (always being searched in _globalPlaylist)
  static Song get currentSong {
    return _globalPlaylist.getSongById(_playingSongIdState) ??
        _globalPlaylist.getSongByIndex(0);
  }

  /// Get current playing id
  static int get currentSongId {
    return _playingSongIdState;
  }

  /// Changes current songs id and emits song change event
  static void changeSong(int songId) {
    _playingSongIdState = songId;
    emitSongChange();
  }

  /// Util function to select playlist by `argPlaylistType`
  ///
  /// Returns current playlist if `argPlaylistType` is `null`
  static Playlist _selectPlaylist([PlaylistType argPlaylistType]) {
    if (argPlaylistType == null) return currentPlaylist();
    return currentPlaylist(argPlaylistType);
  }

  /// Returns a `currentSong` index in current playlist (by default)
  ///
  /// If optional `playlistType` is specified, then returns index in selected playlist type
  static int currentSongIndex([PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType)
        .getSongIndexById(_playingSongIdState);
  }

  /// Returns `songs` of current playlist (by default)
  ///
  /// If optional `playlistType` is specified, then returns `songs` of selected playlist type
  static List<Song> songs([PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).songs;
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

  /// A stream of changes on playlist
  static Stream<void> get onSongChange => _songChangeStreamController.stream;

  /// Emit event to `onPlaylistListChange`
  static void emitPlaylistChange() {
    _songsListChangeStreamController.emitEvent();
  }

  /// Emit event to `onSongChange`
  static void emitSongChange() {
    _songChangeStreamController.emitEvent();
  }

  // Methods from playlist class
  /// Searches always on `_globalPlaylist`
  static Song getSongById(int id) {
    return _globalPlaylist.getSongById(id);
  }

  static Song getSongByIndex(int index, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).getSongByIndex(index);
  }

  static int getSongIdByIndex(int index, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).getSongIdByIndex(index);
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

  static Future<void> init() async {
    // Init permission
    await Permissions.requestPermission(PermissionGroup.storage);

    if (Permissions.permissionStorageStatus == MyPermissionStatus.granted) {
      _globalPlaylist = null; // Reset `playReady`
      emitPlaylistChange();

      initFetching = true;
      await songsSerializer.initJson(); // Init songs json
      await playlistSerializer.initJson(); // Init playlist json
      // Get songs from json and create global playlist
      _globalPlaylist = Playlist(await songsSerializer.readJson());
      await _getSavedSortFeature();
      await filterSongs();
      sortSongs();

      await _restorePlayer();
      await _restorePlaylist();

      // Init player state
      await MusicPlayer.nativePlayerInstance.pause();

      // Emit event to track change stream
      emitPlaylistChange();

      _globalPlaylist =
          Playlist(await songsFetcher.fetchSongs()); // Fetch songs
      await filterSongs();
      sortSongs();

      // Retry do all the same as before fetching songs (set duration, set track url) if it hadn't been performed before (_playingSongIdState == null)
      if (_playingSongIdState == null) {
        await _restorePlayer();
      }
    } else {
      // Init empty playlist if no permission granted
      if (!playReady) _globalPlaylist = Playlist([]);
    }

    initFetching = false;
    // Emit event to track change stream
    emitPlaylistChange();
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
          Playlist.shuffled(PlaylistControl.songs(argPlaylistType));
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
    Prefs.byKey.playlistTypeInt.setPref(0); // Save to prefs
    playlistSerializer.saveJson([]);
    playlistType = PlaylistType.global;
    _searchedPlaylist = Playlist([]);
    _shuffledPlaylist = Playlist([]);
    emitPlaylistChange();
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
    final File file = File(getSongById(id).trackUri);
    await file.delete();
    print('fqwf');
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
  static Future<void> _getSavedSortFeature() async {
    int savedSortFeature = await Prefs.byKey.sortFeatureInt.getPref() ?? 0;
    if (savedSortFeature == 0) {
      sortSongs(SortFeature.date);
    } else if (savedSortFeature == 1) {
      sortSongs(SortFeature.title);
    } else
      throw Exception(
          "_getSavedSortFeature: wrong saved sortFeatureInt: $savedSortFeature");
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
  static Future<void> _restorePlayer() async {
    // songsEmpty condition is here to avoid errors when trying to get first song index
    if (!songsEmpty()) {
      // Get saved data
      SharedPreferences prefs = await Prefs.sharedInstance;
      int savedSongId = await Prefs.byKey.songIdInt.getPref(prefs) ??
          currentPlaylist().getSongIdByIndex(0);
      int savedSongPos = await Prefs.byKey.songPositionInt.getPref(prefs);

      // Setup initial playing state index from prefs
      _playingSongIdState = savedSongId;

      try {
        // Set url of first track in player instance
        await MusicPlayer.nativePlayerInstance.setUrl(currentSong.trackUri);
      } catch (e) {
        debugPrint('Wasn\'t able to set url of saved song id');
      }

      try {
        // Seek to saved position
        if (savedSongPos != null)
          await MusicPlayer.seek(Duration(seconds: savedSongPos));
      } catch (e) {
        debugPrint('Wasn\'t able to seek to saved position');
      }

      emitSongChange();
    }
  }
}
