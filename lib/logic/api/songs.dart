/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/services.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'api.dart';

abstract class SongsHandler {
  static MethodChannel _songsChannel =
      const MethodChannel(Constants.SongsChannel.CHANNEL_NAME);

  static MethodChannelHandler _onGetSongHandler;

  /// Sets handler for [Constants.SongsChannel.METHOD_SEND_SONGS] native channel invocations
  static setOnGetSongsHandler(MethodChannelHandler handler) {
    _onGetSongHandler = handler;
  }

  /// Starts to listen to a native method calls
  static void init() {
    _songsChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == Constants.SongsChannel.METHOD_SEND_SONGS) {
        // Getting the fetched songs
        if (_onGetSongHandler != null) {
          _onGetSongHandler(call);
        }
      }
    });
  }

  /// Invocation of this method will trigger native code to start the process of fetching songs
  static Future<void> retrieveSongs() {
    return _songsChannel
        .invokeMethod<String>(Constants.SongsChannel.METHOD_RETRIEVE_SONGS);
  }

  /// Deletes the song by id
  static Future<void> deleteSongs(Set<String> songDataSet) {
    return _songsChannel.invokeMethod<String>(
      Constants.SongsChannel.METHOD_DELETE_SONGS,
      {"songDataList": songDataSet.toList()},
    );
  }
}
