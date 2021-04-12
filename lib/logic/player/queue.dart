/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

// @dart = 2.12

import 'package:audio_service/audio_service.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:collection/collection.dart';
import 'package:sweyer/sweyer.dart';

/// The type of currently playing queue.
enum QueueType {
  /// Queue of all songs.
  all,

  /// Queue of searched tracks.
  searched,

  /// Some persistent queue on user device, has an id.
  /// See [PersistentQueue].
  persistent,

  /// Some arbitrary queue. Сannot have modified state.
  ///
  /// Made up when:
  /// * user adds a song to [persistent] queue, that’s not included in it
  /// * after restoring shuffled queue (as the info about the queue it was shuffled from is lost on app restart)
  /// * in any other ways not described yet
  arbitrary,
}

extension QueueTypeSerialization on QueueType {
  String get value => EnumToString.convertToString(this);
}

/// Class, representing a queue in application
///
/// It is more array-like, as it has shuffle methods and explicit indexing.
class Queue implements _QueueOperations<Song> {
  /// Creates queue from songs list.
  Queue(this._songs) {
    byId = _QueueOperationsById(this);
  }

  /// Queue songs.
  List<Song> get songs => _songs;
  List<Song> _songs;
  /// Sets songs.
  void setSongs(List<Song> value) {
    _songs = value;
  }

  /// Provides operations on queue by [Song.id].
  late final _QueueOperationsById byId;

  /// Returns a shuffled copy of songs.
  static List<Song> shuffleSongs(List<Song> songsToShuffle) {
    final List<Song> shuffledSongs = List.from(songsToShuffle);
    shuffledSongs.shuffle();
    return shuffledSongs;
  }

  int get length => songs.length;
  bool get isEmpty => songs.isEmpty;
  bool get isNotEmpty => songs.isNotEmpty;

  /// Clears the songs list.
  void clear() {
    songs.clear();
  }

  /// Checks if queue contains song.
  bool contains(Song song) {
    for (final _song in _songs) {
      if (_song == song) {
        return true;
      }
    }
    return false;
  }

  /// Adds the [song] (a copy of it) to a queue.
  void add(Song song) {
    songs.add(song.copyWith());
  }

  /// Inserts the [song] (a copy of it) to a given position in queue.
  void insert(int index, Song song) {
    songs.insert(index, song.copyWith());
  }

  /// Removes a song from the queue at given [index] and returns
  /// the removed object.
  Song removeSongAt(int index) {
    return songs.removeAt(index);
  }

  @override
  void removeSong(Song song) {
    byId.removeSong(song.id);
  }

  @override
  Song? getSong(Song song) {
    return byId.getSong(song.id);
  }

  @override
  int getSongIndex(Song song) {
    return byId.getSongIndex(song.id);
  }

  @override
  Song? getNextSong(Song song) {
    return byId.getNextSong(song.id);
  }

  @override
  Song? getPrevSong(Song song) {
    return byId.getPrevSong(song.id);
  }

  /// Searches each song of this queue in another [queue] and removes
  /// it if doesn't find it.
  void compareAndRemoveObsolete(Queue queue) {
    songs.removeWhere((song) {
      return queue.getSong(song) == null;
    });
  }
}

/// Describes generic operations on the song queue.
abstract class _QueueOperations<T> {
  /// Removes song.
  void removeSong(T arg);

  /// Finds a song.
  Song? getSong(T arg);

  /// Returns song index.
  int getSongIndex(T arg);

  /// Finds a song and returns the one that goes after it.
  Song? getNextSong(T arg);

  /// Finds a song and returns the one that goes before it.
  Song? getPrevSong(T arg);
}

/// Implements opertions on [queue] by IDs of the [Song]s.
class _QueueOperationsById implements _QueueOperations<int> {
  const _QueueOperationsById(this.queue);
  final Queue queue;

  @override
  void removeSong(int id) {
    queue.songs.removeWhere((el) => el.id == id);
  }

  @override
  Song? getSong(int id) {
    return queue.songs.firstWhereOrNull((el) => el.id == id);
  }

  @override
  int getSongIndex(int id) {
    return queue.songs.indexWhere((el) => el.id == id);
  }

  @override
  Song? getNextSong(int id) {
    final songIndex = getSongIndex(id);
    if (songIndex < 0) {
      return null;
    }
    final nextSongIndex = songIndex + 1;
    if (nextSongIndex >= queue.songs.length) {
      return queue.songs[0];
    }
    return queue.songs[nextSongIndex];
  }

  @override
  Song? getPrevSong(int id) {
    final songIndex = getSongIndex(id);
    if (songIndex < 0) {
      return null;
    }
    final int prevSongIndex = songIndex - 1;
    if (prevSongIndex < 0) {
      return queue.songs.last;
    }
    return queue.songs[prevSongIndex];
  }
}
