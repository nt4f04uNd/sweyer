import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sweyer_plugin_platform_interface.dart';
import 'sweyer_plugin.dart';

class SweyerMethodChannelException extends SweyerPluginException {
  const SweyerMethodChannelException._(this.value, [this._exception]);

  final PlatformException? _exception;
  @override
  final String value;

  /// Generic error.
  static const unexpected = SweyerMethodChannelException._('UNEXPECTED_ERROR');

  /// On Android 30 requests like `MediaStore.createDeletionRequest` require
  /// calling `startIntentSenderForResult`, which might throw this exception.
  static const intentSender = SweyerMethodChannelException._('INTENT_SENDER_ERROR');

  static const io = SweyerMethodChannelException._('IO_ERROR');

  /// API is unavailable on current SDK level.
  static const sdk = SweyerMethodChannelException._('SDK_ERROR');

  /// Operation cannot be performed because there's no such playlist
  static const playlistNotExists = SweyerMethodChannelException._('PLAYLIST_NOT_EXISTS_ERROR');

  /// Create a new [SweyerMethodChannelException] form the platform [exception]
  /// and assert that it is either [unexpected] or in the list of [expectedExceptions].
  static SweyerMethodChannelException _throw(
    PlatformException exception,
    List<SweyerMethodChannelException> expectedExceptions,
  ) {
    final toThrow = SweyerMethodChannelException._(exception.code, exception);
    assert(toThrow == unexpected || expectedExceptions.contains(toThrow));
    return toThrow;
  }

  @override
  String toString() => _exception.toString();
}

/// An implementation of [SweyerPluginPlatform] that uses method channels.
class MethodChannelSweyerPlugin extends SweyerPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sweyer_plugin');

  @override
  Future<Uint8List?> loadAlbumArt({
    required String uri,
    required Size size,
    required String cancellationSignalId,
  }) async {
    try {
      return await methodChannel.invokeMethod<Uint8List>(
        'loadAlbumArt',
        {
          'id': cancellationSignalId,
          'uri': uri,
          'width': size.width.toInt(),
          'height': size.height.toInt(),
        },
      );
    } on PlatformException catch (ex) {
      throw SweyerMethodChannelException._throw(
          ex, const [SweyerMethodChannelException.io, SweyerMethodChannelException.sdk]);
    }
  }

  @override
  Future<void> cancelAlbumArtLoad({required String id}) async => methodChannel.invokeMethod<void>(
        'cancelAlbumArtLoading',
        {'id': id},
      );

  @override
  Future<void> fixAlbumArt(int albumId) async => methodChannel.invokeMethod<void>(
        'fixAlbumArt',
        {'id': albumId},
      );

  @override
  Future<List<Map>> retrieveSongs() async => (await methodChannel.invokeListMethod<Map>('retrieveSongs'))!;

  @override
  Future<List<Map>> retrieveAlbums() async => (await methodChannel.invokeListMethod<Map>('retrieveAlbums'))!;

  @override
  Future<List<Map>> retrievePlaylists() async => (await methodChannel.invokeListMethod<Map>('retrievePlaylists'))!;

  @override
  Future<List<Map>> retrieveArtists() async => (await methodChannel.invokeListMethod<Map>('retrieveArtists'))!;

  @override
  Future<List<Map>> retrieveGenres() async => (await methodChannel.invokeListMethod<Map>('retrieveGenres'))!;

  @override
  Future<bool> setSongsFavorite(List<int> songsIds, bool value) async {
    try {
      return (await methodChannel.invokeMethod<bool>(
        'setSongsFavorite',
        {
          'songIds': songsIds,
          'value': value,
        },
      ))!;
    } on PlatformException catch (ex) {
      throw SweyerMethodChannelException._throw(
        ex,
        const [SweyerMethodChannelException.sdk, SweyerMethodChannelException.intentSender],
      );
    }
  }

  @override
  Future<bool> deleteSongs(List<Map> songs) async {
    try {
      return (await methodChannel.invokeMethod<bool>(
        'deleteSongs',
        {'songs': songs},
      ))!;
    } on PlatformException catch (ex) {
      throw SweyerMethodChannelException._throw(ex, const [SweyerMethodChannelException.intentSender]);
    }
  }

  @override
  Future<void> createPlaylist(String name) async {
    try {
      return await methodChannel.invokeMethod<void>('createPlaylist', {'name': name});
    } on PlatformException catch (ex) {
      throw SweyerMethodChannelException._throw(ex, const []);
    }
  }

  @override
  Future<void> renamePlaylist(int playlistId, String name) async {
    try {
      return await methodChannel.invokeMethod<void>(
        'renamePlaylist',
        {
          'id': playlistId,
          'name': name,
        },
      );
    } on PlatformException catch (ex) {
      throw SweyerMethodChannelException._throw(ex, const [SweyerMethodChannelException.playlistNotExists]);
    }
  }

  @override
  Future<void> removePlaylists(List<int> playlistIds) async =>
      methodChannel.invokeMethod<void>('removePlaylists', {'ids': playlistIds});

  @override
  Future<void> insertSongsInPlaylist({
    required int index,
    required List<int> songIds,
    required int playlistId,
  }) async {
    try {
      return await methodChannel.invokeMethod<void>(
        'insertSongsInPlaylist',
        {
          'id': playlistId,
          'index': index,
          'songIds': songIds,
        },
      );
    } on PlatformException catch (ex) {
      throw SweyerMethodChannelException._throw(ex, const [SweyerMethodChannelException.playlistNotExists]);
    }
  }

  @override
  Future<bool> moveSongInPlaylist({required int playlistId, required int from, required int to}) async =>
      (await methodChannel.invokeMethod<bool>(
        'moveSongInPlaylist',
        {
          'id': playlistId,
          'from': from,
          'to': to,
        },
      ))!;

  @override
  Future<void> removeFromPlaylistAt({required List<int> indexes, required int playlistId}) async {
    try {
      return await methodChannel.invokeMethod<void>(
        'removeFromPlaylistAt',
        {
          'id': playlistId,
          'indexes': indexes,
        },
      );
    } on PlatformException catch (ex) {
      throw SweyerMethodChannelException._throw(ex, const [SweyerMethodChannelException.playlistNotExists]);
    }
  }

  @override
  Future<bool> isIntentActionView() async => (await methodChannel.invokeMethod<bool>('isIntentActionView'))!;
}
