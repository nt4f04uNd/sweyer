/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*
*  Copyright (c) Luan Nico.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'package:flutter/services.dart';

import 'package:flutter_music_player/constants/constants.dart' as Constants;

typedef StreamController CreateStreamController();
typedef void TimeChangeHandler(Duration duration);
typedef void ErrorHandler(String message);
typedef void AudioPlayerStateChangeHandler(AudioPlayerState state);

/// This enum is meant to be used as a parameter of [setReleaseMode] method.
///
/// It represents the behaviour of [AudioPlayer] when an audio is finished or
/// stopped.
enum ReleaseMode {
  /// Releases all resources, just like calling [release] method.
  ///
  /// In Android, the media player is quite resource-intensive, and this will
  /// let it go. Data will be buffered again when needed (if it's a remote file,
  /// it will be downloaded again).
  /// In iOS, works just like [stop] method.
  ///
  /// This is the default behaviour.
  RELEASE,

  /// Keeps buffered data and plays again after completion, creating a loop.
  /// Notice that calling [stop] method is not enough to release the resources
  /// when this mode is being used.
  LOOP,

  /// Stops audio playback but keep all resources intact.
  /// Use this if you intend to play again later.
  STOP
}

/// Self explanatory. Indicates the state of the audio player.
enum AudioPlayerState {
  STOPPED,
  PLAYING,
  PAUSED,
  COMPLETED,
}

/// This represents a single AudioPlayer, which can play one audio at a time.
/// To play several audios at the same time, you must create several instances
/// of this class.
///
/// It holds methods to play, loop, pause, stop, seek the audio, and some useful
/// hooks for handlers and callbacks.
abstract class NativeAudioPlayer {
  static final MethodChannel _channel =
      const MethodChannel(Constants.PlayerChannel.CHANNEL_NAME)
        ..setMethodCallHandler(platformCallHandler);

  static final StreamController<AudioPlayerState> _playerStateController =
      StreamController<AudioPlayerState>.broadcast();

  static final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();

  static final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  static final StreamController<void> _completionController =
      StreamController<void>.broadcast();

  static final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  /// Enables more verbose logging.
  static bool logEnabled = false;

  static AudioPlayerState _audioPlayerState;

  static AudioPlayerState get state => _audioPlayerState;

  static set state(AudioPlayerState state) {
    _playerStateController.add(state);
    _audioPlayerState = state;
  }

  /// Stream of changes on player state.
  static Stream<AudioPlayerState> get onPlayerStateChanged =>
      _playerStateController.stream;

  /// Stream of changes on audio position.
  ///
  /// Roughly fires every 200 milliseconds. Will continuously update the
  /// position of the playback if the status is [AudioPlayerState.PLAYING].
  ///
  /// You can use it on a progress bar, for instance.
  static Stream<Duration> get onAudioPositionChanged =>
      _positionController.stream;

  /// Stream of changes on audio duration.
  ///
  /// An event is going to be sent as soon as the audio duration is available
  /// (it might take a while to download or buffer it).
  static Stream<Duration> get onDurationChanged => _durationController.stream;

  /// Stream of player completions.
  ///
  /// Events are sent every time an audio is finished, therefore no event is
  /// sent when an audio is paused or stopped.
  ///
  /// [ReleaseMode.LOOP] also sends events to this stream.
  static Stream<void> get onPlayerCompletion => _completionController.stream;

  /// Stream of player errors.
  ///
  /// Events are sent when an unexpected error is thrown in the native code.
  static Stream<String> get onPlayerError => _errorController.stream;

  static Future<int> _invokeMethod(
    String method, [
    Map<String, dynamic> arguments,
  ]) {
    arguments ??= const {};

    final Map<String, dynamic> withPlayerId = Map.of(arguments);

    return _channel
        .invokeMethod(method, withPlayerId)
        .then((result) => (result as int));
  }

  /// Plays an audio.
  ///
  /// If [isLocal] is true, [url] must be a local file system path.
  /// If [isLocal] is false, [url] must be a remote URL.
  static Future<int> play(
    String url, {
    bool isLocal = false,
    double volume = 1.0,
    // position must be null by default to be compatible with radio streams
    Duration position,
    bool respectSilence = false,
    bool stayAwake = false,
  }) async {
    isLocal ??= false;
    volume ??= 1.0;
    respectSilence ??= false;
    stayAwake ??= false;

    final int result = await _invokeMethod('play', {
      'url': url,
      'isLocal': isLocal,
      'volume': volume,
      'position': position?.inMilliseconds,
      'respectSilence': respectSilence,
      'stayAwake': stayAwake,
    });

    if (result == 1) {
      state = AudioPlayerState.PLAYING;
    }

    return result;
  }

