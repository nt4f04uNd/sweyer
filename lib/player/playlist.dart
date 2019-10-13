import 'dart:async';
import 'package:app/player/fetcher.dart';
import 'package:app/player/permissions.dart';
import 'package:app/player/player.dart';
import 'package:app/player/prefs.dart';
import 'package:app/player/serialization.dart';
import 'package:app/player/song.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Features to sort by
enum SortFeature { date, title }

/// Features to filter playlist by
enum FilterFeature { duration, fileSize }

/// Class to create change and control stream
///
class ManualStreamController {
  /// Stream controller used to create stream of changes on track list (just to notify)
  StreamController<void> _controller = StreamController<void>.broadcast();

  /// Get stream of notifier events about changes on track list
  Stream<void> get stream => _controller.stream;

  /// Emit change event
  void emitEvent() {
    _controller.add(null);
  }
}

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

/// What playlist is now playing? type
enum PlaylistType { global, searched, shuffled }

/// A class to
/// 1. Fetch songs
/// 2. Control playlist json
/// 3. Manage playlists
/// 4. Search in playlists
///
/// etc.
abstract class PlaylistControl {
  /// Playlist for songs
  static Playlist globalPlaylist;

  /// Playlist used to save searched tracks
  static Playlist searchedPlaylist;

  /// Shuffled version of global playlist
  static Playlist shuffledPlaylist;

  /// What playlist is now playing?
  static PlaylistType playlistType = PlaylistType.global;

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

