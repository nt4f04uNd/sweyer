/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweyer/sweyer.dart';

import 'package:sweyer/api.dart' as API;

class ContentState {
  ContentState();

  /// Current id of playing song
  int _currentSongId;

  /// A general art color change the UI
  Color _currentArtColor;

  /// Cancelable operation for getting the art color
  CancelableOperation _thiefOperation;

  final Map<PlaylistType, Playlist> _playlists = {
    PlaylistType.global: null,
    PlaylistType.searched: Playlist([]),
    PlaylistType.shuffled: Playlist([]),
  };

  /// What playlist is now playing?
  PlaylistType _currentPlaylistType = PlaylistType.global;

  /// What playlist was before shuffling
  ///
  /// This isn't saved and will be restored after activity re-open
  PlaylistType _playlistTypeBeforeShuffle = PlaylistType.global;

  /// Sort feature
  SortFeature _currentSortFeature = SortFeature.date;

  //****************** Getters *****************************************************
  /// Get current playing song (always being searched in globalPlaylist)
  Song get currentSong {
    return _playlists[PlaylistType.global].getSongById(_currentSongId) ??
        _playlists[PlaylistType.global].songs[0];
  }

  /// Get current playing id
  int get currentSongId => _currentSongId;
  Color get currentArtColor => _currentArtColor;
  PlaylistType get currentPlaylistType => _currentPlaylistType;
  Playlist get currentPlaylist => _playlists[_currentPlaylistType];
  Playlist getPlaylist(PlaylistType playlistType) => _playlists[playlistType];
  SortFeature get currentSortFeature => _currentSortFeature;

  //****************** Setters *****************************************************
  /// Changes current song id and emits change event
  /// This allows to change the current id visually, separately from the player
  void changeSong(int songId) {
    _currentSongId = songId;
    emitSongChange(currentSong);
  }

  //****************** Methods *****************************************************
  /// Returns a [currentSong] index in current playlist (by default)
  int get currentSongIndex => currentPlaylist.getSongIndexById(_currentSongId);

  //****************** Streams *****************************************************
  /// Controller for stream of playlist changes
  StreamController<PlaylistType> _playlistChangeStreamController =
      StreamController<PlaylistType>.broadcast();

  /// Controller for stream of song changes
  StreamController<Song> _songChangeStreamController =
      StreamController<Song>.broadcast();

  /// Controller for stream of song changes
  StreamController<Color> _artColorChangeStreamController =
      StreamController<Color>.broadcast();

  /// A stream of changes on playlist
  Stream<PlaylistType> get onPlaylistListChange =>
      _playlistChangeStreamController.stream;

  /// A stream of changes on song
  Stream<Song> get onSongChange => _songChangeStreamController.stream;

  /// A stream of changes on art color
  Stream<Color> get onArtColorChange => _artColorChangeStreamController.stream;

  /// Emit event to [onPlaylistListChange]
  ///
  /// Should be only called when user can see playlist change, i.e. songs sort.
  /// Shouldn't be called, e.g. on tile click, when playlist changes, but user can't actually see it
  ///
  /// Parameter [playlistType] denotes preferred update scope, this means e.g. that if [PlaylistType.searched] changes, [ListView] dependant on [PlaylistType.global] shouldn't get any updates
  void emitPlaylistChange([PlaylistType playlistType = PlaylistType.global]) {
    _playlistChangeStreamController.add(playlistType);
  }

  /// Emits song change event
  void emitSongChange(Song song) {
    _songChangeStreamController.add(song);
  }

  /// Emits art color change event
  void emitArtColorChange(Color color) {
    _artColorChangeStreamController.add(color);
  }

  void dispose() {
    _playlistChangeStreamController.close();
    _artColorChangeStreamController.close();
    _songChangeStreamController.close();
  }
}

/// A class to
/// 1. Fetch songs
/// 2. Control playlist json
/// 3. Manage playlists
/// 4. Search in playlists
///
/// etc.
abstract class ContentControl {
  static ContentState state = ContentState();

  /// An object to serialize songs
  static SongsSerialization songsSerializer = SongsSerialization();

  /// An object to serialize playlist
  static PlaylistSerialization playlistSerializer = PlaylistSerialization();

  /// Songs fetcher class instance
  static final SongsFetcher songsFetcher = SongsFetcher();

  /// A subscription to song changes, needed to get current art color
  // static StreamSubscription<Song> _songChangeSubscription;

  /// Represents songs fetch on app start
  static bool initFetching = true;

