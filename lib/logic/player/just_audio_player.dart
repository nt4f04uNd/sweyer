import 'package:just_audio/just_audio.dart';
import 'package:sweyer/logic/models/song.dart';
import 'package:sweyer/logic/player/sweyer_player.dart';

/// Player implementation using just_audio.
class JustAudioPlayer implements SweyerPlayer {
  JustAudioPlayer() {
    _audioPlayer = AudioPlayer();
  }

  late final AudioPlayer _audioPlayer;

  @override
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  @override
  Future<void> play() => _audioPlayer.play();

  @override
  Future<void> pause() => _audioPlayer.pause();

  @override
  Future<void> stop() => _audioPlayer.stop();

  @override
  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  @override
  Future<void> setVolume(double volume) => _audioPlayer.setVolume(volume);

  @override
  Future<void> setSpeed(double speed) => _audioPlayer.setSpeed(speed);

  @override
  Future<void> setLoopMode(LoopMode mode) => _audioPlayer.setLoopMode(mode);

  @override
  Future<void> switchLooping() async {
    return setLoopMode(looping ? LoopMode.off : LoopMode.one);
  }

  @override
  Future<void> playPause() async {
    if (playing) {
      return pause();
    } else {
      return play();
    }
  }

  @override
  Future<void> setSong(Song song) async {
    try {
      await _audioPlayer.setAudioSource(
        ProgressiveAudioSource(Uri.parse(song.contentUri)),
      );
    } catch (e) {
      // Handle error
    }
  }

  @override
  Future<void> playNext() => _audioPlayer.seekToNext();

  @override
  Future<void> playPrevious() => _audioPlayer.seekToPrevious();

  @override
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  @override
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  @override
  Stream<Duration> get bufferedPositionStream => _audioPlayer.bufferedPositionStream;

  @override
  Stream<ProcessingState> get playerStateStream => _audioPlayer.processingStateStream;

  @override
  Stream<bool> get loopingStream => loopModeStream.map((event) => event == LoopMode.one);

  @override
  Stream<LoopMode> get loopModeStream => _audioPlayer.loopModeStream;

  @override
  bool get playing => _audioPlayer.playing;

  @override
  Duration get currentPosition => _audioPlayer.position;

  @override
  Duration get position => _audioPlayer.position;

  @override
  Duration get bufferedPosition => _audioPlayer.bufferedPosition;

  @override
  ProcessingState get playerState => _audioPlayer.processingState;

  @override
  ProcessingState get processingState => _audioPlayer.processingState;

  @override
  bool get looping => loopMode == LoopMode.one;

  @override
  LoopMode get loopMode => _audioPlayer.loopMode;

  @override
  double get speed => _audioPlayer.speed;
}
