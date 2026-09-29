import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:sweyer/logic/models/song.dart';
import 'package:sweyer/logic/player/apple_music_player.dart';
import 'package:sweyer/logic/player/just_audio_player.dart';

sealed class SetSongResult {
  const SetSongResult();
}

/// The song was prepared successfully.
final class SetSongSuccess extends SetSongResult {
  const SetSongSuccess();
}

/// The request was superseded by another song preparation request.
final class SetSongInterrupted extends SetSongResult {
  const SetSongInterrupted();
}

/// The song is no longer available from the player's media source.
final class SetSongUnavailable extends SetSongResult {
  const SetSongUnavailable(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

/// The player failed to prepare the song without proving it unavailable.
final class SetSongFailure extends SetSongResult {
  const SetSongFailure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

sealed class PlayResult {
  const PlayResult();
}

/// Playback started successfully.
final class PlaySuccess extends PlayResult {
  const PlaySuccess();
}

/// Playback failed to start.
final class PlayFailure extends PlayResult {
  const PlayFailure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

/// Abstract base class for all player implementations.
abstract class SweyerPlayer {
  /// Dispose any resources used by the player.
  Future<void> dispose();

  /// Starts or resumes playback and reports the expected outcome.
  Future<PlayResult> play();

  /// Pauses playback.
  Future<void> pause();

  /// Stops playback.
  Future<void> stop();

  /// Seeks to [position].
  Future<void> seek(Duration position);

  /// Sets playback speed.
  Future<void> setSpeed(double speed);

  /// Sets the player loop [mode].
  Future<void> setLoopMode(LoopMode mode);

  /// Prepares [song] for playback and reports the expected outcome.
  Future<SetSongResult> setSong(Song song);

  /// Emits whether playback is active.
  Stream<bool> get playingStream;

  /// Emits the current playback position.
  Stream<Duration> get positionStream;

  /// Emits changes to the processing state.
  Stream<ProcessingState> get processingStateStream;

  /// Emits whether single-song looping is enabled.
  Stream<bool> get loopingStream;

  /// Whether playback is active, or `false` before the first state update.
  bool get playing;

  /// Current playback position, or [Duration.zero] before the first update.
  Duration get position;

  /// Current buffered playback position, or [Duration.zero] before the first update.
  Duration get bufferedPosition;

  /// Current processing state, or [ProcessingState.idle] before the first update.
  ProcessingState get processingState;

  /// Whether single-song looping is enabled, or `false` before the first update.
  bool get looping;

  /// Current playback speed, or `1` before the first update.
  double get speed;

  factory SweyerPlayer.create() {
    if (Platform.isIOS) {
      return AppleMusicPlayer();
    }
    return JustAudioPlayer();
  }
}
