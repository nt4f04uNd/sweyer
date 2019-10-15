import 'dart:async';
import 'dart:convert';

import 'package:app/player/song.dart';
import 'package:flutter/services.dart';
import 'package:app/constants/constants.dart' as Constants;

class SongsFetcher {
  /// Channel for handling audio focus
  MethodChannel _songsChannel =
      const MethodChannel(Constants.SongsChannel.channelName);

  // /// An instance of `AsyncOperation` to track if tracks are fetching
  // AsyncOperation fetchingOperation = AsyncOperation();
  OperationsQueue _fetchQueue = OperationsQueue();

  /// A temporary container for found songs
  List<Song> _foundSongsTemp;

  /// Function from `SongsSerializer` to save songs after fetching
  final Function saveJson;

  SongsFetcher(this.saveJson) {
    _songsChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == Constants.SongsChannel.methodSendSongs) {
        // List to songs that come from channel
        // NOTE: cast method is must be here, `as` crashes code execution
        _getSongsFromChannel(call.arguments.cast<String>());
      }
    });
  }

  /// Fetches songs on user device
  ///
  /// If gets invoked before previous fetch operation ended, then call will be added to a queue an completed after current operation ends
  Future<List<Song>> fetchSongs() async {
    await _fetchQueue.add(() {
      _songsChannel
          .invokeMethod<String>(Constants.SongsChannel.methodRetrieveSongs);
    });
    // Save it to local var to clear `_foundSongsTemp`
    List<Song> retSongs = _foundSongsTemp;
    _foundSongsTemp = null;
    return retSongs;
  }

  /// Method that is used to get songs from method channel
  ///
  /// ATTENTION: IF YOU USE `call.arguments` WITH THIS FUNCTION, TYPE CAST IT THROUGH `List<T> List.cast<T>()`, because `call.arguments` `as` type cast will crash closure execution
  void _getSongsFromChannel(List<String> songsJsons) {
    List<Song> foundSongs = [];
    for (String songJson in songsJsons) {
      foundSongs.add(Song.fromJson(jsonDecode(songJson)));
    }
    // Save songs to temp container
    _foundSongsTemp = foundSongs;
    // Serialize found songs
    saveJson(foundSongs);
    // Say to `fetchSongs` that operation ended and it can continue its execution
    _fetchQueue.finishCurrent();
  }
}

/// A class that represents some async operation
///
/// Can add to queue calls if it is still in work
class AsyncOperation {
  final Completer _completer = Completer();
  final Function _callback;
  AsyncOperation(Function callback) : this._callback = callback;

  /// Returns status of the operation
  ///
  /// Returns true if operation is in work
  bool get isWorking => !_completer.isCompleted;

  // Returns future to wait before operation completion
  Future<void> wait() {
    return _completer.future;
  }

  /// Calls `_callback`
  void start() {
    _callback();
  }

  /// End operation
  void finish() {
    _completer.complete();
  }

  /// Fill completer future that is returned from `wait` method with error
  void errorFinish(error) {
    _completer.completeError(error);
  }
}

/// A queue of `AsyncOperation`s
///
/// Adds new `AsyncOperation` to the end
///
/// Completes from start of list to end
class OperationsQueue {
  List<AsyncOperation> _queue = [];

  /// first element of `_queue` is considered to be current
  AsyncOperation get _currentOperation => _queue.first;

  /// Adds a function to queue
  ///
  /// If `_queue` length equals 1 calls `_completeQueue` to start queue completion
  ///
  /// @return `AsyncOperation.wait` future
  Future<void> add(Function callback) {
    _queue.add(AsyncOperation(callback));
    if (_queue.length == 1) _completeQueue();
    return _queue[_queue.length - 1]
        .wait(); // Return future to wait before operation completion
  }

  /// Finishes currentOperation
  void finishCurrent() {
    _currentOperation.finish();
  }

  /// Completes all operations in `_queue` from start to end
  Future<void> _completeQueue() async {
    while (_queue.isNotEmpty) {
      _currentOperation.start();
      await _currentOperation.wait(); // Wait before `finishCurrent` call
      _queue.removeAt(0); // Remove completed operation
    }
  }
}
