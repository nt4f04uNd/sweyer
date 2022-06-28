import 'dart:typed_data';
import 'dart:ui';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sweyer_plugin_method_channel.dart';

abstract class SweyerPluginPlatform extends PlatformInterface {
  /// Constructs a SweyerPluginPlatform.
  SweyerPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static SweyerPluginPlatform _instance = MethodChannelSweyerPlugin();

  /// The default instance of [SweyerPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelSweyerPlugin].
  static SweyerPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SweyerPluginPlatform] when
  /// they register themselves.
  static set instance(SweyerPluginPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<Uint8List?> loadAlbumArt({required String uri, required Size size, required String cancellationSignalId});

  Future<void> cancelAlbumArtLoad({required String id});

  Future<void> fixAlbumArt(int albumId);

  Future<Iterable<Map<String, dynamic>>> retrieveSongs();

  Future<Iterable<Map<String, dynamic>>> retrieveAlbums();

  Future<Iterable<Map<String, dynamic>>> retrievePlaylists();

  Future<Iterable<Map<String, dynamic>>> retrieveArtists();

  Future<Iterable<Map<String, dynamic>>> retrieveGenres();

  Future<bool> setSongsFavorite(List<int> songsIds, bool value);

  Future<bool> deleteSongs(List<Map<String, dynamic>> songs);

  Future<void> createPlaylist(String name);

  Future<void> renamePlaylist(int playlistId, String name);

  Future<void> removePlaylists(List<int> playlistIds);

  Future<void> insertSongsInPlaylist({required int index, required List<int> songIds, required int playlistId});

  Future<bool> moveSongInPlaylist({required int playlistId, required int from, required int to});

  Future<void> removeFromPlaylistAt({required List<int> indexes, required int playlistId});

  Future<bool> isIntentActionView();
}
