/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:typed_data';

import 'package:equatable/equatable.dart';
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

class ContentChannelException extends Enum with EquatableMixin {
  const ContentChannelException._(String value, [this._exception]) : super(value);

  PlatformException get exception => _exception!;
  // TODO: https://github.com/dart-lang/linter/issues/2718
  // ignore: use_late_for_private_fields_and_variables
  final PlatformException? _exception;

  @override
  List<Object?> get props => [value];

  /// Generic error.
  static const unexpected = ContentChannelException._('UNEXPECTED_ERROR');

  /// On Android 30 requets like `MediaStore.createDeletionRequest` require
  /// calling `startIntentSenderForResult`, which might throw this exception.
  static const intentSender = ContentChannelException._('INTENT_SENDER_ERROR');

  static const io = ContentChannelException._('IO_ERROR');

  /// API is unavailable on current SDK level.
  static const sdk = ContentChannelException._('SDK_ERROR');

  /// Operation cannot be performed because there's no such playlist
  static const playlistNotExists = ContentChannelException._('PLAYLIST_NOT_EXISTS_ERROR');

  static ContentChannelException _throw(PlatformException exception, List<ContentChannelException> expectedExceptions) {
    final toThrow = ContentChannelException._(exception.code, exception);
    assert(toThrow == unexpected || expectedExceptions.contains(toThrow));
    return toThrow;
  }

  @override
  String toString() => _exception.toString();
}

/// Communication bridge with the platform for all content-related methods.
/// 
/// Methods can thow various [ContentChannelException]s.
abstract class ContentChannel {
  static const MethodChannel _channel = MethodChannel('content_channel');

  /// Loads album art on Android Q (SDK 29) and above.
  /// Calling this on versions below with throw.
  ///
  /// Can return `null` in case operation is cancelled before fetching if finished.
  ///
  /// Throws:
  ///  * [ContentChannelException.io] when art fails to load
  ///  * [ContentChannelException.sdk] when it's called below Android 29
  static Future<Uint8List?> loadAlbumArt({ required String uri, required Size size, required CancellationSignal signal }) async {
    try {
      return await _channel.invokeMethod<Uint8List>(
        'loadAlbumArt',
        {
          'id': signal._id,
          'uri': uri, 
          'width': size.width.toInt(),
          'height': size.height.toInt(),
        },
      );
    } on PlatformException catch(ex) {
      throw ContentChannelException._throw(ex, const [ContentChannelException.io, ContentChannelException.sdk]);
    }
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

  /// Sets songs' favorite flag to [value].
  ///
  /// The returned value indicates the success of the operation.
  ///
  /// Throws:
  ///  * [ContentChannelException.sdk] when it's called below Android 30
  ///  * [ContentChannelException.intentSender]
  static Future<bool> setSongsFavorite(Set<Song> songs, bool value) async {
    try {
      final res = await _channel.invokeMethod<bool>(
        'setSongsFavorite',
        {
          'songs': songs.map((song) => song.toMap()).toList(),
          'value': value,
        },
      );
      return res!;
    } on PlatformException catch(ex) {
      throw ContentChannelException._throw(ex, const [ContentChannelException.sdk, ContentChannelException.intentSender]);
    }
  }

  /// Deletes a set of songs.
  ///
  /// The returned value indicates the success of the operation.
  ///
  /// Throws:
  ///  * [ContentChannelException.intentSender]
  static Future<bool> deleteSongs(Set<Song> songs) async {
    try {
      final res = await _channel.invokeMethod<bool>(
        'deleteSongs',
        {'songs': songs.map((song) => song.toMap()).toList()},
      );
      return res!;
    } on PlatformException catch(ex) {
      throw ContentChannelException._throw(ex, const [ContentChannelException.intentSender]);
    }
  }

  static Future<void> createPlaylist(String name) async {
    try {
      return await _channel.invokeMethod<void>('createPlaylist', {'name': name});
    } on PlatformException catch(ex) {
      throw ContentChannelException._throw(ex, const []);
    }
  }

  /// Throws:
  ///  * [ContentChannelException.playlistNotExists] when playlist doesn't exist.
  static Future<void> renamePlaylist(Playlist playlist, String name) async {
    try {
      return await _channel.invokeMethod<void>(
        'renamePlaylist',
        {
          'id': playlist.id,
          'name': name,
        },
      );
    } on PlatformException catch(ex) {
      throw ContentChannelException._throw(ex, const [ContentChannelException.playlistNotExists]);
    }
  }

  static Future<void> removePlaylists(List<Playlist> playlists) async {
    return _channel.invokeMethod<void>('removePlaylists', {'ids': playlists.map((el) => el.id).toList()});
  }

  /// Throws:
  ///  * [ContentChannelException.playlistNotExists] when playlist doesn't exist.
  static Future<void> insertSongsInPlaylist({ required int index, required List<Song> songs, required Playlist playlist }) async {
    assert(songs.isNotEmpty);
    assert(index >= 0 && index <= playlist.songIds.length);
    try {
      return await _channel.invokeMethod<void>(
        'insertSongsInPlaylist',
        {
          'id': playlist.id,
          'index': index,
          'songIds': songs.map((el) => el.id).toList(),
        },
      );
    } on PlatformException catch(ex) {
      throw ContentChannelException._throw(ex, const [ContentChannelException.playlistNotExists]);
    }
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

  /// Throws:
  ///  * [ContentChannelException.playlistNotExists] when playlist doesn't exist.
  static Future<void> removeSongsFromPlaylist({ required List<Song> songs, required Playlist playlist }) async {
    assert(songs.isNotEmpty);
    try {
      return await _channel.invokeMethod<void>(
        'removeSongsFromPlaylist',
        {
          'id': playlist.id,
          'songIds': songs.map((el) => el.sourceId).toList(),
        },
      );
    } on PlatformException catch(ex) {
      throw ContentChannelException._throw(ex, const [ContentChannelException.playlistNotExists]);
    }
  }

  /// Checks if open intent is view (user tried to open file with app).
  static Future<bool> isIntentActionView() async {
    final res = await _channel.invokeMethod<bool>('isIntentActionView');
    return res!;
  }
}
