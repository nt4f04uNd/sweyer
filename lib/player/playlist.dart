import 'dart:async';

import 'package:app/player/song.dart';

/// Class to create change and control stream
/// 
/// TODO: rename into PlaylistChangeStreamController
class TrackListChangeStreamController {
  /// Stream controller used to create stream of changes on track list (just to notify)
  StreamController _controller = StreamController<void>.broadcast();

  /// Get stream of notifier events about changes on track list
  get stream => _controller.stream;

  /// Emit change event
  void emitEvent() {
    _controller.add(null);
  }
}

class Playlist {
  final List<Song> songs;
  Playlist(this.songs);

  /// Get playlist length
  int get length => songs.length;

  /// Returns song object by index in songs array
  Song getSongByIndex(int index) {
    return songs[index];
  }

  /// Returns song object by song id
  Song getSongById(int id) {
    return songs.firstWhere((el) => el.id == id);
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

class PlaylistControl {

}
