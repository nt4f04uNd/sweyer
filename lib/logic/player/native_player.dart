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

/// Indicates the state of the audio player.
enum PlayerState {
  PLAYING,
  PAUSED,
  COMPLETED,
}

/// A list of all error player can throw or emit to the [NativePlayer.onError] stream.
abstract class NativePlayerErrors {
  /// Resource can't be accessed.
  /// Thrown from methods [play] and [setUri].
  static const String UNABLE_ACCESS_RESOURCE_ERROR = 'UNABLE_ACCESS_RESOURCE_ERROR';

  /// Player encountered unexpected playback error.
  static const String UNEXPECTED_ERROR = 'UNEXPECTED_ERROR';
}

/// This represents an interface to communicate with native player.
///
/// It holds methods to play, loop, pause, stop, seek the audio, and some useful
/// hooks for handlers and callbacks.
///
/// The initialization part is located at native side.
abstract class NativePlayer {
  static final MethodChannel _channel = const MethodChannel('player_channel')
    ..setMethodCallHandler(platformCallHandler);
  static final StreamController<PlayerState> _playerStateController = StreamController<PlayerState>.broadcast();
  static final StreamController<Duration> _positionController =  StreamController<Duration>.broadcast();
  static final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  static final StreamController<PlatformException> _errorController = StreamController<PlatformException>.broadcast();
  static final StreamController<bool> _loopController = StreamController<bool>.broadcast();

  static PlayerState _internalState = PlayerState.PAUSED;
  static PlayerState get state => _internalState;

  static bool _looping = false;
  static bool get looping => _looping;

  /// Will emit event to [onStateChange] stream.
  static set _state(PlayerState value) {
    _playerStateController.add(value);
    _internalState = value;
  }

  /// Will emit event to [onLoopSwitch] stream.
  static set _loopMode(bool value) {
    _loopController.add(value);
    _looping = value;
  }

  /// Stream of changes on player state.
  static Stream<PlayerState> get onStateChange => _playerStateController.stream;

  /// Stream of changes on audio position.
  ///
  /// Roughly fires every 500 milliseconds. Will continuously update the
  /// position of the playback if the status is [PlayerState.PLAYING].
  ///
  /// You can use it on a progress bar, for instance.
  static Stream<Duration> get onPosition => _positionController.stream;

  /// Stream of loop mode changes.
  static Stream<void> get onLoopSwitch => _loopController.stream;

  /// Stream of native player errors.
  ///
  /// Events are sent when an unexpected error is thrown in the native code.
  static Stream<PlatformException> get onError => _errorController.stream;

  /// Checks if player playing and if so, changes state to playing appropriately
  static Future<void> init() async {
    if (await isPlaying()) _state = PlayerState.PLAYING;
    _loopMode = await isLooping();
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
    _platformCall(call);
  }

  static void _platformCall(MethodCall call) {
    final Map<dynamic, dynamic> args = call.arguments as Map;
    final value = args['value'];
    // _log('_platformCallHandler call ${call.method} $args');
    switch (call.method) {
      case 'audio.state.set':
        switch (value) {
          case 'PLAYING':
            _state = PlayerState.PLAYING;
            break;
          case 'PAUSED':
            _state = PlayerState.PAUSED;
            break;
          case 'COMPLETED':
            _state = PlayerState.COMPLETED;
            break;
          default:
            throw ArgumentError('Wrong state');
        }
        break;
      case 'audio.onPosition':
        Duration position = Duration(milliseconds: value);
        // Make sure we never emit invalid positions.
        final state = ContentControl.state;
        if ((state.queues.current?.isNotEmpty ?? false) && 
            position <= Duration(milliseconds: state.currentSong.duration)) {
          _positionController.add(position);
        }
        break;
      case 'audio.onError':
        _state = PlayerState.PAUSED;
        _errorController.add(PlatformException(code: '0', message: value['message']));
        break;
      case 'audio.onLoopModeSwitch':
        _loopMode = value;
        break;
      default:
        throw ArgumentError('Wrong method');
    }
  }

  /// Closes all [StreamController]s.
  static Future<void> dispose() async {
    await Future.wait([
      _playerStateController.close(),
      _positionController.close(),
      _durationController.close(),
      _errorController.close()
    ]);
  }
}
