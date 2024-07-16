import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sweyer/sweyer.dart';

@visibleForTesting
class PlaybackRepository {
  final songId = Prefs.songId;
}

/// Controls information about currently playing content and allows to perform related actions.
class PlaybackControl extends Control {
  static PlaybackControl instance = PlaybackControl();

  @override
  void init() {
    super.init();
    if (_songSubject.isClosed) {
      _songSubject = BehaviorSubject();
    }
  }

  @override
  void dispose() {
    if (!disposed.value) {
      _songSubject.close();
    }
    super.dispose();
  }

  @visibleForTesting
  late final repository = PlaybackRepository();

  /// A stream of changes on [currentSong].
  Stream<Song> get onSongChange => _songSubject.stream;
  BehaviorSubject<Song> _songSubject = BehaviorSubject();

  /// The current playing song.
  Song get currentSong {
    return _songSubject.value!;
  }

  /// The current playing song, may be `null`.
  Song? get currentSongNullable {
    return _songSubject.value;
  }

  /// Returns index of [currentSong] in the current queue.
  ///
  /// If current song cannot be found for some reason, will fallback the state
  /// to the index `0` and return it.
  int get currentSongIndex {
    var index = QueueControl.instance.state.current.byId.getIndex(currentSong.id);
    if (index < 0) {
      final firstSong = QueueControl.instance.state.current.songs[0];
      changeSong(firstSong);
      index = 0;
    }
    return index;
  }

  /// Currently playing persistent queue when song is added via [QueueControl.playOriginNext]
  /// or [QueueControl.addOriginToQueue].
  ///
  /// Used for showing [CurrentIndicator] for [SongOrigin]s.
  ///
  /// See also [Song.origin].
  SongOrigin? get currentSongOrigin => currentSong.origin;

  /// Changes current song id and emits change event.
  /// This allows to change the current id visually, separately from the player.
  ///
  /// Also, uses [Song.origin] to set [currentSongOrigin].
  void changeSong(Song song) {
    if (song.id != currentSongNullable?.id) {
      repository.songId.set(song.id);
    }
    if (!identical(song, currentSongNullable)) {
      _songSubject.add(song);
    }
  }
}
