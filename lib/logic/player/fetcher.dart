/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:convert';

import 'package:sweyer/utils/async.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/api.dart' as API;

import 'song.dart';

class SongsFetcher {
  // TODO: rewrite with cancelable operationh
  AsyncOperationsQueue _fetchQueue = AsyncOperationsQueue();

  /// A temporary container for found songs
  List<Song> _foundSongsTemp;

  SongsFetcher() {
    API.SongsHandler.setOnGetSongsHandler((MethodCall call) {
      // List to songs that come from channel
      // NOTE: cast method is must be here, [as] crashes code execution
      _getSongsFromChannel(call.arguments.cast<String>());
      return;
    });
  }

  /// Fetches songs on user device
  ///
  /// If gets invoked before previous fetch operation ended, then call will be added to a queue an completed after current operation ends
  Future<List<Song>> fetchSongs() async {
    await _fetchQueue.add(() {
      API.SongsHandler.retrieveSongs();
    });
    // Save it to local var to clear `_foundSongsTemp`
    List<Song> retSongs = _foundSongsTemp;
    _foundSongsTemp = null;
    return retSongs;
  }

  /// Method that is used to get songs from method channel
  ///
  /// ATTENTION: IF YOU USE `call.arguments` WITH THIS FUNCTION, TYPE CAST IT THROUGH `List<T> List.cast<T>()`, because `call.arguments` [as] type cast will crash closure execution
  void _getSongsFromChannel(List<String> songsJsons) {
    List<Song> foundSongs = [];
    for (String songJson in songsJsons) {
      foundSongs.add(Song.fromJson(jsonDecode(songJson)));
    }
    // Save songs to temp container
    _foundSongsTemp = foundSongs;
    // Say to [fetchSongs] that operation ended and it can continue its execution
    _fetchQueue.finishCurrent();
  }
}