  /// Whether playlist control is ready to provide to player instance the sources to play tracks
  static bool get playReady => state._playlists[PlaylistType.global] != null;

  /// The main data app initialization function
  /// Inits all playlists
  /// Also handles no-permissions situations
  static Future<void> init() async {
    if (Permissions.granted) {
      // Reset [playReady]
      state._playlists[PlaylistType.global] = null;

      initFetching = true;
      await Future.wait([
        songsSerializer.initJson(), // Init songs json
        playlistSerializer.initJson() // Init playlist json
      ]);
      // Get songs from json and create global playlist
      state._playlists[PlaylistType.global] =
          Playlist(await songsSerializer.readJson());
      await _restoreSortFeature();
      await filterSongs(emitChangeEvent: false);
      sortSongs(emitChangeEvent: false);

      await _restoreLastSong();

      // // Setting up the subscription to get the art color
      // _songChangeSubscription = onSongChange.listen((event) async {
      //   var prevArtColor = _artColor;
      //   if (event.albumArtUri != null) {
      //     // Cancel the operation if it didn't finish by that moment
      //     if (_thiefOperation != null) _thiefOperation.cancel();

      //     _thiefOperation = CancelableOperation.fromFuture(() async {
      //       var prevArtColor = _artColor;
      //       final image =
      //           await getImageFromProvider(FileImage(File(event.albumArtUri)));
      //       List<int> colorRGBList = await getColorFromImage(image, 1);
      //       _artColor = Color.fromRGBO(
      //           colorRGBList[0], colorRGBList[1], colorRGBList[2], 1.0);

      //       if (prevArtColor != _artColor) emitArtColorChange(_artColor);
      //       _thiefOperation = null;
      //     }());
      //   } else {
      //     _artColor = null;
      //     if (prevArtColor != _artColor) emitArtColorChange(_artColor);
      //   }
      // });

      await _restorePlaylist();

      _initialSongsFetch();
    } else {
      // Init empty playlist if no permission granted
      if (!playReady) {
        state._playlists[PlaylistType.global] = Playlist([]);
      }
    }

    // Emit event to track change stream
    state.emitPlaylistChange();
  }

  //****************** Playlist manipulation methods *****************************************************

  /// Sets searched playlist
  ///
  /// This function doesn't call [emitPlaylistChange()]
  ///
  /// @param [songs] — can be omitted and if so, then the playlist itself won't be changed,
  /// the state is only will get switched to it, and also playlist will be is serialized
  static Future<void> setSearchedPlaylist({List<Song> songs}) async {
    if (songs != null) {
      state._playlists[PlaylistType.searched].setSongs(songs);
    }
    playlistSerializer.saveJson(state._playlists[PlaylistType.searched].songs);
    state._currentPlaylistType = PlaylistType.searched;
    Prefs.playlistTypeInt.setPref(value: 1);
    state._playlists[PlaylistType.shuffled].clear();
  }

  /// Shuffles from current playlist (by default)
  ///
  /// @param [shuffleFromPlaylist] if specified - shuffles from it.
  ///
  /// @param [songs] if specified - sets them.
  ///
  /// @param [emitChangeEvent] - if false, [ContentState.emitPlaylistChange] won't be called.
  static void setShuffledPlaylist({
    PlaylistType shuffleFrom,
    List<Song> songs,
    bool emitChangeEvent = true,
  }) {
    shuffleFrom ??= state._currentPlaylistType;

    state._playlistTypeBeforeShuffle = shuffleFrom;
    state._currentPlaylistType = PlaylistType.shuffled;
    Prefs.playlistTypeInt.setPref(value: 2);

    if (songs == null)
      state._playlists[PlaylistType.shuffled] =
          Playlist.shuffled(state._playlists[shuffleFrom].songs);
    else
      state._playlists[PlaylistType.shuffled].setSongs(songs);

    playlistSerializer.saveJson(state._playlists[PlaylistType.shuffled].songs);

    if (emitChangeEvent) {
      state.emitPlaylistChange();
    }
  }

  /// Returns playlist that was before shuffle and clears [shuffledPlaylist]
  ///
  /// @param [returnTo] if specified - returns to this playlist
  static void backFromShuffledPlaylist({PlaylistType returnTo}) {
    returnTo ??= state._playlistTypeBeforeShuffle;
    switch (returnTo) {
      case PlaylistType.global:
        resetPlaylists();
        break;
      case PlaylistType.searched:
        setSearchedPlaylist();
        break;
      default:
    }
    state._playlists[PlaylistType.shuffled].clear();
    state.emitPlaylistChange();
  }

