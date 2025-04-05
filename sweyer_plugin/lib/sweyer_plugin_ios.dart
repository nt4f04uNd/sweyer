import 'dart:typed_data';
import 'dart:ui';

import 'package:playify/playify.dart';
import 'sweyer_plugin_platform_interface.dart';

/// iOS-specific implementation of [SweyerPluginPlatform].
class IOSSweyerPlugin extends SweyerPluginPlatform {
  final Playify _playify = Playify();

  // Map to store cancellation signals
  final Map<String, bool> _cancellationSignals = {};

  @override
  Future<Uint8List?> loadAlbumArt({
    required String uri,
    required Size size,
    required String cancellationSignalId,
  }) async {
    try {
      // Register the cancellation signal
      _cancellationSignals[cancellationSignalId] = false;

      // Check if the operation was cancelled before starting
      if (_cancellationSignals[cancellationSignalId] == true) {
        return null;
      }

      // Extract song ID from URI
      // URI format is expected to be something like "music://song/12345"
      final songId = _extractIdFromUri(uri);
      if (songId == null) {
        return null;
      }

      // Try to get album art for the specific song
      try {
        final artists = await _playify.getAllSongs();
        for (final artist in artists) {
          for (final album in artist.albums) {
            for (final song in album.songs) {
              // Check if the operation was cancelled during execution
              if (_cancellationSignals[cancellationSignalId] == true) {
                return null;
              }

              if (song.songID == songId || song.songID.hashCode.toString() == songId) {
                // Found the song, get its album art directly
                // We need to get the album art from the album
                return album.coverArt;
              }
            }
          }
        }
      } catch (e) {
        // If there's an error, return null
        return null;
      }

      return null;
    } catch (e) {
      throw PlatformHandlerException(cause: e as Exception?);
    } finally {
      // Clean up the cancellation signal
      _cancellationSignals.remove(cancellationSignalId);
    }
  }

  /// Extracts ID from URI like "music://song/12345"
  String? _extractIdFromUri(String uri) {
    final parts = uri.split('/');
    if (parts.length >= 3) {
      return parts.last;
    }
    return null;
  }

  @override
  Future<void> cancelAlbumArtLoad({required String id}) async {
    // Mark the operation as cancelled
    _cancellationSignals[id] = true;
  }

