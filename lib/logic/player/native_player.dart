/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*
*  Copyright (c) Luan Nico.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';

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
  PLAYING,
  PAUSED,
  STOPPED,
  COMPLETED,
}

/// This represents an interface to communicate with native player methods
///
/// It holds methods to play, loop, pause, stop, seek the audio, and some useful
/// hooks for handlers and callbacks.
///
/// NOTE that initialization part is located at native side
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

  static final StreamController<PlatformException> _errorController =
      StreamController<PlatformException>.broadcast();

  static final StreamController<bool> _loopController =
      StreamController<bool>.broadcast();

  /// Enables more verbose logging.
  static bool logEnabled = false;

  static AudioPlayerState _internalState = AudioPlayerState.PAUSED;
  static bool _internalLoopMode = false;

  static AudioPlayerState get state => _internalState;
  static bool get loopMode => _internalLoopMode;

  /// It is observable, that means on every set we emit event to `onPlayerStateChanged` stream
  static set state(AudioPlayerState value) {
    _playerStateController.add(value);
    _internalState = value;
  }

  /// It is observable, that means on every set we emit event to `onPlayerStateChanged` stream
  static set loopMode(bool value) {
    _loopController.add(value);
    _internalLoopMode = value;
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

  /// Stream of loop mode changes.
  static Stream<void> get onLoopSwitch => _loopController.stream;

  /// Stream of player errors.
  ///
  /// Events are sent when an unexpected error is thrown in the native code.
  static Stream<PlatformException> get onPlayerError => _errorController.stream;

  /// Checks if player playing and if so, changes state to playing appropriately
  /// Also sets release mode to be `ReleaseMode.STOP`
  static Future<void> init() async {
    if (await isPlaying()) state = AudioPlayerState.PLAYING;
    loopMode = await isLooping();
  }

  /// Plays an audio.
  ///
  /// If [isLocal] is true, [url] must be a local file system path.
  /// If [isLocal] is false, [url] must be a remote URL.
  ///
  /// Throws `Unsupported value: java.lang.IllegalStateException` message thrown when `play` gets called in wrong state
  ///
  /// Throws `Unsupported value: java.lang.RuntimeException: Unable to access resource` message thrown when resource can't be played
  static Future<void> play(
    Song song, {
    double volume = 1.0,
    // position must be null by default to be compatible with radio streams
    Duration position,
    bool stayAwake = true,
  }) async {
    return _channel.invokeMethod('play', {
      'song': song.toJson(),
      'volume': volume,
      'position': position?.inMilliseconds,
      'stayAwake': stayAwake,
    });
  }

  /// Pauses the audio that is currently playing.
  ///
  /// If you call [resume] later, the audio will resume from the point that it
  /// has been paused.
  static Future<void> pause() async {
    return _channel.invokeMethod('pause');
  }

  /// Stops the audio that is currently playing.
  ///
  /// The position is going to be reset and you will no longer be able to resume
  /// from the last point.
  static Future<void> stop() async {
    return _channel.invokeMethod('stop');
  }

  /// Resumes the audio that has been paused or stopped, just like calling
  /// [play], but without changing the parameters.
  static Future<void> resume() async {
    return _channel.invokeMethod('resume');
  }

  /// Releases the resources associated with this media player.
  ///
  /// The resources are going to be fetched or buffered again as soon as you
  /// call [play] or [setUri].
  static Future<void> release() async {
    return _channel.invokeMethod('release');
  }

  /// Moves the cursor to the desired position.
  static Future<void> seek(Duration position) async {
    _positionController.add(position);
    return _channel.invokeMethod('seek', {'position': position.inMilliseconds});
  }

  /// Sets the volume (amplitude).
  ///
  /// 0 is mute and 1 is the max volume. The values between 0 and 1 are linearly
  /// interpolated.
  static Future<void> setVolume(double volume) async {
    return _channel.invokeMethod('setVolume', {'volume': volume});
  }

  /// Sets the release mode.
  ///
  /// Check [ReleaseMode]'s doc to understand the difference between the modes.
  static Future<void> setReleaseMode(ReleaseMode releaseMode) async {
    return _channel.invokeMethod(
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
  /// 
  /// Uses id to get song path
  static Future<void> setUri(int songId) async {
    return _channel.invokeMethod('setUri', {'songId': songId});
  }

  /// Checks is the actual player is playing
  /// Needed on the app start, to check if service is running and playing music
  static Future<bool> isPlaying() async {
    return _channel.invokeMethod('isPlaying');
  }

  /// Checks is the actual player has release mode [ReleaseMode.LOOP]
  static Future<bool> isLooping() async {
    return _channel.invokeMethod('isLooping');
  }

  /// Switches loop mode
  static Future<void> switchLoopMode() async {
    return _channel.invokeMethod('switchLoopMode');
  }

  /// Get audio duration after setting url.
  /// Use it in conjunction with setUrl.
  ///
  /// It will be available as soon as the audio duration is available
  /// (it might take a while to download or buffer it if file is not local).
  static Future<int> getDuration() async {
    return _channel.invokeMethod('getDuration');
  }

  // Gets audio current playing position
  static Future<int> getCurrentPosition() async {
    return _channel.invokeMethod('getCurrentPosition');
  }

  static Future<void> platformCallHandler(MethodCall call) async {
    try {
      _doHandlePlatformCall(call);
    } catch (ex) {
      _log('Unexpected error: $ex');
    }
  }

  static void _doHandlePlatformCall(MethodCall call) {
    final Map<dynamic, dynamic> callArgs = call.arguments as Map;
    _log('_platformCallHandler call ${call.method} $callArgs');

    final value = callArgs['value'];

    switch (call.method) {
      case 'audio.onDuration':
        {
          Duration newDuration = Duration(milliseconds: value);
          _durationController.add(newDuration);
          break;
        }
      case 'audio.onCurrentPosition':
        {
          Duration newDuration = Duration(milliseconds: value);
          _positionController.add(newDuration);
          break;
        }
      case 'audio.onComplete':
        {
          state = AudioPlayerState.COMPLETED;
          _completionController.add(null);
          break;
        }
      case 'audio.onError':
        {
          state = AudioPlayerState.STOPPED;
          // TODO : add exception various codes
          _errorController
              .add(PlatformException(code: "0", message: value["message"]));
          break;
        }
      case 'audio.onLoopModeSwitch':
        {
          loopMode = value;
          break;
        }
      case 'audio.state.set':
        {
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
        }
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
    await Future.wait([
      _playerStateController.close(),
      _positionController.close(),
      _durationController.close(),
      _completionController.close(),
      _errorController.close()
    ]);
  }


  static void emitDurationChange(int value){
    Duration newDuration = Duration(milliseconds: value);
          _durationController.add(newDuration);
  }
}
