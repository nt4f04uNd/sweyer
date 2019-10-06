import 'dart:async';
import 'package:app/player/fetcher.dart';
import 'package:app/player/player.dart';
import 'package:app/player/song.dart';
import 'package:flutter/material.dart';
import 'package:app/constants/constants.dart' as Constants;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Features to sort by
enum SortFeature { date, title }

/// Class to create change and control stream
///
class SongsListChangeStreamController {
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
  final List<Song> songs;
  Playlist(this.songs);

  /// Creates playlist and shuffles specified songs array
  Playlist.shuffled(List<Song> songs)
      : this.songs = Playlist.shuffleSongs(songs);

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
    return songs[index];
  }

  /// Returns song object by song id
  Song getSongById(int id) {
    return songs.firstWhere((el) => el.id == id, orElse: () => songs[0]);
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
}

/// What playlist is now playing? type
enum PlaylistType { global, searched, shuffled }

/// A class to fetch songs/control json/control playlists/search in playlists
class PlaylistControl {
  /// Playlist for songs
  Playlist globalPlaylist;

  /// Playlist used to save searched tracks
  Playlist searchedPlaylist;

  /// Shuffled version of global playlist
  Playlist shuffledPlaylist;

  /// What playlist is now playing?
  PlaylistType playlistType = PlaylistType.global;

  /// Songs fetcher class instance
  final SongsFetcher fetcher = SongsFetcher();

  /// Current id of playing track
  int playingTrackIdState;

  /// Controller for stream of playlist changes
  SongsListChangeStreamController _songsListChangeStreamController =
      SongsListChangeStreamController();

  /// Controller for stream of current song changes
  SongsListChangeStreamController _songChangeStreamController =
      SongsListChangeStreamController();

  /// Returns current playlist (by default)
  ///
  /// If optional `argPlaylistType` is specified, then returns playlist respectively to it
  Playlist currentPlaylist([PlaylistType argPlaylistType]) {
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
  Song get currentSong {
    return globalPlaylist.getSongById(playingTrackIdState);
  }

  /// Util function to select playlist by `argPlaylistType`
  ///
  /// Returns current playlist if `argPlaylistType` is `null`
  Playlist _selectPlaylist([PlaylistType argPlaylistType]) {
    if (argPlaylistType == null) return currentPlaylist();
    return currentPlaylist(argPlaylistType);
  }

  /// Returns a `currentSong` index in current playlist (by default)
  ///
  /// If optional `playlistType` is specified, then returns index in selected playlist type
  int currentSongIndex([PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType)
        .getSongIndexById(playingTrackIdState);
  }

  /// Returns `songs` of current playlist (by default)
  ///
  /// If optional `playlistType` is specified, then returns `songs` of selected playlist type
  List<Song> songs([PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).songs;
  }

  /// Returns `length` of current playlist (by default)
  ///
  /// If optional `playlistType` is specified, then returns `length` of selected playlist type
  int length([PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).length;
  }

  /// Returns `isEmpty` of current playlist (by default)
  ///
  /// If optional `playlistType` is specified, then returns `isEmpty` of selected playlist type
  bool songsEmpty([PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).isEmpty;
  }

  /// Whether playlist control is ready to provide player instance sources to play tracks
  bool get playReady => globalPlaylist != null;

  /// A stream of changes on playlist
  Stream<void> get onPlaylistListChange =>
      _songsListChangeStreamController.stream;

  /// A stream of changes on playlist
  Stream<void> get onSongChange => _songChangeStreamController.stream;

  /// Emit event to `onPlaylistListChange`
  void emitPlaylistChange() {
    _songsListChangeStreamController.emitEvent();
  }

  /// Emit event to `onSongChange`
  void emitSongChange() {
    _songChangeStreamController.emitEvent();
  }

  // Methods from playlist class
  /// Searches always on `globalPlaylist`
  Song getSongById(int id) {
    return globalPlaylist.getSongById(id);
  }

  Song getSongByIndex(int index, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).getSongByIndex(index);
  }

