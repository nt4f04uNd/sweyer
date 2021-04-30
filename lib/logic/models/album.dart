/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:audio_service/audio_service.dart';
import 'package:sweyer/sweyer.dart';

class Album extends PersistentQueue {
  final String album;
  final String albumArt;
  final String artist;
  final int artistId;
  final int firstYear;
  final int? lastYear;
  final int numberOfSongs;

  @override
  String get title => album;

  /// Returns songs that belong to this album.
  @override
  List<Song> get songs {
    return ContentControl.state.allSongs.songs
      .fold<List<Song>>([], (prev, el) {
        if (el.albumId == id) {
          prev.add(el.copyWith());
        }
        return prev;
      })
      .toList();
  }

  @override
  int get length => numberOfSongs;

  /// Gets album normalized year.
  int get year {
    return lastYear == null || lastYear! < 1000
      ? DateTime.now().year
      : lastYear!;
  }


  Song get firstSong {
    return ContentControl.state.allSongs.songs.firstWhere((el) => el.albumId == id);
  }

  const Album({
    required int id,
    required this.album,
    required this.albumArt,
    required this.artist,
    required this.artistId,
    required this.firstYear,
    required this.lastYear,
    required this.numberOfSongs,
  }) : super(id: id);

  MediaItem toMediaItem() {
    return MediaItem(
      id: id.toString(),
      album: null,
      defaultArtBlendColor: ThemeControl.colorForBlend.value,
      artUri: null,
      title: album,
      artist: formatArtist(artist, staticl10n),
      genre: null,
      rating: null,
      extras: null,
      playable: false,
    );
  }

  factory Album.fromMap(Map map) {
    return Album(
      id: map['id'] as int,
      album: map['album'] as String,
      albumArt: map['albumArt'] as String,
      artist: map['artist'] as String,
      artistId: map['artistId'] as int,
      firstYear: map['firstYear'] as int,
      lastYear: map['lastYear'] as int,
      numberOfSongs: map['numberOfSongs'] as int,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
      'id': id,
      'album': album,
      'albumArt': albumArt,
      'artist': artist,
      'artistId': artistId,
      'firstYear': firstYear,
      'lastYear': lastYear,
      'numberOfSongs': numberOfSongs,
    };
}
