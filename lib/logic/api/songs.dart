/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/services.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'api.dart';

abstract class ContentHandler {
  static MethodChannel _contentChannel =
      const MethodChannel(Constants.ContentChannel.CHANNEL_NAME);

  static MethodChannelHandler _onGetSongHandler;

  /// Sets handler for [Constants.SongsChannel.METHOD_SEND_SONGS] native channel invocations
  static setOnGetSongsHandler(MethodChannelHandler handler) {
    _onGetSongHandler = handler;
  }

  /// Starts to listen to a native method calls
  static void init() {
    _contentChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == Constants.ContentChannel.METHOD_SEND_SONGS) {
        // Getting the fetched songs
        if (_onGetSongHandler != null) {
          _onGetSongHandler(call);
        }
      }
    });
  }

  /// Invocation of this method will trigger native code to start the process of fetching songs
  static Future<List<String>> retrieveSongs() async {
    return _contentChannel
        .invokeListMethod<String>(Constants.ContentChannel.METHOD_RETRIEVE_SONGS);
  }
  /// Invocation of this method will trigger native code to start the process of fetching songs
  static Future<List<String>> retrieveAlbums()async {
            return _contentChannel
        .invokeListMethod<String>(Constants.ContentChannel.METHOD_RETRIEVE_ALBUMS);
  }

  /// Deletes the song by id
  static Future<void> deleteSongs(Set<String> songDataSet)async {
    return _contentChannel.invokeMethod(
      Constants.ContentChannel.METHOD_DELETE_SONGS,
      {"songDataList": songDataSet.toList()},
    );
  }
}
