import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:playify/playify.dart' as playify;
import 'package:sweyer/logic/models/song.dart';

/// Abstract base class for all player implementations
abstract class SweyerPlayer {
  /// Dispose any resources used by the player
  Future<void> dispose();

  /// Playback control
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setSpeed(double speed);
  Future<void> setLoopMode(LoopMode mode);
  Future<void> playPause();
  Future<void> switchLooping();

  /// Queue management
  Future<void> setSong(Song song);
  Future<void> playNext();
  Future<void> playPrevious();

  /// State streams
  Stream<bool> get playingStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get bufferedPositionStream;
  Stream<ProcessingState> get playerStateStream;
  Stream<bool> get loopingStream;
  Stream<LoopMode> get loopModeStream;

  /// Current state
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

/// Player implementation using just_audio
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

/// Player implementation using Playify for Apple Music
class AppleMusicPlayer implements SweyerPlayer {
  AppleMusicPlayer() {
    _playify = playify.Playify();
    _statusPlayingSyncSubscription = _statusStream.listen((status) {
      _playing = _mapStatusToPlaying(status);
    });
    _positionUpdateTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      try {
        final time = await _playify.getPlaybackTime();
        _cachedPosition = Duration(milliseconds: (time * 1000).toInt());
      } catch (e) {
        _cachedPosition = Duration.zero;
      }
    });
  }

  late final playify.Playify _playify;
  Duration _cachedPosition = Duration.zero;
  late Timer _positionUpdateTimer;
  LoopMode _loopMode = LoopMode.off;
  // Keep the instance, the plugin doens't support multiple.
  late final _statusStream = _playify.statusStream;
  late StreamSubscription _statusPlayingSyncSubscription;
  bool _playing = false;

  @override
  Future<void> dispose() async {
    _positionUpdateTimer.cancel();
    _statusPlayingSyncSubscription.cancel();
  }

  @override
  Future<void> play() async {
    if (_preparedSongId != null) {
      try {
        await _playify.playItem(songID: _preparedSongId!);
      } catch (e) {
        // Handle Apple Music playback error
      }
    } else {
      await _playify.play();
    }
  }

  @override
  Future<void> pause() async {
    await _playify.pause();
  }

  @override
  Future<void> stop() async {
    await _playify.pause();
  }

  @override
  Future<void> seek(Duration position) => _playify.setPlaybackTime(position.inSeconds.toDouble());

  @override
  Future<void> setVolume(double volume) => _playify.setVolume(volume);

  @override
  Future<void> setSpeed(double speed) {
    // Playify doesn't support playback speed
    return Future.value();
  }

  @override
  Future<void> setLoopMode(LoopMode mode) {
    _loopMode = mode;
    // Playify uses different enum for repeat modes
    final playifyMode = mode == LoopMode.one ? playify.Repeat.one : playify.Repeat.none;
    return _playify.setRepeatMode(playifyMode);
  }

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

  String? _preparedSongId;

  @override
  Future<void> setSong(Song song) async {
    _preparedSongId = song.sourceId.toString();
  }

  @override
  Future<void> playNext() => _playify.next();

  @override
  Future<void> playPrevious() => _playify.previous();

  bool _mapStatusToPlaying(playify.PlayifyStatus status) =>
      status == playify.PlayifyStatus.playing ||
      status == playify.PlayifyStatus.seekingBackward ||
      status == playify.PlayifyStatus.seekingForward;

  @override
  Stream<bool> get playingStream => _statusStream.map(_mapStatusToPlaying);

  @override
  Stream<Duration> get positionStream {
    return Stream.periodic(
      const Duration(milliseconds: 200),
      (_) async {
        try {
          final time = await _playify.getPlaybackTime();
          return Duration(milliseconds: (time * 1000).toInt());
        } catch (e) {
          return Duration.zero;
        }
      },
    ).asyncMap((event) => event);
  }

  @override
  Stream<Duration> get bufferedPositionStream => positionStream;

  @override
  Stream<ProcessingState> get playerStateStream => _statusStream.map((status) {
        switch (status) {
          case playify.PlayifyStatus.playing:
          case playify.PlayifyStatus.paused:
            return ProcessingState.ready;
          case playify.PlayifyStatus.stopped:
            return ProcessingState.idle;
          default:
            return ProcessingState.loading;
        }
      });

  @override
  Stream<bool> get loopingStream => Stream.value(looping);

  @override
  Stream<LoopMode> get loopModeStream => Stream.value(_loopMode);

  @override
  bool get playing => _playing;

  @override
  Duration get currentPosition => _cachedPosition;

  @override
  Duration get position => _cachedPosition;

  @override
  Duration get bufferedPosition => _cachedPosition;

  @override
  ProcessingState get playerState => playing ? ProcessingState.ready : ProcessingState.idle;

  @override
  ProcessingState get processingState => playing ? ProcessingState.ready : ProcessingState.idle;

  @override
  bool get looping => _loopMode == LoopMode.one;

  @override
  LoopMode get loopMode => _loopMode;

  @override
  double get speed => 1.0; // Playify doesn't support speed
}
