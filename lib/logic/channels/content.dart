/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';

abstract class ContentChannel {
  static MethodChannel _channel = const MethodChannel('content_channel');

  static Future<List<String>> retrieveSongs() async {
    return _channel.invokeListMethod<String>('retrieveSongs');
  }

  static Future<List<String>> retrieveAlbums() async {
    return _channel.invokeListMethod<String>('retrieveAlbums');
  }

  static Future<List<String>> retrievePlaylists() async {
    return _channel.invokeListMethod<String>('retrievePlaylists');
  }

  static Future<List<String>> retrieveArtists() async {
    return _channel.invokeListMethod<String>('retrieveArtists');
  }

  static Future<bool> deleteSongs(Set<Song> songSet) async {
    return _channel.invokeMethod<bool>(
      'deleteSongs',
      {'songs': jsonEncode(songSet.map((el) => el.toJson()).toList())},
    );
  }
}
