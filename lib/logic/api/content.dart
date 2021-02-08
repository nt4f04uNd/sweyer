/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';

abstract class ContentHandler {
  static MethodChannel _contentChannel = const MethodChannel('contentChannel');

  static Future<List<String>> retrieveSongs() async {
    return _contentChannel.invokeListMethod<String>('retrieveSongs');
  }

  static Future<List<String>> retrieveAlbums() async {
    return _contentChannel.invokeListMethod<String>('retrieveAlbums');
  }

  static Future<List<String>> retrievePlaylists() async {
    return _contentChannel.invokeListMethod<String>('retrievePlaylists');
  }

  static Future<List<String>> retrieveArtists() async {
    return _contentChannel.invokeListMethod<String>('retrieveArtists');
  }

  static Future<bool> deleteSongs(Set<Song> songSet) async {
    return _contentChannel.invokeMethod<bool>(
      'deleteSongs',
      {'songs': jsonEncode(songSet.map((el) => el.toJson()).toList())},
    );
  }
}
