/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sweyer/sweyer.dart';

part 'album.g.dart';

@JsonSerializable()
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

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
  Map<String, dynamic> toJson() => _$AlbumToJson(this);

  MediaItem toMediaItem() {
    return MediaItem(
      id: id.toString(),
      album: null,
      title: album,
       // TODO: use displaySubtitle and pass raw artist here when https://github.com/ryanheise/audio_service/issues/651 is resolved
      artist: formatArtist(artist, staticl10n),
      genre: null, // TODO: GENRE
      // duration: Duration(milliseconds: duration),
      artUri: Uri.file(albumArt ?? ContentControl.state.defaultAlbumArtPath),
      // displaySubtitle: formatArtist(artist, staticl10n),
      rating: null,
      extras: null,
    );
  }
}
