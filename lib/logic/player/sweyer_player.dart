import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:sweyer/logic/models/song.dart';
import 'package:sweyer/logic/player/apple_music_player.dart';
import 'package:sweyer/logic/player/just_audio_player.dart';

/// Abstract base class for all player implementations.
abstract class SweyerPlayer {
  /// Dispose any resources used by the player.
  Future<void> dispose();

  /// Playback control.
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setSpeed(double speed);
  Future<void> setLoopMode(LoopMode mode);
  Future<void> playPause();
  Future<void> switchLooping();

  /// Queue management.
  Future<void> setSong(Song song);
  Future<void> playNext();
  Future<void> playPrevious();

  /// State streams.
  Stream<bool> get playingStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get bufferedPositionStream;
  Stream<ProcessingState> get playerStateStream;
  Stream<bool> get loopingStream;
  Stream<LoopMode> get loopModeStream;

  /// Current state.
  bool get playing;
  Duration get currentPosition;
  Duration get position;
  Duration get bufferedPosition;
  ProcessingState get playerState;
  ProcessingState get processingState;
  bool get looping;
  LoopMode get loopMode;
  double get speed;

  factory SweyerPlayer.create() {
    if (Platform.isIOS) {
      return AppleMusicPlayer();
    }
    return JustAudioPlayer();
  }
}