  int getSongIdByIndex(int index, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).getSongIdByIndex(index);
  }

  int getSongIndexById(int id, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).getSongIndexById(id);
  }

  int getNextSongId(int id, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).getNextSongId(id);
  }

  int getPrevSongId(int id, [PlaylistType argPlaylistType]) {
    return _selectPlaylist(argPlaylistType).getPrevSongId(id);
  }

  PlaylistControl() {
    _init();
  }

  Future<void> _init() async {
    // Permissions
    // TODO: add button to re-request permissions
    PermissionStatus permissionStorage = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    // PermissionStatus permissionBattery = await PermissionHandler()
    //     .checkPermissionStatus(PermissionGroup.ignoreBatteryOptimizations);

    // For return values of `requestPermissions`s
    Map<PermissionGroup, PermissionStatus> permissions;

    if (permissionStorage != PermissionStatus.granted)
      await PermissionHandler().requestPermissions([
        PermissionGroup.storage,
      ]);

    // if (permissionBattery != PermissionStatus.granted)
    //   await PermissionHandler()
    //       .requestPermissions([PermissionGroup.ignoreBatteryOptimizations]);

    await fetcher.serializer.initJson(); // Init songs json actions
    globalPlaylist = Playlist(await fetcher.serializer
        .readJson()); // Get songs from json and create global playlist

    // Get saved data
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int savedSongId = prefs.getInt(Constants.PrefKeys.songIdInt);
    int savedSongPos = prefs.getInt(Constants.PrefKeys.songPositionInt);

    // songsEmpty condition is here to avoid errors when trying to get first song index
    if (!songsEmpty()) {
      // Setup initial playing state index from prefs
      playingTrackIdState =
          savedSongId ?? currentPlaylist().getSongIdByIndex(0);

      try {
        // Set url of first track in player instance
        await MusicPlayer.instance.nativePlayerInstance
            .setUrl(currentSong.trackUri);
      } catch (e) {
        // playingTrackIdState =
        //     null; // Set to null to display that there's no currently playing track and user could not go to player route (NOTE: THIS IS VERY UNRELIABLE)
        debugPrint('Wasn\'t able to set url to _playerInstance');
      }

      // Seek to saved position
      if (savedSongPos != null)
        MusicPlayer.instance.nativePlayerInstance
            .seek(Duration(seconds: savedSongPos));
    }

    // Init player state
    await MusicPlayer.instance.nativePlayerInstance.pause();

    // Emit event to track change stream
    emitPlaylistChange();

    globalPlaylist = Playlist(await fetcher.fetchSongs()); // Fetch songs

    // Retry do all the same as before fetching songs (set duration, set track url) if it hadn't been performed before (playingTrackIdState == null)
    if (!songsEmpty() && playingTrackIdState == null) {
      // Setup initial playing state index from prefs
      playingTrackIdState =
          savedSongId ?? currentPlaylist().getSongIdByIndex(0);

      try {
        // Set url of first track in player instance
        await MusicPlayer.instance.nativePlayerInstance
            .setUrl(currentSong.trackUri);
      } catch (e) {
        // playingTrackIdState =
        //     null; // Set to null to display that there's no currently playing track and user could not go to player route (NOTE: THIS IS VERY UNRELIABLE)
        debugPrint('Wasn\'t able to set url to nativePlayerInstance');
      }

      // Seek to saved position
      if (savedSongPos != null)
        MusicPlayer.instance.nativePlayerInstance
            .seek(Duration(seconds: savedSongPos));
    }

    // Emit event to track change stream TODO: test this line
    emitPlaylistChange();
  }

  /// Fetch songs and update playlist
  Future<void> refetchSongs() async {
    globalPlaylist = Playlist(await fetcher.fetchSongs());
    emitPlaylistChange();
  }

  /// Create and sets specific playlist to play
  ///
  /// NOTE: YOU SHOULD NEVER SET GLOBAL PLAYLIST THROUGH THIS EXCEPT FOR APP INIT PROCESS
  void setPlaylist(List<Song> songs, PlaylistType argPlaylistType) {
    // FIXME: try to optimize this, add some comparison e.g ???
    switch (argPlaylistType) {
      case PlaylistType.searched:
        // NOTE The order of these two instruction matters
        searchedPlaylist = Playlist(songs);
        playlistType = argPlaylistType;
        emitPlaylistChange();
        break;
      case PlaylistType.shuffled:
        shuffledPlaylist = Playlist(songs);
        playlistType = argPlaylistType;
        emitPlaylistChange();
        break;
      case PlaylistType.global: // Do nothing
        break;
      default:
        throw 'Invalid playlistType';
    }
    emitPlaylistChange();
  }

  /// Shuffles from current playlist (by default)
  ///
  /// If `argPlaylistType` specified - shuffles from it
  void setShuffledPlaylist([PlaylistType argPlaylistType]) {
    setPlaylist(
        Playlist.shuffleSongs(songs(argPlaylistType)), PlaylistType.shuffled);
  }

  /// Switches tp global Resets all playlists except it
  void resetPlaylists() {
    playlistType = PlaylistType.global;
    searchedPlaylist = Playlist([]);
    shuffledPlaylist = Playlist([]);
    emitPlaylistChange();
  }

  /// Search in playlist song array by query
  Iterable<Song> searchSongs(String query) {
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
  void sortSongs(SortFeature feature) {
    switch (feature) {
      case SortFeature.date:
        globalPlaylist.songs.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case SortFeature.title:
        globalPlaylist.songs.sort((a, b) => a.title.compareTo(b.title));
        break;
      default:
        break;
    }

    // Emit event to track change stream
    emitPlaylistChange();
  }
}