  /// Current id of playing track
  static int playingTrackIdState;

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
        return globalPlaylist;
      case PlaylistType.searched:
        return searchedPlaylist;
      case PlaylistType.shuffled:
        return shuffledPlaylist;
      default:
        throw 'Invalid playlist type';
    }
  }

  /// Get current playing song (always being searched in globalPlaylist)
  static Song get currentSong {
    return globalPlaylist.getSongById(playingTrackIdState) ??
        globalPlaylist.getSongByIndex(0);
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
        .getSongIndexById(playingTrackIdState);
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
  static bool get playReady => globalPlaylist != null;

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
  /// Searches always on `globalPlaylist`
  static Song getSongById(int id) {
    return globalPlaylist.getSongById(id);
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
      globalPlaylist = null; // Reset `playReady`
      emitPlaylistChange();

      initFetching = true;
      await songsSerializer.initJson(); // Init songs json
      await playlistSerializer.initJson(); // Init playlist json
      // Get songs from json and create global playlist
      globalPlaylist = Playlist(await songsSerializer.readJson());

      await _getSavedSortFeature();

      await filterSongs();
      sortSongs();

      await _afterTrackLoaded();
      await _restorePlaylist();

      // Init player state
      await MusicPlayer.nativePlayerInstance.pause();

      // Emit event to track change stream
      emitPlaylistChange();

      globalPlaylist = Playlist(await songsFetcher.fetchSongs()); // Fetch songs
      await filterSongs();
      sortSongs();

      // Retry do all the same as before fetching songs (set duration, set track url) if it hadn't been performed before (playingTrackIdState == null)
      if (playingTrackIdState == null) {
        await _afterTrackLoaded();
      }
    } else {
      // Init empty playlist if no permission granted
      if (!playReady) globalPlaylist = Playlist([]);
    }

    initFetching = false;
    // Emit event to track change stream
    emitPlaylistChange();
  }

  /// Fetch songs and update playlist
  static Future<void> refetchSongs() async {
    globalPlaylist = Playlist(await songsFetcher.fetchSongs());
    await filterSongs();
    sortSongs();
    emitPlaylistChange();
  }

  /// Create and sets specific playlist to play
  ///
  /// NOTE: YOU SHOULD NEVER SET GLOBAL PLAYLIST THROUGH THIS EXCEPT FOR APP INIT PROCESS
  static void setPlaylist(List<Song> songs, PlaylistType argPlaylistType) {
    // TODO: try to optimize this, add some comparison e.g ???
    switch (argPlaylistType) {
      case PlaylistType.global: // Just save to prefs
        Prefs.byKey.playlistTypeInt.setPref(0);
        playlistSerializer.saveJson([]);
        break;
      case PlaylistType.searched:
        // NOTE The order of these two instruction matters
        searchedPlaylist = Playlist(songs);
        playlistType = argPlaylistType;
        Prefs.byKey.playlistTypeInt.setPref(1);
        playlistSerializer.saveJson(songs);
        emitPlaylistChange();
        break;
      case PlaylistType.shuffled:
        shuffledPlaylist = Playlist(songs);
        playlistType = argPlaylistType;
        Prefs.byKey.playlistTypeInt.setPref(2);
        playlistSerializer.saveJson(songs);
        emitPlaylistChange();
        break;
      default:
        throw 'Invalid playlistType';
    }
    emitPlaylistChange();
  }

  /// Shuffles from current playlist (by default)
  ///
  /// If `argPlaylistType` specified - shuffles from it
  static void setShuffledPlaylist([PlaylistType argPlaylistType]) {
    setPlaylist(
        Playlist.shuffleSongs(songs(argPlaylistType)), PlaylistType.shuffled);
  }

  /// Switches tp global Resets all playlists except it
  static void resetPlaylists() {
    Prefs.byKey.playlistTypeInt.setPref(0); // Save to prefs
    playlistSerializer.saveJson([]);
    playlistType = PlaylistType.global;
    searchedPlaylist = Playlist([]);
    shuffledPlaylist = Playlist([]);
    emitPlaylistChange();
  }

  /// Search in playlist song array by query
  static Iterable<Song> searchSongs(String query) {
    if (query != '') {
      // Lowercase to bring strings to one format
      query = query.toLowerCase();
      return globalPlaylist.songs.where((el) {
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
        globalPlaylist.songs
            .sort((b, a) => a.dateModified.compareTo(b.dateModified));
        sortFeature = feature;
        Prefs.byKey.sortFeatureInt.setPref(0);
        break;
      case SortFeature.title:
        globalPlaylist.songs.sort((a, b) => a.title.compareTo(b.title));
        sortFeature = feature;
        Prefs.byKey.sortFeatureInt.setPref(1);
        break;
      default:
        break;
    }

    // Emit event to track change stream
    emitPlaylistChange();
  }

  /// Filter songs by min duration (for now, in future by size will be implemened)
  /// FIXME: try to make better method logics and playlist sync, e.g. `emitPlaylistChange` is called in sort, which is not really cool and in a generally, when i fetch songs from somewhere, i make 3 actions: assign `globalPlaylist` and call `filterSongs`, `sortSongs`
  static Future<void> filterSongs() async {
    globalPlaylist.filter(FilterFeature.duration,
        duration: Duration(
            seconds:
                await Prefs.byKey.settingMinFileDurationInt.getPref() ?? 30));
    // Emit event to track change stream
    emitPlaylistChange();
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
          "_getSavedSortFeature: wrong saved playlistTypeInt: $savedPlaylistType");

    if (playlistType != PlaylistType.global) {
      /// Get songs ids from json
      List<int> songIds = await playlistSerializer.readJson();
      List<Song> restoredSongs = [];
      songIds.forEach((id) {
        final Song songEl = globalPlaylist.getSongById(id);
        if (songEl != null) restoredSongs.add(songEl);
      });
      setPlaylist(restoredSongs, playlistType);
    }
  }

  /// Function that fires right after json has fetched and when initial songs fetch has done
  ///
  /// Its main purpose to setup player to work with playlists
  static Future<void> _afterTrackLoaded() async {
    // Get saved data
    SharedPreferences prefs = await Prefs.sharedInstance;
    int savedSongId = await Prefs.byKey.songIdInt.getPref(prefs);
    int savedSongPos = await Prefs.byKey.songPositionInt.getPref(prefs);
    // songsEmpty condition is here to avoid errors when trying to get first song index
    if (!songsEmpty()) {
      // Setup initial playing state index from prefs
      playingTrackIdState =
          savedSongId ?? currentPlaylist().getSongIdByIndex(0);

      try {
        // Set url of first track in player instance
        await MusicPlayer.nativePlayerInstance.setUrl(currentSong.trackUri);
      } catch (e) {
        // playingTrackIdState =
        //     null; // Set to null to display that there's no currently playing track and user could not go to player route (NOTE: THIS IS VERY UNRELIABLE)
        debugPrint('Wasn\'t able to set url to _playerInstance');
      }

      // Seek to saved position
      if (savedSongPos != null)
        MusicPlayer.nativePlayerInstance.seek(Duration(seconds: savedSongPos));
    }
  }
}
