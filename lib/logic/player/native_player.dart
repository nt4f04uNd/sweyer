/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*
*  Copyright (c) Luan Nico.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';

/// Self explanatory. Indicates the state of the audio player.
enum MusicPlayerState {
  PLAYING,
  PAUSED,
  COMPLETED,
}

/// This represents an interface to communicate with native player methods
///
/// It holds methods to play, loop, pause, stop, seek the audio, and some useful
/// hooks for handlers and callbacks.
///
/// The initialization part is located at native side.
abstract class NativeAudioPlayer {
  static final MethodChannel _channel = const MethodChannel('playerChannel')
    ..setMethodCallHandler(platformCallHandler);

  static final StreamController<MusicPlayerState> _playerStateController =
      StreamController<MusicPlayerState>.broadcast();

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

  static MusicPlayerState _internalState = MusicPlayerState.PAUSED;
  static MusicPlayerState get state => _internalState;

  static bool _looping = false;
  static bool get looping => _looping;

  /// It is observable, that means on every set we emit event to [onStateChange] stream
  static set state(MusicPlayerState value) {
    _playerStateController.add(value);
    _internalState = value;
  }

  /// It is observable, that means on every set we emit event to [onLoopSwitch] stream
  static set loopMode(bool value) {
    _loopController.add(value);
    _looping = value;
  }

  /// Stream of changes on player state.
  static Stream<MusicPlayerState> get onStateChange =>
      _playerStateController.stream;

  /// Stream of changes on audio position.
  ///
  /// Roughly fires every 500 milliseconds. Will continuously update the
  /// position of the playback if the status is [MusicPlayerState.PLAYING].
  ///
  /// You can use it on a progress bar, for instance.
  static Stream<Duration> get onPosition => _positionController.stream;

  /// Stream of player completions.
  ///
  /// Events are sent every time an audio is finished, therefore no event is
  /// sent when an audio is paused or stopped.
  ///
  /// If player is looping the events to this stream are not emitted.
  static Stream<void> get onCompletion => _completionController.stream;

  /// Stream of loop mode changes.
  static Stream<void> get onLoopSwitch => _loopController.stream;

  /// Stream of native player errors.
  ///
  /// Events are sent when an unexpected error is thrown in the native code.
  static Stream<PlatformException> get onError => _errorController.stream;

  /// Checks if player playing and if so, changes state to playing appropriately
  static Future<void> init() async {
    if (await isPlaying()) state = MusicPlayerState.PLAYING;
    loopMode = await isLooping();
  }

  static Future<void> clearIdMap() {
    return _channel.invokeMethod('clearIdMap');
  }

  /// Plays a song.
  ///
  /// The [duplicate] indicates that the current song is already present in the current queue and its id should be mapped.
  ///
  /// Throws:
  /// * `Unsupported value: java.lang.IllegalStateException` message thrown when [play] gets called in wrong state
  /// * `Unsupported value: java.lang.RuntimeException: Unable to access resource` message thrown when resource can't be played
  static Future<void> play(Song song, bool duplicate) async {
    return _channel.invokeMethod('play', {
      'song': jsonEncode(song.toJson()),
      'duplicate': duplicate,
    });
  }

  /// Silently prepares the resourses for the given [songId], from wich
  /// the song source path is constructed.
  ///
  /// The [duplicate] indicates that the current song is already present in the current queue and its id should be mapped.
  ///
  /// The resources will start being fetched or buffered as soon as you call
  /// this method.
  static Future<void> setUri(Song song, bool duplicate) async {
    return _channel.invokeMethod('setUri', {
      'song': jsonEncode(song.toJson()),
      'duplicate': duplicate,
    });
  }

  /// Resumes the playback.
  static Future<void> resume() async {
    return _channel.invokeMethod('resume');
  }

  /// Pauses the playback.
  static Future<void> pause() async {
    return _channel.invokeMethod('pause');
  }

  /// Releases the resources associated with this media player.
  static Future<void> release() async {
    return _channel.invokeMethod('release');
  }

  /// Moves the cursor to the desired position.
  static Future<void> seek(Duration position) async {
    _positionController.add(position);
    return _channel.invokeMethod('seek', {'position': position.inMilliseconds});
  }

  /// Sets the [volume]. Has to be in range from `0.0` to `1.0`.
  static Future<void> setVolume(double volume) async {
    return _channel.invokeMethod('setVolume', {'volume': volume});
  }

  /// Sets the looping mode.
  static Future<void> setLooping(bool looping) async {
    return _channel.invokeMethod('setLooping', {'looping': looping});
  }

  /// Checks is the actual native player is actually playing.
  /// Needed on the app start, to check if service is running and playing music.
  static Future<bool> isPlaying() async {
    return _channel.invokeMethod('isPlaying');
  }

  /// Checks is the player is looping.
  static Future<bool> isLooping() async {
    return _channel.invokeMethod('isLooping');
  }

  // Gets the current player position.
  static Future<int> getPosition() async {
    return _channel.invokeMethod('getPosition');
  }

  /// Get audio duration after setting uri.
  ///
  /// It will be available as soon as the audio duration is available
  /// (it might take a while to download or buffer it if file is not local).
  static Future<int> getDuration() async {
    return _channel.invokeMethod('getDuration');
  }

  static Future<void> platformCallHandler(MethodCall call) async {
    try {
      _platformCall(call);
    } catch (ex) {
      _log('Unexpected error: $ex');
    }
  }

  static void _platformCall(MethodCall call) {
    final Map<dynamic, dynamic> callArgs = call.arguments as Map;
    _log('_platformCallHandler call ${call.method} $callArgs');

    final value = callArgs['value'];

    switch (call.method) {
      case 'audio.state.set':
        {
          switch (value) {
            case 'PLAYING':
              state = MusicPlayerState.PLAYING;
              break;
            case 'PAUSED':
              state = MusicPlayerState.PAUSED;
              break;
            case 'COMPLETED':
              state = MusicPlayerState.COMPLETED;
              _completionController.add(null);
          }
          break;
        }
      case 'audio.onPosition':
        {
          Duration position = Duration(milliseconds: value);
          if ((ContentControl.state.queues.current?.isNotEmpty ?? false) &&
              position <=
                  Duration(
                    milliseconds: ContentControl.state.currentSong.duration,
                  )) {
            _positionController.add(position);
          }
          break;
        }
      case 'audio.onError':
        {
          state = MusicPlayerState.PAUSED;
          _errorController
              .add(PlatformException(code: '0', message: value['message']));
          break;
        }
      case 'audio.onLoopModeSwitch':
        {
          loopMode = value;
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
  static Future<void> dispose() async {
    await Future.wait([
      _playerStateController.close(),
      _positionController.close(),
      _durationController.close(),
      _completionController.close(),
      _errorController.close()
    ]);
  }
}
