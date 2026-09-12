import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sweyer_plugin_ios.dart';
import 'sweyer_plugin_method_channel.dart';

/// Base class for all exceptions from the Sweyer plugin.
class SweyerPluginException implements Exception {
  /// The exception reason.
  final String message;

  /// An optional cause of this exception.
  final Exception? cause;

  const SweyerPluginException(this.message, {this.cause});

  @override
  String toString() {
    var representation = "$runtimeType: $message";
    if (cause != null) {
      representation += "\n\nCaused by:\n$cause";
    }
    return representation;
  }
}

/// An IO operation failed.
class SweyerPluginIoException extends SweyerPluginException {
  const SweyerPluginIoException({super.cause}) : super('An IO operation failed');
}

/// An operation was performed on a playlist that doesn't exist.
class PlaylistNotExistException extends SweyerPluginException {
  /// The id of the playlist that does not exist.
  final int playlistId;

  const PlaylistNotExistException(this.playlistId, {super.cause}) : super('No playlist with id $playlistId found');
}

/// The functionality requested is unsupported on this platform or API level.
class UnsupportedApiException extends SweyerPluginException {
  const UnsupportedApiException({super.cause}) : super('The required API is not supported');
}

/// The platform handler for this operation failed.
class PlatformHandlerException extends SweyerPluginException {
  const PlatformHandlerException({super.cause}) : super('Platform handler failed');
}

abstract class SweyerPluginPlatform extends PlatformInterface {
  /// Constructs a SweyerPluginPlatform.
  SweyerPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static SweyerPluginPlatform _instance = _getPlatformInstance();

  /// The default instance of [SweyerPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelSweyerPlugin] for Android and [IOSSweyerPlugin] for iOS.
  static SweyerPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SweyerPluginPlatform] when
  /// they register themselves.
  static set instance(SweyerPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// The default instance of [SweyerPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelSweyerPlugin] for Android and [IOSSweyerPlugin] for iOS.
  static SweyerPluginPlatform _getPlatformInstance() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return IOSSweyerPlugin();
    }
    return MethodChannelSweyerPlugin();
  }

  /// Loads album art for a song.
  Future<Uint8List?> loadAlbumArt({required String uri, required Size size, required String cancellationSignalId});

  /// Cancels loading of album art.
  Future<void> cancelAlbumArtLoad({required String id});

  /// Fixes album art for an album.
  Future<void> fixAlbumArt(int albumId);

  /// Retrieves all songs from the device.
  Future<Iterable<Map<String, dynamic>>> retrieveSongs();

  /// Retrieves all albums from the device.
  Future<Iterable<Map<String, dynamic>>> retrieveAlbums();

  /// Retrieves all playlists from the device.
  Future<Iterable<Map<String, dynamic>>> retrievePlaylists();

  /// Retrieves all artists from the device.
  Future<Iterable<Map<String, dynamic>>> retrieveArtists();

  /// Retrieves all genres from the device.
  Future<Iterable<Map<String, dynamic>>> retrieveGenres();

  /// Sets songs as favorite.
  Future<bool> setSongsFavorite(List<int> songsIds, bool value);

  /// Deletes songs from the device.
  Future<bool> deleteSongs(List<Map<String, dynamic>> songs);

  /// Creates a new playlist.
  Future<void> createPlaylist(String name);

  /// Renames a playlist.
  Future<void> renamePlaylist(int playlistId, String name);

  /// Removes playlists.
  Future<void> removePlaylists(List<int> playlistIds);

  /// Inserts songs in a playlist at a specific index.
  Future<void> insertSongsInPlaylist({required int index, required List<int> songIds, required int playlistId});

  /// Moves a song in a playlist from one index to another.
  Future<bool> moveSongInPlaylist({required int playlistId, required int from, required int to});

  /// Removes songs from a playlist at specific indexes.
  Future<void> removeFromPlaylistAt({required List<int> indexes, required int playlistId});

  /// Checks if the app was started with an intent action view.
  Future<bool> isIntentActionView();
}