  /// Pauses the audio that is currently playing.
  ///
  /// If you call [resume] later, the audio will resume from the point that it
  /// has been paused.
  static Future<int> pause() async {
    final int result = await _invokeMethod('pause');

    if (result == 1) {
      state = AudioPlayerState.PAUSED;
    }

    return result;
  }

  /// Stops the audio that is currently playing.
  ///
  /// The position is going to be reset and you will no longer be able to resume
  /// from the last point.
  static Future<int> stop() async {
    final int result = await _invokeMethod('stop');

    if (result == 1) {
      state = AudioPlayerState.STOPPED;
    }

    return result;
  }

  /// Resumes the audio that has been paused or stopped, just like calling
  /// [play], but without changing the parameters.
  static Future<int> resume() async {
    final int result = await _invokeMethod('resume');

    if (result == 1) {
      state = AudioPlayerState.PLAYING;
    }

    return result;
  }

  /// Releases the resources associated with this media player.
  ///
  /// The resources are going to be fetched or buffered again as soon as you
  /// call [play] or [setUrl].
  static Future<int> release() async {
    final int result = await _invokeMethod('release');

    if (result == 1) {
      state = AudioPlayerState.STOPPED;
    }

    return result;
  }

  /// Moves the cursor to the desired position.
  static Future<int> seek(Duration position) {
    _positionController.add(position);
    return _invokeMethod('seek', {'position': position.inMilliseconds});
  }

  /// Sets the volume (amplitude).
  ///
  /// 0 is mute and 1 is the max volume. The values between 0 and 1 are linearly
  /// interpolated.
  static Future<int> setVolume(double volume) {
    return _invokeMethod('setVolume', {'volume': volume});
  }

  /// Sets the release mode.
  ///
  /// Check [ReleaseMode]'s doc to understand the difference between the modes.
  static Future<int> setReleaseMode(ReleaseMode releaseMode) {
    return _invokeMethod(
      'setReleaseMode',
      {'releaseMode': releaseMode.toString()},
    );
  }

  /// Sets the URL.
  ///
  /// Unlike [play], the playback will not resume.
  ///
  /// The resources will start being fetched or buffered as soon as you call
  /// this method.
  static Future<int> setUrl(String url, {bool isLocal: false}) {
    return _invokeMethod('setUrl', {'url': url, 'isLocal': isLocal});
  }

  /// Get audio duration after setting url.
  /// Use it in conjunction with setUrl.
  ///
  /// It will be available as soon as the audio duration is available
  /// (it might take a while to download or buffer it if file is not local).
  static Future<int> getDuration() {
    return _invokeMethod('getDuration');
  }

  // Gets audio current playing position
  static Future<int> getCurrentPosition() async {
    return _invokeMethod('getCurrentPosition');
  }

  static Future<void> platformCallHandler(MethodCall call) async {
    try {
      _doHandlePlatformCall(call);
    } catch (ex) {
      _log('Unexpected error: $ex');
    }
  }

  static Future<void> _doHandlePlatformCall(MethodCall call) async {
    final Map<dynamic, dynamic> callArgs = call.arguments as Map;
    _log('_platformCallHandler call ${call.method} $callArgs');

    final value = callArgs['value'];

    switch (call.method) {
      case 'audio.onDuration':
        Duration newDuration = Duration(milliseconds: value);
        _durationController.add(newDuration);
        break;
      case 'audio.onCurrentPosition':
        Duration newDuration = Duration(milliseconds: value);
        _positionController.add(newDuration);
        break;
      case 'audio.onComplete':
        state = AudioPlayerState.COMPLETED;
        _completionController.add(null);
        break;
      case 'audio.onError':
        state = AudioPlayerState.STOPPED;
        _errorController.add(value);
        break;
      case 'audio.state.set':
        switch (value) {
          case 'PLAYING':
            state = AudioPlayerState.PLAYING;
            break;
          case 'PAUSED':
            state = AudioPlayerState.PAUSED;
            break;
          case 'STOPPED':
            state = AudioPlayerState.STOPPED;
        }
        break;
      default:
        _log('Unknown method ${call.method} ');
    }
  }

  static void _log(String param) {
    if (logEnabled) {
      print(param);
    }
  }

  /// Closes all [StreamController]s.
  ///
  /// You must call this method when your [AudioPlayer] instance is not going to
  /// be used anymore.
  static Future<void> dispose() async {
    List<Future> futures = [];

    if (!_playerStateController.isClosed)
      futures.add(_playerStateController.close());
    if (!_positionController.isClosed) futures.add(_positionController.close());
    if (!_durationController.isClosed) futures.add(_durationController.close());
    if (!_completionController.isClosed)
      futures.add(_completionController.close());
    if (!_errorController.isClosed) futures.add(_errorController.close());

    await Future.wait(futures);
  }
}
