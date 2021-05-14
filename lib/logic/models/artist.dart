/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';

class Artist extends Content {
  @override
  final int id;
  final String artist;
  final int numberOfAlbums;
  final int numberOfTracks;

  @override
  List<Object> get props => [id];

  /// Returns songs for this artst.
  List<Song> get songs {
    return ContentControl.state.allSongs.songs.fold<List<Song>>([], (prev, el) {
      if (el.artistId == id) {
        prev.add(el.copyWith());
      }
      return prev;
    }).toList();
  }

  /// Returns albums for this artst.
  List<Album> get albums {
    return ContentControl.state.albums.values
      .where((el) => el.artistId == id)
      .toList();
  }

  const Artist({
    required this.id,
    required this.artist,
    required this.numberOfAlbums,
    required this.numberOfTracks,
  });

  ArtistCopyWith get copyWith => _ArtistCopyWith(this);

  factory Artist.fromMap(Map map) {
    return Artist(
      id: map['id'] as int,
      artist: map['artist'] as String,
      numberOfAlbums: map['numberOfAlbums'] as int,
      numberOfTracks: map['numberOfTracks'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'artist': artist,
    'numberOfAlbums': numberOfAlbums,
    'numberOfTracks': numberOfTracks,
  };
}

/// The `copyWith` function type for [Artist].
abstract class ArtistCopyWith {
  Artist call({
    int id,
    String artist,
    int numberOfAlbums,
    int numberOfTracks,
  });
}

/// The implementation of [Artist]'s `copyWith` function allowing
/// parameters to be explicitly set to null.
class _ArtistCopyWith extends ArtistCopyWith {
  static const _undefined = Object();

  /// The object this function applies to.
  final Artist value;

  _ArtistCopyWith(this.value);

  @override
  Artist call({
    Object id = _undefined,
    Object artist = _undefined,
    Object numberOfAlbums = _undefined,
    Object numberOfTracks = _undefined,
  }) {
    return Artist(
      id: id == _undefined ? value.id : id as int,
      artist: artist == _undefined ? value.artist : artist as String,
      numberOfAlbums: numberOfAlbums == _undefined ? value.numberOfAlbums : numberOfAlbums as int,
      numberOfTracks: numberOfTracks == _undefined ? value.numberOfTracks : numberOfTracks as int,
    );
  }
}
