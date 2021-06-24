/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:collection/collection.dart';
import 'package:sweyer/sweyer.dart';

/// The type of currently playing queue.
enum QueueType {
  /// Queue of all songs.
  allSongs,

  /// Queue of all albums.
  allAlbums,

  /// Queue of all playlists.
  allPlaylists,

  /// Queue of all artistt.
  allArtists,

  /// Queue of searched tracks.
  searched,

  /// Queue that has same [SongOrigin].
  origin,

  /// Some arbitrary queue. Сannot have modified state.
  ///
  /// Made up when:
  /// * user adds a song to [persistent] queue, that’s not included in it
  /// * after restoring shuffled queue (as the info about the queue it was shuffled from is lost on app restart)
  /// * in any other ways not described yet
  arbitrary,
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

    // TODO: docs
  int? _nextIndex(int index) {
    if (index < 0) {
      return null;
    }
    final nextIndex = index + 1;
    if (nextIndex >= songs.length) {
      return 0;
    }
    return nextIndex;
  }

  int? _prevIndex(int index) {
    if (index < 0) {
      return null;
    }
    final prevIndex = index - 1;
    if (prevIndex < 0) {
      return songs.length - 1;
    }
    return prevIndex;
  }

  int get length => songs.length;
  bool get isEmpty => songs.isEmpty;
  bool get isNotEmpty => songs.isNotEmpty;

  /// Clears the songs list.
  void clear() {
    songs.clear();
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
  Song removeAt(int index) {
    return songs.removeAt(index);
  }

  @override
  bool contains(Song song) {
    return byId.contains(song.id);
  }

  @override
  bool remove(Song song) {
    return byId.remove(song.id);
  }

  @override
  Song? get(Song song) {
    return byId.get(song.id);
  }

  @override
  int getIndex(Song song) {
    return byId.getIndex(song.id);
  }

  @override
  Song? getNext(Song song) {
    return byId.getNext(song.id);
  }

  // TODO: docs
  Song getNextAt(int index) {
    return songs[_nextIndex(index)!];
  }

  @override
  Song? getPrev(Song song) {
    return byId.getPrev(song.id);
  }

  Song getPrevAt(int index) {
    return songs[_prevIndex(index)!];
  }

  /// Searches each song of this queue in another [queue] and removes
  /// it if doesn't find it.
  void compareAndRemoveObsolete(Queue queue) {
    songs.removeWhere((song) {
      return queue.songs.firstWhereOrNull((el) => el.sourceId == song.sourceId) == null;
    });
  }
}

/// Describes generic operations on the song queue.
abstract class _QueueOperations<T> {
  /// Checks if queue contains song.
  bool contains(T arg);

  /// Removes song.
  bool remove(T arg);

  /// Retruns song.
  Song? get(T arg);

  /// Returns song index.
  int getIndex(T arg);

  /// Returns next song.
  Song? getNext(T arg);

  /// Returns prev song.
  Song? getPrev(T arg);
}

/// Implements opertions on [queue] by IDs of the [Song]s.
class _QueueOperationsById implements _QueueOperations<int> {
  const _QueueOperationsById(this.queue);
  final Queue queue;

  @override
  bool contains(int id) {
    return queue.songs.firstWhereOrNull((el) => el.id == id) != null;
  }

  @override
  bool remove(int id) {
    bool removed = false;
    queue.songs.removeWhere((el) {
      if (el.id == id) {
        removed = true;
        return true;
      }
      return false;
    });
    return removed;
  }

  @override
  Song? get(int id) {
    return queue.songs.firstWhereOrNull((el) => el.id == id);
  }

  @override
  int getIndex(int id) {
    return queue.songs.indexWhere((el) => el.id == id);
  }

  @override
  Song? getNext(int id) {
    final index = queue._nextIndex(getIndex(id));
    return index == null ? null : queue.songs[index];
  }

  @override
  Song? getPrev(int id) {
    final index = queue._prevIndex(getIndex(id));
    return index == null ? null : queue.songs[index];
  }
}
