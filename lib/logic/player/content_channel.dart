/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

// @dart = 2.12 

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Class to cancel the [ContentChannel.loadAlbumArt].
class CancellationSignal {
  CancellationSignal() : _id = _uuid.v4();
  final String _id;

  /// Cancel loading of an album art.
  Future<void> cancel() {
    return ContentChannel._channel.invokeMethod<void>(
      'cancelAlbumArtLoading',
      {'id': _id}
    );
  } 
}

/// TODO: better docs
abstract class ContentChannel {
  static const MethodChannel _channel = MethodChannel('content_channel');

  /// Loads album art on Android Q (SDK 29) and above.
  /// Calling this on versions below with throw.
  static Future<Uint8List> loadAlbumArt({ required String uri, required Size size, required CancellationSignal signal }) async {
    final res = await _channel.invokeMethod<Uint8List>(
      'loadAlbumArt',
      {
        'id': signal._id,
        'uri': uri, 
        'width': size.width.toInt(),
        'height': size.height.toInt(),
      },
    );
    return res!;
  }

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
    return maps!.map((el) => Song.fromMap(el)).toList();
  }

  static Future<Map<int, Album>> retrieveAlbums() async {
    final maps = await _channel.invokeListMethod<Map>('retrieveAlbums');
    final Map<int, Album> albums = {};
    for (final map in maps!) {
      albums[map['id'] as int] = Album.fromMap(map);
    }
    return albums;
  }

  static Future<List<Playlist>> retrievePlaylists() async {
    final maps = await _channel.invokeListMethod<Map>('retrievePlaylists');
    return maps!.map((el) => Playlist.fromMap(el)).toList();
  }

  static Future<List<Artist>> retrieveArtists() async {
    final maps = await _channel.invokeListMethod<Map>('retrieveArtists');
    return maps!.map((el) => Artist.fromMap(el)).toList();
  }

  static Future<List<Genre>> retrieveGenres() async {
    final maps = await _channel.invokeListMethod<Map>('retrieveGenres');
    return maps!.map((el) => Genre.fromMap(el)).toList();
  }

  static Future<bool> deleteSongs(Set<Song> songSet) async {
    final res = await _channel.invokeMethod<bool>(
      'deleteSongs',
      {'songs': songSet.map((song) => song.toMap()).toList()},
    );
    return res!;
  }

  static Future<void> createPlaylist(String name) async {
    return _channel.invokeMethod<void>('createPlaylist', {'name': name});
  }

  static Future<void> removePlaylist(Playlist playlist) async {
    return _channel.invokeMethod<void>('removePlaylist', {'id': playlist.id});
  }

  static Future<void> insertSongsInPlaylist({ required int index, required List<Song> songs, required Playlist playlist }) async {
    assert(songs.isNotEmpty);
    assert(index >= 1 && index <= playlist.songIds.length);
    return _channel.invokeMethod<void>(
      'insertSongsInPlaylist',
      {
        'id': playlist.id,
        'index': index,
        'songIds': songs.map((el) => el.id).toList(),
      },
    );
  }

  /// Moves song in playlist, returned value indicates whether the operation was successful.
  static Future<bool> moveSongInPlaylist({ required Playlist playlist, required int from, required int to }) async {
    assert(from >= 0);
    assert(to >= 0);
    assert(from != to);
    final res = await _channel.invokeMethod<bool>(
      'moveSongInPlaylist',
      {
        'id': playlist.id,
        'from': from,
        'to': to,
      },
    );
    return res!;
  }

  static Future<void> removeSongsFromPlaylist({ required List<Song> songs, required Playlist playlist }) async {
    assert(songs.isNotEmpty);
    return _channel.invokeMethod<void>(
      'removeSongsFromPlaylist',
      {
        'id': playlist.id,
        'songIds': songs.map((el) => el.id).toList(),
      },
    );
  }

  /// Checks if open intent is view (user tried to open file with app).
  static Future<bool> isIntentActionView() async {
    final res = await _channel.invokeMethod<bool>('isIntentActionView');
    return res!;
  }
}
