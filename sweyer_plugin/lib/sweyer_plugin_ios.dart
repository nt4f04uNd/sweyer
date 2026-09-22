import 'dart:typed_data';
import 'dart:ui';

import 'package:playify/playify.dart' as playify;

import 'sweyer_plugin_platform_interface.dart';

/// iOS-specific implementation of [SweyerPluginPlatform].
class IOSSweyerPlugin extends SweyerPluginPlatform {
  final playify.Playify _playify = playify.Playify.instance;
  final Map<String, bool> _albumArtCancellations = {};

  Future<List<playify.Song>>? _songsRequest;

  Future<List<playify.Song>> _retrieveSongsOnce() async {
    final pendingRequest = _songsRequest;
    if (pendingRequest != null) {
      return pendingRequest;
    }

    final request = _playify.getSongs();
    _songsRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_songsRequest, request)) {
        _songsRequest = null;
      }
    }
  }

  Future<T> _handlePlatformErrors<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw PlatformHandlerException(cause: error is Exception ? error : Exception(error.toString()));
    }
  }

  int _id(String value) => int.parse(value);

  int? _optionalId(String value) {
    final id = _id(value);
    return id == 0 ? null : id;
  }

  int _artistId(playify.Song song) => _optionalId(song.albumArtistID) ?? _id(song.artistID);

  String _artistName(playify.Song song) => song.albumArtistName.isEmpty ? song.artistName : song.albumArtistName;

  String? _songIdFromUri(String uri) {
    final parsedUri = Uri.tryParse(uri);
    if (parsedUri == null || parsedUri.pathSegments.isEmpty) {
      return null;
    }
    return parsedUri.pathSegments.last;
  }

  String _songUri(playify.Song song) => 'content://media/external/audio/media/${song.songID}';

  @override
  Future<Uint8List?> loadAlbumArt({required String uri, required Size size, required String cancellationSignalId}) {
    return _handlePlatformErrors(() async {
      _albumArtCancellations[cancellationSignalId] = false;
      try {
        final songId = _songIdFromUri(uri);
        if (songId == null) {
          return null;
        }
        final artwork = await _playify.getArtwork(
          songID: songId,
          width: size.width.round().clamp(1, 4096).toInt(),
          height: size.height.round().clamp(1, 4096).toInt(),
        );
        return _albumArtCancellations[cancellationSignalId] == true ? null : artwork;
      } finally {
        _albumArtCancellations.remove(cancellationSignalId);
      }
    });
  }

  @override
  Future<void> cancelAlbumArtLoad({required String id}) async {
    if (_albumArtCancellations.containsKey(id)) {
      _albumArtCancellations[id] = true;
    }
  }

  @override
  Future<void> fixAlbumArt(int albumId) async {}

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveSongs() {
    return _handlePlatformErrors(() async {
      final songs = await _retrieveSongsOnce();
      return songs.map((song) {
        return <String, dynamic>{
          'id': _id(song.songID),
          'title': song.title,
          'artist': song.artistName,
          'album': song.albumTitle.isEmpty ? null : song.albumTitle,
          'albumId': _optionalId(song.albumID),
          'artistId': _artistId(song),
          'genre': song.genre.isEmpty ? null : song.genre,
          'genreId': _optionalId(song.genreID),
          'track': song.trackNumber == 0 ? null : song.trackNumber.toString(),
          'dateAdded': song.dateAdded.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond,
          'duration': (song.duration * 1000).round(),
          'size': null,
          'filesystemPath': null,
        };
      }).toList(growable: false);
    });
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveAlbums() {
    return _handlePlatformErrors(() async {
      final songs = await _retrieveSongsOnce();
      final songsByAlbum = <int, List<playify.Song>>{};
      for (final song in songs) {
        final albumId = _optionalId(song.albumID);
        if (albumId != null) {
          (songsByAlbum[albumId] ??= []).add(song);
        }
      }

      return songsByAlbum.entries.map((entry) {
        final songs = entry.value;
        final firstSong = songs.first;
        final years = songs
            .where((song) => song.releaseDate.millisecondsSinceEpoch > 0)
            .map((song) => song.releaseDate.year)
            .toList(growable: false);
        return <String, dynamic>{
          'id': entry.key,
          'album': firstSong.albumTitle,
          'albumArt': _songUri(firstSong),
          'artist': _artistName(firstSong),
          'artistId': _artistId(firstSong),
          'firstYear': years.isEmpty ? null : years.reduce((a, b) => a < b ? a : b),
          'lastYear': years.isEmpty ? null : years.reduce((a, b) => a > b ? a : b),
          'numberOfSongs': songs.length,
        };
      }).toList(growable: false);
    });
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveArtists() {
    return _handlePlatformErrors(() async {
      final songs = await _retrieveSongsOnce();
      final songsByArtist = <int, List<playify.Song>>{};
      for (final song in songs) {
        (songsByArtist[_artistId(song)] ??= []).add(song);
      }

      return songsByArtist.entries.map((entry) {
        final songs = entry.value;
        return <String, dynamic>{
          'id': entry.key,
          'artist': _artistName(songs.first),
          'numberOfAlbums': songs.map((song) => _optionalId(song.albumID)).nonNulls.toSet().length,
          'numberOfTracks': songs.length,
        };
      }).toList(growable: false);
    });
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveGenres() {
    return _handlePlatformErrors(() async {
      final songs = await _retrieveSongsOnce();
      final songsByGenre = <int, List<playify.Song>>{};
      for (final song in songs) {
        final genreId = _optionalId(song.genreID);
        if (genreId != null && song.genre.isNotEmpty) {
          (songsByGenre[genreId] ??= []).add(song);
        }
      }

      return songsByGenre.entries.map((entry) {
        return <String, dynamic>{
          'id': entry.key,
          'name': entry.value.first.genre,
          'songIds': entry.value.map((song) => _id(song.songID)).toList(growable: false),
        };
      }).toList(growable: false);
    });
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrievePlaylists() {
    return _handlePlatformErrors(() async {
      final playlists = await _playify.getPlaylists() ?? const [];
      return playlists.map((playlist) {
        return <String, dynamic>{
          'id': _id(playlist.playlistID),
          'filesystemPath': null,
          'dateAdded': null,
          'dateModified': null,
          'name': playlist.title,
          'songIds': playlist.songs.map((song) => _id(song.songID)).toList(growable: false),
        };
      }).toList(growable: false);
    });
  }

  @override
  Future<bool> setSongsFavorite(List<int> songsIds, bool value) async => false;

  @override
  Future<bool> deleteSongs(List<Map<String, dynamic>> songs) async => false;

  @override
  Future<void> createPlaylist(String name) => Future.error(const UnsupportedApiException());

  @override
  Future<void> renamePlaylist(int playlistId, String name) => Future.error(const UnsupportedApiException());

  @override
  Future<void> removePlaylists(List<int> playlistIds) => Future.error(const UnsupportedApiException());

  @override
  Future<void> insertSongsInPlaylist({required int index, required List<int> songIds, required int playlistId}) =>
      Future.error(const UnsupportedApiException());

  @override
  Future<bool> moveSongInPlaylist({required int playlistId, required int from, required int to}) async => false;

  @override
  Future<void> removeFromPlaylistAt({required List<int> indexes, required int playlistId}) =>
      Future.error(const UnsupportedApiException());

  @override
  Future<bool> isIntentActionView() async => false;
}
