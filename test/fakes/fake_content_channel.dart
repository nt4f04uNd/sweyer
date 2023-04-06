import 'dart:ui';
import 'dart:typed_data';
import 'dart:collection';

import 'package:flutter/services.dart';
import '../test.dart';

/// An Entry in the [FakeContentChannel.favoriteRequestLog].
class FavoriteLogEntry {
  /// The set of songs that were modified.
  final Set<Song> songs;

  /// `true` if a request was made to make the songs favorite, `false` if the request was made to unfavor them.
  final bool setFavorite;

  const FavoriteLogEntry(this.songs, this.setFavorite);

  @override
  String toString() => '${runtimeType.toString()}(songs=$songs, setFavorite=$setFavorite)';

  @override
  bool operator ==(Object other) =>
      other is FavoriteLogEntry && setFavorite == other.setFavorite && setEquals(songs, other.songs);

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(songs), setFavorite);
}

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

  /// The log of all recorded [setSongsFavorite] calls.
  List<FavoriteLogEntry> get favoriteRequestLog => UnmodifiableListView(_favoriteRequestLog);
  final List<FavoriteLogEntry> _favoriteRequestLog = [];

  @override
  Future<bool> setSongsFavorite(Set<Song> songs, bool value) async {
    _favoriteRequestLog.add(FavoriteLogEntry(songs, value));
    return true;
  }
}
