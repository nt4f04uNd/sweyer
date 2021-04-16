/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';

abstract class ContentChannel {
  static const MethodChannel _channel = MethodChannel('content_channel');

  /// Tries to tell system to recreate album art by [albumId].
  ///
  /// Sometimes `MediaStore` tells that there's an albumart for some song, but the actual file
  /// by some path doesn't exist. Supposedly, what happens is that Android detects reads on this
  /// entry from something like `InputStream` in Java and regenerates albumthumbs if they do not exist
  /// (because this is just a caches that system tends to clear out if it thinks it should),
  /// but (yet again, supposedly) this is not the case when Flutter accesses this file. System cannot
  /// detect it and does not recreate the thumb, so we do this instead.
  ///
  /// See https://stackoverflow.com/questions/18606007/android-image-files-deleted-from-com-android-providers-media-albumthumbs-on-rebo
  static Future<void> fixAlbumArt(int albumId) async {
    return _channel.invokeMethod<void>(
      'fixAlbumArt',
      {'id': albumId},
    );
  }

  static Future<List<Song>> retrieveSongs() async {
    final maps = await _channel.invokeListMethod<Map>('retrieveSongs');
    final List<Song> songs = [];
    for (Map map in maps) {
      map = map.cast<String, dynamic>();
      songs.add(Song.fromMap(map));
    }
    return songs;
  }

  static Future<Map<int, Album>> retrieveAlbums() async {
    final maps = await _channel.invokeListMethod<Map>('retrieveAlbums');
    final Map<int, Album> albums = {};
    for (Map map in maps) {
      map = map.cast<String, dynamic>();
      albums[map['id'] as int] = Album.fromJson(map);
    }
    return albums;
  }

  // static Future<List<Map<String, dynamic>>> retrievePlaylists() async {
  //   return _channel.invokeListMethod<Map<String, dynamic>>('retrievePlaylists');
  // }

  // static Future<List<Map<String, dynamic>>> retrieveArtists() async {
  //   return _channel.invokeListMethod<Map<String, dynamic>>('retrieveArtists');
  // }

  static Future<bool> deleteSongs(Set<Song> songSet) async {
    return _channel.invokeMethod<bool>(
      'deleteSongs',
      {'songs': jsonEncode(songSet.map((song) => song.toMap()).toList())},
    );
  }
}
