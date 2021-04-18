/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

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
  /// This will help determining where the song comes from to show [CurrentIndicator]s.
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


  String get contentUri => 'content://media/external/audio/media/$sourceId';

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

  MediaItem toMediaItem() {
    return MediaItem(
      id: sourceId.toString(),
      uri: contentUri,
      defaultArtBlendColor: ThemeControl.colorForBlend.value,
      // artUri: albumArt == null ? null : Uri(scheme: '', path: albumArt),
      artUri: null,
      album: getAlbum().album,
      title: title,
      artist: formatArtist(artist, staticl10n),
      genre: null, // TODO: GENRE
      duration: Duration(milliseconds: duration),
      playable: true,
      rating: null,
      extras: null,
    );
  }

  factory Song.fromMap(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as int,
      album: json['album'] as String,
      albumId: json['albumId'] as int,
      artist: json['artist'] as String,
      artistId: json['artistId'] as int,
      title: json['title'] as String,
      track: json['track'] as String,
      dateAdded: json['dateAdded'] as int,
      dateModified: json['dateModified'] as int,
      duration: json['duration'] as int,
      size: json['size'] as int,
      data: json['data'] as String,
    );
  }
  Map<String, dynamic> toMap() => <String, dynamic>{
      'id': id,
      'album': album,
      'albumId': albumId,
      'artist': artist,
      'artistId': artistId,
      'title': title,
      'track': track,
      'dateAdded': dateAdded,
      'dateModified': dateModified,
      'duration': duration,
      'size': size,
      'data': data,
    };
}
