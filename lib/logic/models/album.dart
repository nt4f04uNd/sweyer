/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class Album extends PersistentQueue {
  final String album;
  final String albumArt;
  final String artist;
  final int artistId;
  final int firstYear;
  final int? lastYear;
  final int numberOfSongs;

  /// An icon for this content type.
  static const icon = Icons.album_rounded;

  @override
  String get title => album;

  /// Returns songs that belong to this album.
  @override
  List<Song> get songs {
    return ContentControl.state.allSongs.songs
      .fold<List<Song>>([], (prev, el) {
        if (el.albumId == id) {
          prev.add(el.copyWith(origin: this));
        }
        return prev;
      })
      .toList();
  }

  @override
  int get length => numberOfSongs;

  @override
  bool get playable => true;

  /// Gets album normalized year.
  int get year {
    return lastYear == null || lastYear! < 1000
      ? DateTime.now().year
      : lastYear!;
  }

  Song get firstSong {
    return ContentControl.state.allSongs.songs.firstWhere((el) => el.albumId == id);
  }

  /// Returns string in format `album name • year`. 
  String get nameDotYear {
    return ContentUtils.appendYearWithDot(album, year);
  }

  /// Returns string in format `Album • year`. 
  String albumDotName(AppLocalizations l10n) {
    return ContentUtils.appendYearWithDot(l10n.album, year);
  }

  /// Returns the album artist.
  Artist getArtist() => ContentControl.state.artists.firstWhere((el) => el.id == artistId);

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

  @override
  AlbumCopyWith get copyWith => _AlbumCopyWith(this);

  @override
  MediaItem toMediaItem() {
    return MediaItem(
      id: id.toString(),
      album: null,
      defaultArtBlendColor: ThemeControl.colorForBlend.value,
      artUri: null,
      title: album,
      artist: ContentUtils.localizedArtist(artist, staticl10n),
      genre: null,
      rating: null,
      extras: null,
      playable: false,
    );
  }

  @override
  SongOriginEntry toSongOriginEntry() {
    return SongOriginEntry(
      type: SongOriginType.album,
      id: id,
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

  @override
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

/// The `copyWith` function type for [Album].
abstract class AlbumCopyWith {
  Album call({
    int id,
    String album,
    String albumArt,
    String artist,
    int artistId,
    int firstYear,
    int? lastYear,
    int numberOfSongs,
  });
}

/// The implementation of [Album]'s `copyWith` function allowing
/// parameters to be explicitly set to null.
class _AlbumCopyWith extends AlbumCopyWith {
  static const _undefined = Object();

  /// The object this function applies to.
  final Album value;

  _AlbumCopyWith(this.value);

  @override
  Album call({
    Object id = _undefined,
    Object album = _undefined,
    Object albumArt = _undefined,
    Object artist = _undefined,
    Object artistId = _undefined,
    Object firstYear = _undefined,
    Object? lastYear = _undefined,
    Object numberOfSongs = _undefined,
  }) {
    return Album(
      id: id == _undefined ? value.id : id as int,
      album: album == _undefined ? value.album : album as String,
      albumArt: albumArt == _undefined ? value.albumArt : albumArt as String,
      artist: artist == _undefined ? value.artist : artist as String,
      artistId: artistId == _undefined ? value.artistId : artistId as int,
      firstYear: firstYear == _undefined ? value.firstYear : firstYear as int,
      lastYear: lastYear == _undefined ? value.lastYear : lastYear as int?,
      numberOfSongs: numberOfSongs == _undefined ? value.numberOfSongs : numberOfSongs as int,
    );
  }
}
