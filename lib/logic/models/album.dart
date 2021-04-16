/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class Album extends PersistentQueue {
  /// Album name.
  final String album;
  final String albumArt;
  final String artist;
  final int artistId;
  final int firstYear;
  final int lastYear;
  final int numberOfSongs;

  /// Gets album normalized year.
  int get year {
    return lastYear == null || lastYear < 1000
      ? DateTime.now().year
      : lastYear;
  }

  /// Returns songs that belong to this album.
  @override
  List<Song> get songs =>
      ContentControl.state.allSongs.songs.fold<List<Song>>([], (prev, el) {
        if (el.albumId == id) {
          prev.add(el.copyWith());
        }
        return prev;
      }).toList();

  @override
  int get length => numberOfSongs;

  Album({
    @required int id,
    @required this.album,
    @required this.albumArt,
    @required this.artist,
    @required this.artistId,
    @required this.firstYear,
    @required this.lastYear,
    @required this.numberOfSongs,
  }) : super(id: id);

  MediaItem toMediaItem() {
    return MediaItem(
      id: id.toString(),
      album: null,
      defaultArtBlendColor: ThemeControl.colorForBlend.value,
      artUri: albumArt == null ? null : Uri.file(albumArt),
      title: album,
      artist: formatArtist(artist, staticl10n),
      genre: null, // TODO: GENRE
      rating: null,
      extras: null,
    );
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as int,
      album: json['album'] as String,
      albumArt: json['albumArt'] as String,
      artist: json['artist'] as String,
      artistId: json['artistId'] as int,
      firstYear: json['firstYear'] as int,
      lastYear: json['lastYear'] as int,
      numberOfSongs: json['numberOfSongs'] as int,
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
