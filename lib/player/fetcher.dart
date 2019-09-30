import 'dart:async';
import 'dart:convert';

import 'package:app/player/serialization.dart';
import 'package:app/player/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/constants/constants.dart' as Constants;

class SongsFetcher {
  /// Channel for handling audio focus
  MethodChannel _songsChannel =
      const MethodChannel(Constants.SongsChannel.channelName);

  /// An instance of `AsyncOperation` to track if tracks are fetching
  AsyncOperation fetchingOperation = AsyncOperation();

  /// An object to serialize songs
  SongsSerialization serializer = SongsSerialization();

  /// A temporary container for found songs
  List<Song> _foundSongsTemp;

  SongsFetcher() {
    _songsChannel.setMethodCallHandler((MethodCall call) async {
      debugPrint(call.method.toString());
      if (call.method == Constants.SongsChannel.methodSendSongs) {
        // NOTE: cast method is must be here, `as` crashes code execution
        _getSongsFromChannel(call.arguments.cast<String>());
      }
    });
  }

  /// Fetches songs on user device
  Future<List<Song>> fetchSongs() async {
    await _songsChannel
        .invokeMethod<String>(Constants.SongsChannel.methodRetrieveSongs);
    await fetchingOperation.doOperation();
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
    serializer.saveJson(foundSongs);
    // Say to `fetchSongs` that operation ended and it can continue its execution
    fetchingOperation.finishOperation();

    // Emit event to track change stream
    // trackListChangeStreamController.emitEvent();
  }
}


/// TODO: improve this class
class AsyncOperation {
  Completer _completer = Completer();

  // Send future object back to client.
  Future<void> doOperation() {
    return _completer.future;
  }

  // Something calls this when the value is ready.
  void finishOperation() {
    _completer.complete();
    _completer = Completer(); // Update completer
  }

  // If something goes wrong, call this.
  void errorHappened(error) {
    _completer.completeError(error);
  }
}
