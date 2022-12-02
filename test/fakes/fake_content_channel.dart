import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import '../test.dart';

class FakeContentChannel implements ContentChannel {
  FakeContentChannel(TestWidgetsFlutterBinding binding) {
    instance = this;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('content_channel'), (call) {
      /// Ignore [CancellationSignal] calls
      if (call.method == 'cancelAlbumArtLoading') {
        return null;
      }
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
  Future<void> insertSongsInPlaylist({
    required int index,
    required List<Song> songs,
    required Playlist playlist,
  }) async {}

  @override
  Future<bool> isIntentActionView() async {
    return false;
  }

  @override
  Future<Uint8List?> loadAlbumArt({required String uri, required Size size, required CancellationSignal signal}) async {
    return Uint8List.fromList(kBlueSquarePng);
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
    for (final album in albumsList) {
      albumsMap[album.id] = album;
    }
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
