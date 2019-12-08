// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Song _$SongFromJson(Map<String, dynamic> json) {
  return Song(
    id: json['id'] as int,
    artist: json["artist"] as String,
    album: json['album'] as String,
    albumArtUri: json['albumArtUri'] as String,
    title: json["title"] as String,
    trackUri: json['trackUri'] as String,
    duration: json['duration'] as int,
    dateModified: json['dateModified'] as int,
  );
}

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
      'id': instance.id,
      "artist": instance.artist,
      'album': instance.album,
      'albumArtUri': instance.albumArtUri,
      "title": instance.title,
      'trackUri': instance.trackUri,
      'duration': instance.duration,
      'dateModified': instance.dateModified,
    };
