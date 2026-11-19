import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:playify/playify.dart' as playify;
import 'package:rxdart/rxdart.dart';
import 'package:sweyer/logic/models/song.dart';
import 'package:sweyer/logic/player/sweyer_player.dart';

/// Player implementation backed by Playify and Apple's system music player.
class AppleMusicPlayer implements SweyerPlayer {
  AppleMusicPlayer({required ValueGetter<Duration> currentSongDuration}) : _currentSongDuration = currentSongDuration {
    _statusSubscription = _playify.statusStream.listen(_handleStatus);
  }

  static const _positionUpdateInterval = Duration(seconds: 1);

  // Position polling can lag behind the stopped event by one interval plus
  // method-channel and scheduling latency.
  static const _playbackCompletionTolerance = Duration(seconds: 2);

  final playify.Playify _playify = playify.Playify.instance;
  final ValueGetter<Duration> _currentSongDuration;
  final BehaviorSubject<bool> _playingSubject = BehaviorSubject.seeded(false);
  final BehaviorSubject<Duration> _positionSubject = BehaviorSubject.seeded(Duration.zero);
  final BehaviorSubject<ProcessingState> _processingStateSubject = BehaviorSubject.seeded(ProcessingState.idle);
  final BehaviorSubject<LoopMode> _loopModeSubject = BehaviorSubject.seeded(LoopMode.off);
  late final Stream<bool> _loopingStream = _loopModeSubject.stream.map((mode) => mode == LoopMode.one).distinct();

  late final StreamSubscription<playify.PlayifyStatus> _statusSubscription;
  Timer? _positionUpdateTimer;
  bool _preparing = false;
  bool _positionUpdateInFlight = false;
  int _positionRevision = 0;
  int _loopModeRevision = 0;
  int _loopModeRequest = 0;

  void _handleStatus(playify.PlayifyStatus status) {
    unawaited(_updateLoopMode());
    final wasPlaying = playing;
    final isPlaying = _mapStatusToPlaying(status);
    if (!_playingSubject.isClosed && _playingSubject.requireValue != isPlaying) {
      _playingSubject.add(isPlaying);
    }

    final songDuration = _currentSongDuration();
    final reachedEnd = !_preparing &&
        wasPlaying &&
        songDuration > Duration.zero &&
        position + _playbackCompletionTolerance >= songDuration;
    final processingState = switch (status) {
      playify.PlayifyStatus.stopped => reachedEnd ? ProcessingState.completed : ProcessingState.idle,
      playify.PlayifyStatus.playing ||
      playify.PlayifyStatus.paused ||
      playify.PlayifyStatus.interrupted ||
      playify.PlayifyStatus.seekingForward ||
      playify.PlayifyStatus.seekingBackward =>
        ProcessingState.ready,
      playify.PlayifyStatus.unknown => ProcessingState.loading,
    };
    if (!_processingStateSubject.isClosed && _processingStateSubject.requireValue != processingState) {
      _processingStateSubject.add(processingState);
    }

    if (isPlaying) {
      _startPositionUpdates();
    } else {
      _stopPositionUpdates();
      unawaited(_updatePosition());
    }
  }

  bool _mapStatusToPlaying(playify.PlayifyStatus status) =>
      status == playify.PlayifyStatus.playing ||
      status == playify.PlayifyStatus.seekingBackward ||
      status == playify.PlayifyStatus.seekingForward;

  void _startPositionUpdates() {
    if (_positionUpdateTimer != null) {
      return;
    }
    unawaited(_updatePosition());
    _positionUpdateTimer = Timer.periodic(_positionUpdateInterval, (_) => unawaited(_updatePosition()));
  }

  void _stopPositionUpdates() {
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = null;
  }

