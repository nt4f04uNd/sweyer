import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:playify/playify.dart' as playify;
import 'package:sweyer/logic/models/song.dart';
import 'package:sweyer/logic/player/sweyer_player.dart';

/// Player implementation using Playify for Apple Music.
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
