/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sweyer/sweyer.dart';

/// This allows the [Song] class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'song.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
// ignore: must_be_immutable
class Song extends Content with EquatableMixin {
  @override
  int id;

  /// Album name.
  final String album;
  final int albumId;
  final String artist;
  final int artistId;
  final String title;

  /// The track number of this song on the album, if any.
  final String track;
  final int dateAdded;
  final int dateModified;

  /// Duration in milliseconds
  final int duration;
  final int size;
  final String data;

  /// The [PersistentQueue] this song comes from.
  /// This will help determining where the song comes from and allows to show [CurrentIndicator] for [PersistenQueue]s.
  ///
  /// This is not stored in any way.
  PersistentQueue origin;

  @override
  List<Object> get props => [id];

  int get sourceId => getSourceId(id);
  static int getSourceId(int id) {
    return id < 0 ? ContentControl.state.idMap[id.toString()] : id;
  }

  /// Returns the album this song belongs to (if any).
  Album getAlbum() => albumId == null ? null : ContentControl.state.albums[albumId];

  /// Returns the album art for this (if any).
  String get albumArt => getAlbum()?.albumArt;

  Song({
    @required this.id,
    @required this.album,
    @required this.albumId,
    @required this.artist,
    @required this.artistId,
    @required this.title,
    @required this.track,
    @required this.dateAdded,
    @required this.dateModified,
    @required this.duration,
    @required this.size,
    @required this.data,
    this.origin,
  });

  Song copyWith({
    int id,
    String album,
    int albumId,
    String artist,
    int artistId,
    String title,
    String track,
    int dateAdded,
    int dateModified,
    int duration,
    int size,
    String data,
    PersistentQueue origin,
  }) {
    return Song(
      id: id ?? this.id,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      title: title ?? this.title,
      track: track ?? this.track,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      data: data ?? this.data,
      origin: origin ?? this.origin,
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
  Map<String, dynamic> toJson() => _$SongToJson(this);

  MediaItem toMediaItem() {
    return MediaItem(
      id: sourceId.toString(),
      album: getAlbum().album,
      title: title,
       // TODO: use displaySubtitle and pass raw artist here when https://github.com/ryanheise/audio_service/issues/651 is resolved
      artist: formatArtist(artist, staticl10n),
      genre: null, // TODO: GENRE
      duration: Duration(milliseconds: duration),
      artUri: Uri.file(albumArt ?? ContentControl.state.defaultAlbumArtPath),
      playable: true,
      // displaySubtitle: formatArtist(artist, staticl10n),
      rating: null,
      extras: null,
    );
  }
}
