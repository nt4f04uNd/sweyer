
/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Song _$SongFromJson(Map<String, dynamic> json) {
  return Song(
    id: json['id'] as int,
    album: json['album'] as String,
    albumId: json['albumId'] as int,
    albumKey: json['albumKey'] as int,
    artist: json['artist'] as String,
    artistId: json['artistId'] as int,
    artistKey: json['artistKey'] as int,
    title: json['title'] as String,
    titleKey: json['titleKey'] as int,
    dateAdded: json['dateAdded'] as int,
    dateModified: json['dateModified'] as int,
    duration: json['duration'] as int,
    size: json['size'] as int,
    albumArtUri: json['albumArtUri'] as String,
  );
}

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
      'id': instance.id,
      'album': instance.album,
      'albumId': instance.albumId,
      'albumKey': instance.albumKey,
      'artist': instance.artist,
      'artistId': instance.artistId,
      'artistKey': instance.artistKey,
      'title': instance.title,
      'titleKey': instance.titleKey,
      'dateAdded': instance.dateAdded,
      'dateModified': instance.dateModified,
      'duration': instance.duration,
      'size': instance.size,
      'albumArtUri': instance.albumArtUri,
    };