  /// Switches to global playlist an resets all playlists except it.
  ///
  /// This function doesn't call [ContentState.emitPlaylistChange]
  static void resetPlaylists() {
    if (state._currentPlaylistType != PlaylistType.global) {
      Prefs.playlistTypeInt.setPref(value: 0); // Save to prefs
      playlistSerializer.saveJson(const []);
      state._currentPlaylistType = PlaylistType.global;
      state._playlists[PlaylistType.searched].clear();
      state._playlists[PlaylistType.shuffled].clear();
    }
  }

  /// Will match all the existing playlists with [PlaylistType.global]
  /// and remove not existing songs (or recreate a whole playlist anew in case of [PlaylistType.shuffled])
  ///
  /// @param [emitChangeEvent] - if false, [ContentState.emitPlaylistChange] won't be called.
  static void updatePlaylistsWithGlobal({bool emitChangeEvent = true}) {
    if (state._currentPlaylistType == PlaylistType.searched ||
        state._currentPlaylistType == PlaylistType.shuffled &&
            state._playlistTypeBeforeShuffle == PlaylistType.searched) {
      // Match searched playlist when it's the current or the current is shuffled, but it's been created from searched

      state._playlists[PlaylistType.searched]
          .compareAndRemoveObsolete(state._playlists[PlaylistType.global]);
    }

    if (state._currentPlaylistType != PlaylistType.global &&
        state.currentPlaylist.isEmpty) {
      //  Set playlist to global if searched or shuffled are happened to be zero-length
      ContentControl.resetPlaylists();
    } else {
      // Else update playlists
      switch (state._currentPlaylistType) {
        case PlaylistType.searched:
          // Update searched playlist
          setSearchedPlaylist();
          break;
        case PlaylistType.shuffled:
          // Update shuffled playlist
          setShuffledPlaylist(shuffleFrom: state._playlistTypeBeforeShuffle);
          break;
        default:
      }
    }

    // Update current song
    if ( // This first condition ensures that  [_restoreLastSong] will be called properly in [_initialSongsFetch] during the app setup process
        state._currentSongId != null && state.currentSongIndex == -1) {
      state.changeSong(state.currentPlaylist.songs[0].id);
      if (MusicPlayer.playerState == AudioPlayerState.PLAYING) {
        MusicPlayer.pause();
        MusicPlayer.play(state.currentSongId, silent: true);
      }
    }

    if (emitChangeEvent) {
      state.emitPlaylistChange();
    }
  }

  //****************** Song manipulation methods *****************************************************

  /// Refetch songs and update playlist
  static Future<void> refetchSongs() async {
    state._playlists[PlaylistType.global]
        // .setSongs(await songsFetcher.fetchSongs());
        .setSongs( await songsFetcher.fetchSongs());
    await filterSongs(emitChangeEvent: false);
    sortSongs(emitChangeEvent: false);
    updatePlaylistsWithGlobal(emitChangeEvent: false);
    songsSerializer.saveJson(state._playlists[PlaylistType.global].songs);
    state.emitPlaylistChange();
  }

  /// Search in playlist song array by query
  static Iterable<Song> searchSongs(String query) {
    if (query != '') {
      // Lowercase to bring strings to one format
      query = query.toLowerCase();
      final split = query.split(" ");
      return state._playlists[PlaylistType.global].songs.where((el) {
        return split
                .map<bool>((word) => // Words search
                    el.title.toLowerCase().contains(word) ||
                    el.artist.toLowerCase().contains(word) ||
                    el.album.toLowerCase().contains(word))
                .every((e) => e) ||
            RegExp('\\b\\w')
                // Find abbreviations (big baby tape - bbt)
                // FIXME: this is not working as expected for cyrillic
                .allMatches(el.title.toLowerCase())
                .fold("", (a, b) => a += b.group(0))
                .contains(query);
      });
    }
    return null;
  }

  /// Sort songs list by feature.
  ///
  /// @param [feature] - feature to sort by. If no value has passed then will sort by current sort feature.
  ///
  /// @param [emitChangeEvent] - if false, [ContentState.emitPlaylistChange] won't be called.
  static void sortSongs({SortFeature feature, bool emitChangeEvent = true}) {
    feature ??= state._currentSortFeature;
    switch (feature) {
      case SortFeature.date:
        state._playlists[PlaylistType.global].songs
            .sort((b, a) => a.dateModified.compareTo(b.dateModified));
        state._currentSortFeature = feature;
        Prefs.sortFeatureInt.setPref(value: 0);
        break;
      case SortFeature.title:
        state._playlists[PlaylistType.global].songs
            .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        state._currentSortFeature = feature;
        Prefs.sortFeatureInt.setPref(value: 1);
        break;
      default:
        throw Exception('In sortSongs - invalid sort feature: $feature');
        break;
    }

    // Emit event to track change stream
    if (emitChangeEvent) {
      state.emitPlaylistChange();
    }
  }