  @override
  Future<void> fixAlbumArt(int albumId) async {
    // This is an Android-specific operation, not needed on iOS
    // Just return without throwing an exception to maintain compatibility
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveSongs() async {
    try {
      final artists = await _playify.getAllSongs();
      final result = <Map<String, dynamic>>[];

      // Flatten the artists -> albums -> songs structure
      for (final artist in artists) {
        for (final album in artist.albums) {
          for (final song in album.songs) {
            final songId = int.tryParse(song.songID) ?? song.songID.hashCode;
            result.add({
              'id': songId,
              'title': song.title,
              'artist': song.artistName,
              'album': song.albumTitle,
              'albumId': album.title.hashCode,
              'artistId': artist.name.hashCode,
              'genre': song.genre,
              'genreId': song.genre.hashCode,
              'track': song.trackNumber.toString(),
              'dateAdded': song.releaseDate.millisecondsSinceEpoch,
              'dateModified': song.releaseDate.millisecondsSinceEpoch,
              'duration': (song.duration * 1000).toInt(),
              'size': null, // iOS doesn't expose file size
              'filesystemPath': null, // iOS doesn't expose filesystem path
              'isFavoriteInMediaStore': false, // iOS doesn't expose favorite status
              'generationAdded': null, // iOS specific
              'generationModified': null, // iOS specific
              // Additional fields kept for backward compatibility
              'trackNumber': song.trackNumber,
              'albumTrackCount': album.albumTrackCount,
              'discNumber': song.discNumber,
              'albumDiscCount': album.discCount,
            });
          }
        }
      }

      return result;
    } catch (e) {
      throw PlatformHandlerException(cause: e as Exception?);
    }
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveAlbums() async {
    try {
      final artists = await _playify.getAllSongs();
      final result = <Map<String, dynamic>>[];
      final processedAlbums = <int>{};

      // Extract unique albums from the artists
      for (final artist in artists) {
        for (final album in artist.albums) {
          final albumId = album.title.hashCode;

          // Skip if we've already processed this album
          if (processedAlbums.contains(albumId)) {
            continue;
          }

          processedAlbums.add(albumId);

          // Get the first song ID to use for album art
          final firstSongId = album.songs.isNotEmpty ? album.songs.first.songID : null;

          result.add({
            'id': albumId,
            'album': album.title,
            'artist': album.artistName,
            'artistId': artist.name.hashCode,
            'trackCount': album.albumTrackCount,
            'genre': album.songs.isNotEmpty ? album.songs.first.genre : '',
            'releaseDate': album.songs.isNotEmpty ? album.songs.first.releaseDate.millisecondsSinceEpoch : 0,
            'year': album.songs.isNotEmpty ? album.songs.first.releaseDate.year : 0,
            // Create a URI that can be used for album art loading if we have a song
            'uri': firstSongId != null ? 'music://song/$firstSongId' : null,
          });
        }
      }

      return result;
    } catch (e) {
      throw PlatformHandlerException(cause: e as Exception?);
    }
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveArtists() async {
    try {
      final artists = await _playify.getAllSongs();
      final processedArtists = <int, Map<String, dynamic>>{};

      for (final artist in artists) {
        final artistId = artist.name.hashCode;

        // Skip if we've already processed this artist
        if (processedArtists.containsKey(artistId)) {
          continue;
        }

        // Count total tracks across all albums
        int trackCount = 0;
        for (final album in artist.albums) {
          trackCount += album.songs.length;
        }

        processedArtists[artistId] = {
          'id': artistId,
          'artist': artist.name, // Match model field name
          'numberOfAlbums': artist.albums.length, // Match model field name
          'numberOfTracks': trackCount, // Match model field name
        };
      }

      return processedArtists.values.where((artist) => 
        artist['artist'] != null && // Ensure required fields are present
        artist['numberOfAlbums'] != null &&
        artist['numberOfTracks'] != null
      );
    } catch (e) {
      throw PlatformHandlerException(cause: e as Exception?);
    }
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrieveGenres() async {
    try {
      final genres = await _playify.getAllGenres();
      final result = <Map<String, dynamic>>[];

      // Process each genre
      for (final genre in genres) {
        if (genre.isEmpty) continue; // Skip empty genres

        final genreId = genre.hashCode;

        // Find all songs in this genre to populate songIds
        final songIds = <int>[];
        try {
          final artists = await _playify.getAllSongs();
          for (final artist in artists) {
            for (final album in artist.albums) {
              for (final song in album.songs) {
                if (song.genre == genre) {
                  final songId = int.tryParse(song.songID) ?? song.songID.hashCode;
                  songIds.add(songId);
                }
              }
            }
          }
        } catch (_) {
          // Ignore errors when collecting song IDs
        }

        result.add({
          'id': genreId,
          'name': genre,
          'songIds': songIds,
        });
      }

      return result;
    } catch (e) {
      throw PlatformHandlerException(cause: e as Exception?);
    }
  }

  @override
  Future<Iterable<Map<String, dynamic>>> retrievePlaylists() async {
    try {
      final playlists = await _playify.getPlaylists();
      final result = <Map<String, dynamic>>[];

      if (playlists != null) {
        for (final playlist in playlists) {
          final songIds = playlist.songs.map((song) => int.tryParse(song.songID) ?? song.songID.hashCode).toList();

          // Get a representative song ID for playlist art
          final representativeSongId = playlist.songs.isNotEmpty ? playlist.songs.first.songID : null;

          final playlistId = int.tryParse(playlist.playlistID) ?? playlist.playlistID.hashCode;

          result.add({
            'id': playlistId,
            'name': playlist.title,
            'songIds': songIds,
            'dateAdded': DateTime.now().millisecondsSinceEpoch, // iOS doesn't provide creation date
            'dateModified': DateTime.now().millisecondsSinceEpoch, // iOS doesn't provide modification date
            // Create a URI that can be used for playlist art loading if we have a song
            'uri': representativeSongId != null ? 'music://song/$representativeSongId' : null,
          });
        }
      }

      return result;
    } catch (e) {
      throw PlatformHandlerException(cause: e as Exception?);
    }
  }

  @override
  Future<bool> setSongsFavorite(List<int> songsIds, bool value) async {
    // iOS doesn't support setting favorites through the API
    // Return false to indicate operation was not successful
    return false;
  }

  @override
  Future<bool> deleteSongs(List<Map<String, dynamic>> songs) async {
    // iOS doesn't support deleting songs through the API
    // Return false to indicate operation was not successful
    return false;
  }

  @override
  Future<void> createPlaylist(String name) async {
    // Playify doesn't support creating playlists
    throw UnsupportedApiException();
  }

  @override
  Future<void> renamePlaylist(int playlistId, String name) async {
    // Playify doesn't support renaming playlists
    throw UnsupportedApiException();
  }

  @override
  Future<void> removePlaylists(List<int> playlistIds) async {
    // Playify doesn't support removing playlists
    throw UnsupportedApiException();
  }

  @override
  Future<void> insertSongsInPlaylist({
    required int index,
    required List<int> songIds,
    required int playlistId,
  }) async {
    // Playify doesn't support inserting songs in playlists
    throw UnsupportedApiException();
  }

  @override
  Future<bool> moveSongInPlaylist({
    required int playlistId,
    required int from,
    required int to,
  }) async {
    try {
      // Playify doesn't support reordering songs in a playlist directly
      // Return false to indicate operation was not successful
      return false;
    } catch (e) {
      throw PlatformHandlerException(cause: e as Exception?);
    }
  }

  @override
  Future<void> removeFromPlaylistAt({
    required List<int> indexes,
    required int playlistId,
  }) async {
    // Playify doesn't support removing songs from playlists
    throw UnsupportedApiException();
  }

  @override
  Future<bool> isIntentActionView() async {
    // This is an Android-specific operation, not applicable for iOS
    return false;
  }
}
