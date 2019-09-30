import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/player/fetcher.dart';
import 'package:app/player/player.dart';
import 'package:app/player/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/constants/constants.dart' as Constants;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Features to sort by
enum SortFeature { date, title }

/// Class to create change and control stream
///
class SongsListChangeStreamController {
  /// Stream controller used to create stream of changes on track list (just to notify)
  StreamController _controller = StreamController<void>.broadcast();

  /// Get stream of notifier events about changes on track list
  Stream<dynamic> get stream => _controller.stream;

  /// Emit change event
  void emitEvent() {
    _controller.add(null);
  }
}

class Playlist {
  final List<Song> songs;
  Playlist(this.songs);

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

  /// Returns next song index
  ///
  /// Function will return incremented `index`
  int getNextSongId(int index) {
    final int nextSongIndex = getSongIndexById(index) + 1;
    if (nextSongIndex >= length) {
      return getSongIdByIndex(0);
    }
    return getSongIdByIndex(nextSongIndex);
  }

  /// Returns prev song index
  ///
  /// Function will return decremented `index`
  int getPrevSongId(int index) {
    final int prevSongIndex = getSongIndexById(index) - 1;
    if (prevSongIndex < 0) {
      return getSongIdByIndex(length - 1);
    }
    return getSongIdByIndex(prevSongIndex);
  }
}

/// What playlist is now playing? type
enum PlayingPlaylistType { global, custom }

/// A class to fetch songs/control json/control playlists/search in playlists
class PlaylistControl {
  /// Playlist for songs
  Playlist globalPlaylist;

  /// Playlist some other playlist, less then global e.g.
  Playlist _customPlaylist;

  /// What playlist is now playing?
  PlayingPlaylistType _playingPlaylist = PlayingPlaylistType.global;

  /// Songs fetcher class instance
  final SongsFetcher fetcher = SongsFetcher();

  /// Current index of playing track in `playlist`
  int playingTrackIdState;

  /// Controller for stream of playlist changes
  SongsListChangeStreamController _songsListChangeStreamController =
      SongsListChangeStreamController();

  // Getters

  /// Common field for both `globalPlaylist` and `_customPlaylist`, its return depends on which playlist is now playing (`_playingPlaylist`)
  Playlist get playlist {
    return _playingPlaylist == PlayingPlaylistType.global
        ? globalPlaylist
        : _customPlaylist;
  }

  /// Get current playing song
  ///
  /// FIXME: 0 index reference may fail
  Song get currentSong {
    return globalPlaylist.getSongById(playingTrackIdState);
  }

  /// Whether playlist control is ready to provide player instance sources to play tracks
  bool get playReady => globalPlaylist != null;

  /// Is songs list empty?
  bool get songsEmpty => playlist.isEmpty;

  /// Returns current playlist songs list
  List<Song> get songs => playlist.songs;

  /// A stream of changes on playlist
  Stream<dynamic> get onPlaylistListChange =>
      _songsListChangeStreamController.stream;

  /// Emit event to `onPlaylistListChange`
  void emitPlaylistChange() {
    _songsListChangeStreamController.emitEvent();
  }

  // Methods from playlist class
  /// Works on `globalPlaylist`
  Song getSongById(int index) => globalPlaylist.getSongById(index);
  Song getSongByIndex(int index) => playlist.getSongByIndex(index);
  /// Works on `globalPlaylist`
  int getSongIdByIndex(int index) => globalPlaylist.getSongIdByIndex(index);
  int getSongIndexById(int index) => playlist.getSongIndexById(index);
  int getNextSongId(int index) => playlist.getNextSongId(index);
  int getPrevSongId(int index) => playlist.getPrevSongId(index);

  PlaylistControl() {
    _init();
  }

  Future<void> _init() async {
    // Permissions
    // TODO: add button to re-request permissions
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);

    Map<PermissionGroup, PermissionStatus> permissions;
    if (permission == PermissionStatus.denied)
      permissions = await PermissionHandler()
          .requestPermissions([PermissionGroup.storage]);

    await fetcher.serializer.initJson(); // Init songs json actions
    globalPlaylist = Playlist(await fetcher.serializer
        .readJson()); // Get songs from json and create global playlist

    // Get saved data
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int savedSongId = prefs.getInt(Constants.PrefKeys.songIdInt);
    int savedSongPos = prefs.getInt(Constants.PrefKeys.songPositionInt);

    // songsEmpty condition is here to avoid errors when trying to get first song index
    if (!songsEmpty) {
      // Setup initial playing state index from prefs
      playingTrackIdState = savedSongId ?? playlist.getSongIdByIndex(0);

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
    if (!songsEmpty && playingTrackIdState == null) {
      // Setup initial playing state index from prefs
      playingTrackIdState = savedSongId ?? playlist.getSongIdByIndex(0);

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

  /// Set another playlist to play
  void setPlaylist(List<Song> songs) {
    // FIXME: try to optimize this, add some comparison e.g ???
    _customPlaylist = Playlist(songs); // NOTE The order of these two instruction matters
    _playingPlaylist = PlayingPlaylistType.custom;
  }

  /// Sets playlist default that is made from list of all song on user device
  void resetPlaylist() {
    _playingPlaylist = PlayingPlaylistType.global;
    _customPlaylist = Playlist([]);
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