  /// Filter songs by min duration (for now, in future by size will be implemented).
  ///
  /// @param [emitChangeEvent] - if false, [ContentState.emitPlaylistChange] won't be called.
  static Future<void> filterSongs({bool emitChangeEvent = true}) async {
    state._playlists[PlaylistType.global].filter(
      FilterFeature.duration,
      duration: Duration(seconds: await Settings.minFileDurationInt.getPref()),
    );
    // Emit event to track change stream
    if (emitChangeEvent) {
      state.emitPlaylistChange();
    }
  }

  /// Deletes songs by specified id set
  static Future<void> deleteSongs(Set<int> idSet) async {
    Set<String> dataSet = {};
    idSet.forEach((id) {
      dataSet.add(state._playlists[PlaylistType.global].getSongById(id).data);
    });

    for (var id in idSet) {
      state._playlists[PlaylistType.global].removeSongById(id);
    }

    updatePlaylistsWithGlobal();

    try {
      await API.SongsHandler.deleteSongs(dataSet);
    } catch (e) {
      ShowFunctions.showToast(msg: "Ошибка при удалении");
      debugPrint("Deleting error: $e");
    }
  }

  //****************** Private methods for fetch *****************************************************

  /// Gets saved sort feature from [SharedPreferences]
  ///
  /// Default value is [SortFeature.date]
  static Future<void> _restoreSortFeature() async {
    final int savedSortFeature = await Prefs.sortFeatureInt.getPref();
    if (savedSortFeature == 0) {
      sortSongs(feature: SortFeature.date, emitChangeEvent: false);
    } else if (savedSortFeature == 1) {
      sortSongs(feature: SortFeature.title, emitChangeEvent: false);
    } else
      throw Exception(
          "_restoreSortFeature: wrong saved sortFeatureInt: $savedSortFeature");
  }

  /// Restores saved playlist from json if [playlistTypeInt] (saved [_currentPlaylistType]) is not global
  static Future<void> _restorePlaylist() async {
    int savedPlaylistType = await Prefs.playlistTypeInt.getPref();
    if (savedPlaylistType == 0) {
      state._currentPlaylistType = PlaylistType.global;
    } else if (savedPlaylistType == 1) {
      state._currentPlaylistType = PlaylistType.searched;
    } else if (savedPlaylistType == 2) {
      state._currentPlaylistType = PlaylistType.shuffled;
    } else
      throw Exception(
          "_restorePlaylist: wrong saved playlistTypeInt: $savedPlaylistType");

    if (state._currentPlaylistType != PlaylistType.global) {
      /// Get songs ids from json
      List<int> songIds = await playlistSerializer.readJson();
      List<Song> restoredSongs = [];
      songIds.forEach((id) {
        final Song songEl =
            state._playlists[PlaylistType.global].getSongById(id);
        if (songEl != null) restoredSongs.add(songEl);
      });

      switch (state._currentPlaylistType) {
        case PlaylistType.searched:
          setSearchedPlaylist(songs: restoredSongs);
          break;
        case PlaylistType.shuffled:
          setShuffledPlaylist(
              shuffleFrom: PlaylistType.global, songs: restoredSongs);
          break;
        default:
      }
    }
  }

  /// Function that fires right after json has fetched and when initial songs fetch has done
  ///
  /// Its main purpose to setup player to work with playlists
  static Future<void> _restoreLastSong() async {
    // songsEmpty condition is here to avoid errors when trying to get first song index
    if (state.currentPlaylist.isNotEmpty) {
      final int savedSongId = await Prefs.songIdIntNullable.getPref() ??
          state.currentPlaylist.songs[0].id;

      // Setup initial playing state index from prefs
      state._currentSongId = savedSongId;
      await API.ServiceHandler.sendSong(state.currentSong);
      // Set url of first track in player instance
      await MusicPlayer.setUri(state._currentSongId);
    }
  }

  /// Function to fetch all songs from user devices
  static Future<void> _initialSongsFetch() async {
    await refetchSongs();
    // Retry do all the same as before fetching songs (set duration, set track uri), if it hadn't been performed before (_playingSongIdState == null)
    if (state._currentSongId == null) {
      await _restoreLastSong();
    }
    initFetching = false;
  }
}
