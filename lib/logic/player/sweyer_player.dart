import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:sweyer/logic/models/song.dart';
import 'package:sweyer/logic/player/apple_music_player.dart';
import 'package:sweyer/logic/player/just_audio_player.dart';

/// Abstract base class for all player implementations.
abstract class SweyerPlayer {
  /// Dispose any resources used by the player.
  Future<void> dispose();

  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Stops playback.
  Future<void> stop();

  /// Seeks to [position].
  Future<void> seek(Duration position);

  /// Sets playback volume.
  Future<void> setVolume(double volume);

  /// Sets playback speed.
  Future<void> setSpeed(double speed);

  /// Sets the player loop [mode].
  Future<void> setLoopMode(LoopMode mode);

  /// Prepares [song] for playback.
  Future<void> setSong(Song song);

  /// Emits whether playback is active.
  Stream<bool> get playingStream;

  /// Emits the current playback position.
  Stream<Duration> get positionStream;

  /// Emits the buffered playback position.
  Stream<Duration> get bufferedPositionStream;

  /// Emits changes to the processing state.
  Stream<ProcessingState> get processingStateStream;

  /// Emits whether single-song looping is enabled.
  Stream<bool> get loopingStream;

  /// Emits changes to the loop mode.
  Stream<LoopMode> get loopModeStream;

  /// Whether playback is active.
  bool get playing;

  /// Current playback position.
  Duration get position;

  /// Current buffered playback position.
  Duration get bufferedPosition;

  /// Current processing state.
  ProcessingState get processingState;

  /// Whether single-song looping is enabled.
  bool get looping;

  /// Current loop mode.
  LoopMode get loopMode;

  /// Current playback speed.
  double get speed;

  factory SweyerPlayer.create() {
    if (Platform.isIOS) {
      return AppleMusicPlayer();
    }
    return JustAudioPlayer();
  }
}