  Future<void> _updatePosition() async {
    if (_positionUpdateInFlight) {
      return;
    }
    _positionUpdateInFlight = true;
    final revision = _positionRevision;
    try {
      final seconds = await _playify.getPlaybackTime();
      if (!seconds.isFinite || seconds < 0) {
        return;
      }
      if (revision == _positionRevision && !_positionSubject.isClosed) {
        _positionSubject.add(Duration(milliseconds: (seconds * 1000).round()));
      }
    } catch (error) {
      debugPrint('Failed to update Apple Music playback position: $error');
    } finally {
      _positionUpdateInFlight = false;
    }
  }

  Future<void> _updateLoopMode() async {
    final revision = _loopModeRevision;
    final request = ++_loopModeRequest;
    try {
      final mode = switch (await _playify.getRepeatMode()) {
        playify.Repeat.none => LoopMode.off,
        playify.Repeat.one => LoopMode.one,
        playify.Repeat.all => LoopMode.all,
      };
      if (request == _loopModeRequest &&
          revision == _loopModeRevision &&
          !_loopModeSubject.isClosed &&
          _loopModeSubject.requireValue != mode) {
        _loopModeSubject.add(mode);
      }
    } catch (error) {
      debugPrint('Failed to update Apple Music repeat mode: $error');
    }
  }

  @override
  Future<void> dispose() async {
    _stopPositionUpdates();
    await _statusSubscription.cancel();
    await Future.wait([
      _playingSubject.close(),
      _positionSubject.close(),
      _processingStateSubject.close(),
      _loopModeSubject.close(),
    ]);
  }

  @override
  Future<PlayResult> play() async {
    try {
      await _playify.play();
      return const PlaySuccess();
    } on PlatformException catch (error, stackTrace) {
      return PlayFailure(error, stackTrace);
    }
  }

  @override
  Future<void> pause() => _playify.pause();

  @override
  Future<void> stop() => _playify.pause();

  @override
  Future<void> seek(Duration position) async {
    final revision = ++_positionRevision;
    await _playify.setPlaybackTime(position.inMilliseconds / 1000);
    if (revision == _positionRevision && !_positionSubject.isClosed) {
      _positionSubject.add(position);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> setLoopMode(LoopMode mode) async {
    final revision = ++_loopModeRevision;
    final playifyMode = switch (mode) {
      LoopMode.off => playify.Repeat.none,
      LoopMode.one => playify.Repeat.one,
      LoopMode.all => playify.Repeat.all,
    };
    await _playify.setRepeatMode(playifyMode);
    if (revision == _loopModeRevision && !_loopModeSubject.isClosed) {
      _loopModeSubject.add(mode);
    }
  }

  @override
  Future<SetSongResult> setSong(Song song) async {
    final songId = song.sourceId.toString();
    _positionRevision++;
    if (!_positionSubject.isClosed) {
      _positionSubject.add(Duration.zero);
    }
    _preparing = true;
    try {
      await _playify.setQueue(songIDs: [songId], startID: songId, startPlaying: false);
    } on PlatformException catch (error, stackTrace) {
      return SetSongFailure(error, stackTrace);
    } finally {
      _preparing = false;
    }
    if (!_processingStateSubject.isClosed) {
      _processingStateSubject.add(ProcessingState.ready);
    }
    return const SetSongSuccess();
  }

  @override
  Stream<bool> get playingStream => _playingSubject.stream;

  @override
  Stream<Duration> get positionStream => _positionSubject.stream;

  @override
  Stream<ProcessingState> get processingStateStream => _processingStateSubject.stream;

  @override
  Stream<bool> get loopingStream => _loopingStream;

  @override
  bool get playing => _playingSubject.requireValue;

  @override
  Duration get position => _positionSubject.requireValue;

  @override
  Duration get bufferedPosition => _positionSubject.requireValue;

  @override
  ProcessingState get processingState => _processingStateSubject.requireValue;

  @override
  bool get looping => _loopModeSubject.requireValue == LoopMode.one;

  @override
  double get speed => 1;
}
