// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Album _$AlbumFromJson(Map<String, dynamic> json) {
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

Map<String, dynamic> _$AlbumToJson(Album instance) => <String, dynamic>{
      'id': instance.id,
      'album': instance.album,
      'albumArt': instance.albumArt,
      'artist': instance.artist,
      'artistId': instance.artistId,
      'firstYear': instance.firstYear,
      'lastYear': instance.lastYear,
      'numberOfSongs': instance.numberOfSongs,
    };
