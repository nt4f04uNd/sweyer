import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import '../test.dart';

/// A 50x50 blue square png.
const List<int> _kBlueSquarePng = <int>[
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x32, 0x00, 0x00, 0x00, 0x32, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1e, 0x3f, 0x88, 0xb1, 0x00, 0x00, 0x00, 0x48, 0x49, 0x44,
  0x41, 0x54, 0x78, 0xda, 0xed, 0xcf, 0x31, 0x0d, 0x00, 0x30, 0x08, 0x00, 0xb0,
  0x61, 0x63, 0x2f, 0xfe, 0x2d, 0x61, 0x05, 0x34, 0xf0, 0x92, 0xd6, 0x41, 0x23,
  0x7f, 0xf5, 0x3b, 0x20, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44,
  0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44,
  0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44,
  0x44, 0x44, 0x44, 0x36, 0x06, 0x03, 0x6e, 0x69, 0x47, 0x12, 0x8e, 0xea, 0xaa,
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
];

class FakeContentChannel implements ContentChannel {
  FakeContentChannel(TestWidgetsFlutterBinding binding) {
    instance = this;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('content_channel'), (call) {
      /// Ignore [CancellationSignal] calls
      if (call.method == 'cancelAlbumArtLoading')
        return null;
      throw UnimplementedError('method is not mocked');
    });
  }
  static late FakeContentChannel instance;

  List<Song>? songs;
  List<Album>? albums;
  List<Playlist>? playlists;
  List<Artist>? artists;

  @override
  Future<void> createPlaylist(String name) async {}

  @override
  Future<bool> deleteSongs(Set<Song> songs) async {
    return true;
  }

  @override
  Future<void> fixAlbumArt(int albumId) async {}

  @override
  Future<void> insertSongsInPlaylist({required int index, required List<Song> songs, required Playlist playlist}) async {}

  @override
  Future<bool> isIntentActionView() async {
    return false;
  }

  @override
  Future<Uint8List?> loadAlbumArt({required String uri, required Size size, required CancellationSignal signal}) async {
    return Uint8List.fromList(_kBlueSquarePng);
  }

  @override
  Future<bool> moveSongInPlaylist({required Playlist playlist, required int from, required int to}) async {
    return true;
  }

  @override
  Future<void> removeFromPlaylistAt({required List<int> indexes, required Playlist playlist}) async {}

  @override
  Future<void> removePlaylists(List<Playlist> playlists) async {}

  @override
  Future<void> renamePlaylist(Playlist playlist, String name) async {}

  @override
  Future<Map<int, Album>> retrieveAlbums() async {
    final albumsList = albums ?? [albumWith()];
    final Map<int, Album> albumsMap = {};
    for (final album in albumsList)
      albumsMap[album.id] = album;
    return albumsMap;
  }

  @override
  Future<List<Artist>> retrieveArtists() async {
    return artists ?? [artistWith()];
  }

  @override
  Future<List<Genre>> retrieveGenres() async {
    return [];
  }

  @override
  Future<List<Playlist>> retrievePlaylists() async {
    return playlists ?? [playlistWith()];
  }

  @override
  Future<List<Song>> retrieveSongs() async {
    return songs ?? [songWith()];
  }

  @override
  Future<bool> setSongsFavorite(Set<Song> songs, bool value) async {
    return true;
  }
}
