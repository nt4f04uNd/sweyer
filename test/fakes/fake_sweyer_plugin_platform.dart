import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:sweyer_plugin/sweyer_plugin_platform_interface.dart';
import '../test.dart';

/// A 50x50 blue square png.
const List<int> _kBlueSquarePng = <int>[
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, 0x49, //
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x32, 0x00, 0x00, 0x00, 0x32, 0x08, 0x06, //
  0x00, 0x00, 0x00, 0x1e, 0x3f, 0x88, 0xb1, 0x00, 0x00, 0x00, 0x48, 0x49, 0x44, //
  0x41, 0x54, 0x78, 0xda, 0xed, 0xcf, 0x31, 0x0d, 0x00, 0x30, 0x08, 0x00, 0xb0, //
  0x61, 0x63, 0x2f, 0xfe, 0x2d, 0x61, 0x05, 0x34, 0xf0, 0x92, 0xd6, 0x41, 0x23, //
  0x7f, 0xf5, 0x3b, 0x20, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, //
  0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, //
  0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, //
  0x44, 0x44, 0x44, 0x36, 0x06, 0x03, 0x6e, 0x69, 0x47, 0x12, 0x8e, 0xea, 0xaa, //
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
];

class FakeSweyerPluginPlatform extends SweyerPluginPlatform {
  FakeSweyerPluginPlatform(TestWidgetsFlutterBinding binding) {
    instance = this;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('content_channel'), (call) {
      /// Ignore [CancellationSignal] calls
      if (call.method == 'cancelAlbumArtLoading') {
        return null;
      }
      throw UnimplementedError('method is not mocked');
    });
  }
  static late FakeSweyerPluginPlatform instance;

  List<Song>? songs;
  List<Album>? albums;
  List<Playlist>? playlists;
  List<Artist>? artists;

  @override
  Future<void> createPlaylist(String name) async {}

  @override
  Future<bool> deleteSongs(List<Map> songs) async {
    return true;
  }

  @override
  Future<void> fixAlbumArt(int albumId) async {}

  @override
  Future<void> insertSongsInPlaylist({
    required int index,
    required List<int> songIds,
    required int playlistId,
  }) async {}

  @override
  Future<bool> isIntentActionView() async {
    return false;
  }

  @override
  Future<Uint8List?> loadAlbumArt({
    required String uri,
    required Size size,
    required String cancellationSignalId,
  }) async {
    return Uint8List.fromList(_kBlueSquarePng);
  }

  @override
  Future<void> cancelAlbumArtLoad({required String id}) async {}

  @override
  Future<bool> moveSongInPlaylist({required int playlistId, required int from, required int to}) async {
    return true;
  }

  @override
  Future<void> removeFromPlaylistAt({required List<int> indexes, required int playlistId}) async {}

  @override
  Future<void> removePlaylists(List<int> playlistIds) async {}

  @override
  Future<void> renamePlaylist(int playlistId, String name) async {}

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveAlbums() async {
    final albumsList = albums ?? [albumWith()];
    return albumsList.map((album) => album.toMap()).toList();
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveArtists() async {
    return (artists ?? [artistWith()]).map((artist) => artist.toMap()).toList();
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveGenres() async {
    return [];
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrievePlaylists() async {
    return (playlists ?? [playlistWith()]).map((playlist) => playlist.toMap()).toList();
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveSongs() async {
    return (songs ?? [songWith()]).map((song) => song.toMap()).toList();
  }

  @override
  Future<bool> setSongsFavorite(List<int> songIds, bool value) async {
    return true;
  }
}
