import 'dart:typed_data';

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweyer_plugin/sweyer_plugin.dart';
import 'package:sweyer_plugin/sweyer_plugin_method_channel.dart';

class MockSweyerPluginPlatform extends SweyerPluginPlatform {
  @override
  Future<void> cancelAlbumArtLoad({required String id}) {
    // TODO: implement cancelAlbumArtLoad
    throw UnimplementedError();
  }

  @override
  Future<void> createPlaylist(String name) {
    // TODO: implement createPlaylist
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteSongs(List<Map<String, dynamic>> songs) {
    // TODO: implement deleteSongs
    throw UnimplementedError();
  }

  @override
  Future<void> fixAlbumArt(int albumId) {
    // TODO: implement fixAlbumArt
    throw UnimplementedError();
  }

  @override
  Future<void> insertSongsInPlaylist({required int index, required List<int> songIds, required int playlistId}) {
    // TODO: implement insertSongsInPlaylist
    throw UnimplementedError();
  }

  @override
  Future<bool> isIntentActionView() async {
    return true;
  }

  @override
  Future<Uint8List?> loadAlbumArt({required String uri, required Size size, required String cancellationSignalId}) {
    // TODO: implement loadAlbumArt
    throw UnimplementedError();
  }

  @override
  Future<bool> moveSongInPlaylist({required int playlistId, required int from, required int to}) {
    // TODO: implement moveSongInPlaylist
    throw UnimplementedError();
  }

  @override
  Future<void> removeFromPlaylistAt({required List<int> indexes, required int playlistId}) {
    // TODO: implement removeFromPlaylistAt
    throw UnimplementedError();
  }

  @override
  Future<void> removePlaylists(List<int> playlistIds) {
    // TODO: implement removePlaylists
    throw UnimplementedError();
  }

  @override
  Future<void> renamePlaylist(int playlistId, String name) {
    // TODO: implement renamePlaylist
    throw UnimplementedError();
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveAlbums() {
    // TODO: implement retrieveAlbums
    throw UnimplementedError();
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveArtists() {
    // TODO: implement retrieveArtists
    throw UnimplementedError();
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveGenres() {
    // TODO: implement retrieveGenres
    throw UnimplementedError();
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrievePlaylists() {
    // TODO: implement retrievePlaylists
    throw UnimplementedError();
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveSongs() {
    // TODO: implement retrieveSongs
    throw UnimplementedError();
  }

  @override
  Future<bool> setSongsFavorite(List<int> songsIds, bool value) {
    // TODO: implement setSongsFavorite
    throw UnimplementedError();
  }
}

void main() {
  final SweyerPluginPlatform initialPlatform = SweyerPluginPlatform.instance;

  test('$MethodChannelSweyerPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSweyerPlugin>());
  });

  test('isIntentActionView', () async {
    MockSweyerPluginPlatform fakePlatform = MockSweyerPluginPlatform();
    SweyerPluginPlatform.instance = fakePlatform;

    expect(await SweyerPlugin.instance.isIntentActionView(), true);
  });
}
