/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:convert';

import 'package:sweyer/utils/async.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/constants.dart' as Constants;

import 'song.dart';

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
      if (call.method == Constants.SongsChannel.SONGS_METHOD_SEND_SONGS) {
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
          .invokeMethod<String>(Constants.SongsChannel.SONGS_METHOD_RETRIEVE_SONGS);
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
