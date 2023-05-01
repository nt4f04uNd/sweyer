import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sweyer_plugin_platform_interface.dart';
import 'sweyer_plugin.dart';

enum SweyerMethodChannelExceptionCode {
  /// Generic error.
  unexpected('UNEXPECTED_ERROR'),

  /// On Android 30 requests like `MediaStore.createDeletionRequest` require
  /// calling `startIntentSenderForResult`, which might throw this exception.
  intentSender('INTENT_SENDER_ERROR'),

  io('IO_ERROR'),

  /// API is unavailable on current SDK level.
  sdk('SDK_ERROR'),

  /// Operation cannot be performed because there's no such playlist
  playlistNotExists('PLAYLIST_NOT_EXISTS_ERROR');

  final String value;

  const SweyerMethodChannelExceptionCode(this.value);
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
    } on PlatformException catch (error) {
      throw _convertCommonExceptions('loadAlbumArt failed', error);
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
  Future<Iterable<Map<String, dynamic>>> retrieveSongs() async =>
      (await methodChannel.invokeListMethod<Map>('retrieveSongs'))!.map(Map.castFrom);

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveAlbums() async =>
      (await methodChannel.invokeListMethod<Map>('retrieveAlbums'))!.map(Map.castFrom);

  @override
  Future<Iterable<Map<String, dynamic>>> retrievePlaylists() async =>
      (await methodChannel.invokeListMethod<Map>('retrievePlaylists'))!.map(Map.castFrom);

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveArtists() async =>
      (await methodChannel.invokeListMethod<Map>('retrieveArtists'))!.map(Map.castFrom);

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveGenres() async =>
      (await methodChannel.invokeListMethod<Map>('retrieveGenres'))!.map(Map.castFrom);

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
    } on PlatformException catch (error) {
      throw _convertCommonExceptions('setSongsFavorite failed', error);
    }
  }

  @override
  Future<bool> deleteSongs(List<Map<String, dynamic>> songs) async {
    try {
      return (await methodChannel.invokeMethod<bool>('deleteSongs', {
        'songs': songs,
      }))!;
    } on PlatformException catch (error) {
      throw _convertCommonExceptions('deleteSongs failed', error);
    }
  }

  @override
  Future<void> createPlaylist(String name) async {
    try {
      return await methodChannel.invokeMethod<void>('createPlaylist', {'name': name});
    } on PlatformException catch (error) {
      throw _convertCommonExceptions('createPlaylist failed', error);
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
    } on PlatformException catch (error) {
      if (error.code == SweyerMethodChannelExceptionCode.playlistNotExists.value) {
        throw PlaylistNotExistException(playlistId, cause: error);
      }
      throw _convertCommonExceptions('renamePlaylist failed', error);
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
    } on PlatformException catch (error) {
      if (error.code == SweyerMethodChannelExceptionCode.playlistNotExists.value) {
        throw PlaylistNotExistException(playlistId, cause: error);
      }
      throw _convertCommonExceptions('insertSongsInPlaylist failed', error);
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
    } on PlatformException catch (error) {
      if (error.code == SweyerMethodChannelExceptionCode.playlistNotExists.value) {
        throw PlaylistNotExistException(playlistId, cause: error);
      }
      throw _convertCommonExceptions('removeFromPlaylistAt failed', error);
    }
  }

  @override
  Future<bool> isIntentActionView() async => (await methodChannel.invokeMethod<bool>('isIntentActionView'))!;

  SweyerPluginException _convertCommonExceptions(String message, PlatformException error) {
    if (error.code == SweyerMethodChannelExceptionCode.sdk.value) {
      return UnsupportedApiException(cause: error);
    } else if (error.code == SweyerMethodChannelExceptionCode.io.value) {
      return SweyerPluginIoException(cause: error);
    }
    return SweyerPluginException(message, cause: error);
  }
}
