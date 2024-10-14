import '../../test.dart';

void main() {
  group('Song sorting', () {
    late List<Song> songs;
    setUp(() {
      songs = [
        songWith(id: 0, dateModified: 0, dateAdded: 0, title: '', artist: '', album: ''),
        songWith(id: 1, dateModified: 1, dateAdded: 0, title: '', artist: '', album: ''),
        songWith(id: 2, dateModified: -1, dateAdded: 0, title: '', artist: '', album: ''),
        songWith(id: 3, dateModified: 0, dateAdded: 1, title: '', artist: '', album: ''),
        songWith(id: 4, dateModified: 0, dateAdded: -1, title: '', artist: '', album: ''),
        songWith(id: 5, dateModified: 0, dateAdded: 0, title: 'A', artist: '', album: ''),
        songWith(id: 6, dateModified: 0, dateAdded: 0, title: 'AA', artist: '', album: ''),
        songWith(id: 7, dateModified: 0, dateAdded: 0, title: 'a', artist: '', album: ''),
        songWith(id: 8, dateModified: 0, dateAdded: 0, title: 'z', artist: '', album: ''),
        songWith(id: 9, dateModified: 0, dateAdded: 0, title: '', artist: 'A', album: ''),
        songWith(id: 10, dateModified: 0, dateAdded: 0, title: '', artist: 'AA', album: ''),
        songWith(id: 11, dateModified: 0, dateAdded: 0, title: '', artist: 'a', album: ''),
        songWith(id: 12, dateModified: 0, dateAdded: 0, title: '', artist: 'z', album: ''),
        songWith(id: 13, dateModified: 0, dateAdded: 0, title: '', artist: '', album: 'A'),
        songWith(id: 14, dateModified: 0, dateAdded: 0, title: '', artist: '', album: 'AA'),
        songWith(id: 15, dateModified: 0, dateAdded: 0, title: '', artist: '', album: 'a'),
        songWith(id: 16, dateModified: 0, dateAdded: 0, title: '', artist: '', album: 'z'),
      ];
    });
    final Map<SortOrder, Map<SongSortFeature, List<int>>> testCases = {
      SortOrder.ascending: {
        SongSortFeature.dateModified: [2, 0, 3, 4, 9, 10, 11, 12, 13, 14, 15, 16, 5, 7, 6, 8, 1],
        SongSortFeature.dateAdded: [4, 0, 1, 2, 9, 10, 11, 12, 13, 14, 15, 16, 5, 7, 6, 8, 3],
        SongSortFeature.title: [2, 0, 3, 4, 9, 10, 11, 12, 13, 14, 15, 16, 1, 5, 7, 6, 8],
        SongSortFeature.artist: [0, 1, 2, 3, 4, 13, 14, 15, 16, 5, 7, 6, 8, 9, 11, 10, 12],
        SongSortFeature.album: [0, 1, 2, 3, 4, 9, 10, 11, 12, 5, 7, 6, 8, 13, 15, 14, 16],
      },
      SortOrder.descending: {
        SongSortFeature.dateModified: [1, 8, 6, 5, 7, 0, 3, 4, 9, 10, 11, 12, 13, 14, 15, 16, 2],
        SongSortFeature.dateAdded: [3, 8, 6, 5, 7, 0, 1, 2, 9, 10, 11, 12, 13, 14, 15, 16, 4],
        SongSortFeature.title: [8, 6, 5, 7, 1, 0, 3, 4, 9, 10, 11, 12, 13, 14, 15, 16, 2],
        SongSortFeature.artist: [12, 10, 9, 11, 8, 6, 5, 7, 0, 1, 2, 3, 4, 13, 14, 15, 16],
        SongSortFeature.album: [16, 14, 13, 15, 8, 6, 5, 7, 0, 1, 2, 3, 4, 9, 10, 11, 12],
      },
    };
    for (final entry in testCases.entries) {
      final sortOrder = entry.key;
      final featureTestCases = entry.value;
      for (final entry in featureTestCases.entries) {
        final feature = entry.key;
        final expectedContentList = entry.value;
        test('Sorts songs by ${feature.name} ${sortOrder.name}', () async {
          expect(
            songs.toList()..sort(SongSort(feature: feature, order: sortOrder).comparator),
            expectedContentList.map((i) => songs[i]).toList(),
          );
        });
      }
    }
  });

  group('Album sorting', () {
    late List<Album> albums;
    setUp(() {
      albums = [
        albumWith(id: 0, album: '', artist: '', lastYear: 0, firstYear: 0, numberOfSongs: 0),
        albumWith(id: 1, album: 'A', artist: '', lastYear: 0, firstYear: 0, numberOfSongs: 0),
        albumWith(id: 2, album: 'AA', artist: '', lastYear: 0, firstYear: 0, numberOfSongs: 0),
        albumWith(id: 3, album: 'a', artist: '', lastYear: 0, firstYear: 0, numberOfSongs: 0),
        albumWith(id: 4, album: 'z', artist: '', lastYear: 0, firstYear: 0, numberOfSongs: 0),
        albumWith(id: 5, album: '', artist: 'A', lastYear: 0, firstYear: 0, numberOfSongs: 0),
        albumWith(id: 6, album: '', artist: 'AA', lastYear: 0, firstYear: 0, numberOfSongs: 0),
        albumWith(id: 7, album: '', artist: 'a', lastYear: 0, firstYear: 0, numberOfSongs: 0),
        albumWith(id: 8, album: '', artist: 'z', lastYear: 0, firstYear: 0, numberOfSongs: 0),
        albumWith(id: 9, album: '', artist: '', lastYear: 1, firstYear: 0, numberOfSongs: 0),
        albumWith(id: 10, album: '', artist: '', lastYear: -1, firstYear: 0, numberOfSongs: 0),
        albumWith(id: 11, album: '', artist: '', lastYear: null, firstYear: 0, numberOfSongs: 0),
        albumWith(id: 12, album: '', artist: '', lastYear: null, firstYear: 1, numberOfSongs: 0),
        albumWith(id: 13, album: '', artist: '', lastYear: null, firstYear: -1, numberOfSongs: 0),
        albumWith(id: 14, album: '', artist: '', lastYear: null, firstYear: null, numberOfSongs: 0),
        albumWith(id: 15, album: '', artist: '', lastYear: 0, firstYear: 0, numberOfSongs: 1),
        albumWith(id: 16, album: '', artist: '', lastYear: 0, firstYear: 0, numberOfSongs: -1),
      ];
    });
    final Map<SortOrder, Map<AlbumSortFeature, List<int>>> testCases = {
      SortOrder.ascending: {
        AlbumSortFeature.title: [10, 13, 0, 5, 6, 7, 8, 11, 14, 15, 16, 9, 12, 1, 3, 2, 4],
        AlbumSortFeature.artist: [10, 13, 0, 1, 2, 3, 4, 11, 14, 15, 16, 9, 12, 5, 7, 6, 8],
        AlbumSortFeature.year: [10, 13, 0, 5, 6, 7, 8, 11, 14, 15, 16, 1, 3, 2, 4, 9, 12],
        AlbumSortFeature.numberOfSongs: [16, 10, 13, 0, 1, 2, 3, 4, 5, 6, 7, 8, 11, 14, 9, 12, 15],
      },
      SortOrder.descending: {
        AlbumSortFeature.title: [4, 2, 1, 3, 9, 12, 0, 5, 6, 7, 8, 11, 14, 15, 16, 10, 13],
        AlbumSortFeature.artist: [8, 6, 5, 7, 9, 12, 0, 1, 2, 3, 4, 11, 14, 15, 16, 10, 13],
        AlbumSortFeature.year: [9, 12, 4, 2, 1, 3, 0, 5, 6, 7, 8, 11, 14, 15, 16, 10, 13],
        AlbumSortFeature.numberOfSongs: [15, 9, 12, 0, 1, 2, 3, 4, 5, 6, 7, 8, 11, 14, 10, 13, 16],
      },
    };
    for (final entry in testCases.entries) {
      final sortOrder = entry.key;
      final featureTestCases = entry.value;
      for (final entry in featureTestCases.entries) {
        final feature = entry.key;
        final expectedContentList = entry.value;
        test('Sorts albums by ${feature.name} ${sortOrder.name}', () async {
          expect(
            albums.toList()..sort(AlbumSort(feature: feature, order: sortOrder).comparator),
            expectedContentList.map((i) => albums[i]).toList(),
          );
        });
      }
    }
  });

  group('Playlist sorting', () {
    late List<Playlist> playlists;
    setUp(() {
      playlists = [
        playlistWith(id: 0, name: '', dateModified: 0, dateAdded: 0),
        playlistWith(id: 1, name: 'A', dateModified: 0, dateAdded: 0),
        playlistWith(id: 2, name: 'AA', dateModified: 0, dateAdded: 0),
        playlistWith(id: 3, name: 'a', dateModified: 0, dateAdded: 0),
        playlistWith(id: 4, name: 'z', dateModified: 0, dateAdded: 0),
        playlistWith(id: 5, name: '', dateModified: 1, dateAdded: 0),
        playlistWith(id: 6, name: '', dateModified: -1, dateAdded: 0),
        playlistWith(id: 7, name: '', dateModified: 0, dateAdded: 1),
        playlistWith(id: 8, name: '', dateModified: 0, dateAdded: -1),
      ];
    });
    final Map<SortOrder, Map<PlaylistSortFeature, List<int>>> testCases = {
      SortOrder.ascending: {
        PlaylistSortFeature.dateModified: [6, 0, 7, 8, 1, 3, 2, 4, 5],
        PlaylistSortFeature.dateAdded: [8, 0, 5, 6, 1, 3, 2, 4, 7],
        PlaylistSortFeature.name: [6, 0, 7, 8, 5, 1, 3, 2, 4],
      },
      SortOrder.descending: {
        PlaylistSortFeature.dateModified: [5, 4, 2, 1, 3, 0, 7, 8, 6],
        PlaylistSortFeature.dateAdded: [7, 4, 2, 1, 3, 0, 5, 6, 8],
        PlaylistSortFeature.name: [4, 2, 1, 3, 5, 0, 7, 8, 6],
      },
    };
    for (final entry in testCases.entries) {
      final sortOrder = entry.key;
      final featureTestCases = entry.value;
      for (final entry in featureTestCases.entries) {
        final feature = entry.key;
        final expectedContentList = entry.value;
        test('Sorts playlists by ${feature.name} ${sortOrder.name}', () async {
          expect(
            playlists.toList()..sort(PlaylistSort(feature: feature, order: sortOrder).comparator),
            expectedContentList.map((i) => playlists[i]).toList(),
          );
        });
      }
    }
  });

  group('Artist sorting', () {
    late List<Artist> artists;
    setUp(() {
      artists = [
        artistWith(id: 0, artist: '', numberOfAlbums: 0, numberOfTracks: 0),
        artistWith(id: 1, artist: 'A', numberOfAlbums: 0, numberOfTracks: 0),
        artistWith(id: 2, artist: 'AA', numberOfAlbums: 0, numberOfTracks: 0),
        artistWith(id: 3, artist: 'a', numberOfAlbums: 0, numberOfTracks: 0),
        artistWith(id: 4, artist: 'z', numberOfAlbums: 0, numberOfTracks: 0),
        artistWith(id: 5, artist: '', numberOfAlbums: 1, numberOfTracks: 0),
        artistWith(id: 6, artist: '', numberOfAlbums: -1, numberOfTracks: 0),
        artistWith(id: 7, artist: '', numberOfAlbums: 0, numberOfTracks: 1),
        artistWith(id: 8, artist: '', numberOfAlbums: 0, numberOfTracks: -1),
      ];
    });
    final Map<SortOrder, Map<ArtistSortFeature, List<int>>> testCases = {
      SortOrder.ascending: {
        ArtistSortFeature.name: [8, 0, 5, 6, 7, 1, 3, 2, 4],
        ArtistSortFeature.numberOfAlbums: [6, 0, 7, 8, 1, 3, 2, 4, 5],
        ArtistSortFeature.numberOfTracks: [8, 0, 5, 6, 1, 3, 2, 4, 7],
      },
      SortOrder.descending: {
        ArtistSortFeature.name: [4, 2, 1, 3, 7, 0, 5, 6, 8],
        ArtistSortFeature.numberOfAlbums: [5, 4, 2, 1, 3, 0, 7, 8, 6],
        ArtistSortFeature.numberOfTracks: [7, 4, 2, 1, 3, 0, 5, 6, 8],
      },
    };
    for (final entry in testCases.entries) {
      final sortOrder = entry.key;
      final featureTestCases = entry.value;
      for (final entry in featureTestCases.entries) {
        final feature = entry.key;
        final expectedContentList = entry.value;
        test('Sorts artists by ${feature.name} ${sortOrder.name}', () async {
          expect(
            artists.toList()..sort(ArtistSort(feature: feature, order: sortOrder).comparator),
            expectedContentList.map((i) => artists[i]).toList(),
          );
        });
      }
    }
  });
}
