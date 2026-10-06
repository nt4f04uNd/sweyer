/// Playback operations and state required by player UI controls.
abstract interface class PlaybackController {
  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  bool get playing;

  Stream<bool> get playingStream;

  Duration get position;

  Stream<Duration> get positionStream;

  Duration? get duration;
}
