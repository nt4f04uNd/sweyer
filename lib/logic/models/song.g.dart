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

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
      'id': instance.id,
      'album': instance.album,
      'albumId': instance.albumId,
      'artist': instance.artist,
      'artistId': instance.artistId,
      'title': instance.title,
      'track': instance.track,
      'dateAdded': instance.dateAdded,
      'dateModified': instance.dateModified,
      'duration': instance.duration,
      'size': instance.size,
      'data': instance.data,
    };
