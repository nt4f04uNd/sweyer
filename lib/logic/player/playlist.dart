/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';

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

  // Setters
  /// Explicit setter for songs
  void setSongs(List<Song> songs) {
    _songs = songs;
  }

  /// Clears the songs list
  void clear() {
    _songs = [];
  }

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
    if (nextSongIndex == -1) {
      return null;
    } else if (nextSongIndex >= length) {
      return _songs[0].id;
    }
    return _songs[nextSongIndex].id;
  }

  /// Returns prev song id
  int getPrevSongId(int id) {
    final int prevSongIndex = getSongIndexById(id) - 1;
    if (prevSongIndex == -2) {
      return null;
    } else if (prevSongIndex < 0) {
      return _songs[length - 1].id;
    }
    return _songs[prevSongIndex].id;
  }

  // TODO: implement file size filter
  void filter(FilterFeature feature, {Duration duration}) {
    if (feature == FilterFeature.duration) {
      assert(duration != null);
      _songs
          .retainWhere((el) => Duration(milliseconds: el.duration) >= duration);
    }
  }

  /// Will search each song in another playlist and remove it if won't find it.
  void compareAndRemoveObsolete(Playlist playlist) {
    _songs.removeWhere((song) {
      return playlist.getSongById(song.id) == null;
    });
  }
}
