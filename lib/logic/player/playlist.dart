/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:enum_to_string/enum_to_string.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// The type of currently playing queue.
enum QueueType {
  /// Queue of all songs.
  all,

  /// Queue of searched tracks.
  searched,

  /// Some persistent queue on user device, has id.
  /// Maybe:
  /// * album
  /// * playlist
  /// * favorites
  /// * etc.
  persistent,

  /// Some arbitrary queue.
  /// Сannot have modified state.
  /// Made up when:
  /// * user adds a song to [persistent] queue, that’s not included in it
  /// * after restoring shuffled queue (as the info about the queue it was shuffled from is lost on app restart)
  /// * in any other ways not described yet
  arbitrary,
}

extension QueueTypeSerialization on QueueType {
  String get value => EnumToString.convertToString(this);
}

abstract class PersistentQueue extends Queue with EquatableMixin {
  PersistentQueue({@required this.id, @required List<Song> songs})
      : super(songs);
  PersistentQueue.shuffled({@required this.id, @required List<Song> songs})
      : super.shuffled(songs);
  final int id;
  @override
  List<Object> get props => [id];
}

/// Class, representing a queue in application
///
/// It is more array-like, as it has shuffle methods and explicit indexing.
class Queue implements _QueueOperations<Song> {
  Queue(this._songs) {
    byId = _QueueOperationsById(this);
  }

  /// Creates queue and shuffles specified songs array
  Queue.shuffled(List<Song> songs) : this._songs = Queue.shuffleSongs(songs) {
    byId = _QueueOperationsById(this);
  }

  List<Song> _songs;
  _QueueOperationsById byId;

  /// Returns a shuffled copy of songs.
  static List<Song> shuffleSongs(List<Song> songsToShuffle) {
    List<Song> shuffledSongs = List.from(songsToShuffle);
    shuffledSongs.shuffle();
    return shuffledSongs;
  }

  /// Returns queue length
  int get length => _songs.length;
  bool get isEmpty => _songs.isEmpty;
  bool get isNotEmpty => _songs.isNotEmpty;

  List<Song> get songs => _songs;

  /// Explicit setter for songs
  void setSongs(List<Song> songs) {
    _songs = songs;
  }

  /// Clears the songs list
  void clear() {
    songs.clear();
  }

  /// Checks if queue contains song
  bool contains(Song song) {
    for (final _song in _songs) {
      if (_song == song) return true;
    }
    return false;
  }

  /// Adds song (copy of it) to a queue
  void add(Song song) {
    _songs.add(song.copyWith());
  }

  /// Insers song (copy of it) to a given position in queue
  void insert(int index, Song song) {
    _songs.insert(index, song.copyWith());
  }

  void removeSong(Song song) {
    byId.removeSong(song.id);
  }

  /// Returns the removed object
  Song removeSongAt(int index) {
    return _songs.removeAt(index);
  }

  /// Finds the song
  Song getSong(Song song) {
    return byId.getSong(song.id);
  }

  /// Returns the song index in array
  int getSongIndex(Song song) {
    return byId.getSongIndex(song.id);
  }

  /// Returns next song
  Song getNextSong(Song song) {
    return byId.getNextSong(song.id);
  }

  /// Returns prev song
  Song getPrevSong(Song song) {
    return byId.getPrevSong(song.id);
  }

  /// Will search each song in another queue and remove it if won't find it.
  void compareAndRemoveObsolete(Queue queue) {
    _songs.removeWhere((song) {
      return queue.getSong(song) == null;
    });
  }
}

abstract class _QueueOperations<T> {
  void removeSong(T arg);

  /// Finds the song
  Song getSong(T arg);
  int getSongIndex(T arg);
  Song getNextSong(T arg);
  Song getPrevSong(T arg);
}

class _QueueOperationsById implements _QueueOperations<int> {
  const _QueueOperationsById(this._queue);
  final Queue _queue;

  Song getSong(int id) {
    return _queue._songs.firstWhere((el) => el.id == id, orElse: () => null);
  }

  int getSongIndex(int id) {
    return _queue._songs.indexWhere((el) => el.id == id);
  }

  Song getNextSong(int id) {
    final songIndex = getSongIndex(id);
    if (songIndex < 0) {
      return null;
    }
    final nextSongIndex = songIndex + 1;
    if (nextSongIndex >= _queue._songs.length) {
      return _queue._songs[0];
    }
    return _queue._songs[nextSongIndex];
  }

  Song getPrevSong(int id) {
    final songIndex = getSongIndex(id);
    if (songIndex < 0) {
      return null;
    }
    final int prevSongIndex = songIndex - 1;
    if (prevSongIndex < 0) {
      return _queue._songs.last;
    }
    return _queue._songs[prevSongIndex];
  }

  void removeSong(int id) {
    _queue._songs.removeWhere((el) => el.id == id);
  }
}
