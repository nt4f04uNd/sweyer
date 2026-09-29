import 'package:flutter/services.dart';
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
  Future<PlayResult> play() async {
    try {
      await _audioPlayer.play();
      return const PlaySuccess();
    } on PlayerException catch (error, stackTrace) {
      return PlayFailure(error, stackTrace);
    } on PlatformException catch (error, stackTrace) {
      return PlayFailure(error, stackTrace);
    }
  }

  @override
  Future<void> pause() => _audioPlayer.pause();

  @override
  Future<void> stop() => _audioPlayer.stop();

  @override
  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  @override
  Future<void> setSpeed(double speed) => _audioPlayer.setSpeed(speed);

  @override
  Future<void> setLoopMode(LoopMode mode) => _audioPlayer.setLoopMode(mode);

  @override
  Future<SetSongResult> setSong(Song song) async {
    try {
      await _audioPlayer.setAudioSource(ProgressiveAudioSource(Uri.parse(song.contentUri)));
      return const SetSongSuccess();
    } on PlayerInterruptedException {
      return const SetSongInterrupted();
    } on PlayerException catch (error, stackTrace) {
      return SetSongUnavailable(error, stackTrace);
    } on PlatformException catch (error, stackTrace) {
      if (error.code == 'abort') {
        return const SetSongInterrupted();
      }
      return SetSongFailure(error, stackTrace);
    }
  }

  @override
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  @override
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  @override
  Stream<ProcessingState> get processingStateStream => _audioPlayer.processingStateStream;

  @override
  Stream<bool> get loopingStream => _audioPlayer.loopModeStream.map((event) => event == LoopMode.one);

  @override
  bool get playing => _audioPlayer.playing;

  @override
  Duration get position => _audioPlayer.position;

  @override
  Duration get bufferedPosition => _audioPlayer.bufferedPosition;

  @override
  ProcessingState get processingState => _audioPlayer.processingState;

  @override
  bool get looping => _audioPlayer.loopMode == LoopMode.one;

  @override
  double get speed => _audioPlayer.speed;
}
