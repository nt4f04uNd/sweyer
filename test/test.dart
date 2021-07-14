/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';

final _testSong = Song(
  id: 0,
  album: 'album',
  albumId: 0,
  artist: 'artist',
  artistId: 0,
  genre: 'genre',
  genreId: 0,
  title: 'title',
  track: 'track',
  dateAdded: 0,
  dateModified: 0,
  duration: 0,
  size: 0,
  data: 'data_data_data_data_data_data_data_data',
  isFavorite: false,
  generationAdded: 0,
  generationModified: 0,
  origin: _testAlbum,
  duplicationIndex: 0,
);

const _testAlbum = Album(
  id: 0,
  album: 'album',
  albumArt: 'albumArt_albumArt_albumArt',
  artist: 'artist',
  artistId: 0,
  firstYear: 2000,
  lastYear: 2000,
  numberOfSongs: 1000,
);

const _testArtist = Artist(
  id: 0,
  artist: 'artist',
  numberOfAlbums: 1, 
  numberOfTracks: 1, 
);

SongCopyWith songWith = _testSong.copyWith;
AlbumCopyWith albumWith = _testAlbum.copyWith;
ArtistCopyWith artistWith = _testArtist.copyWith;
