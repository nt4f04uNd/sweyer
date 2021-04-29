/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:audio_service/audio_service.dart';
import 'package:sweyer/sweyer.dart';

class Song extends Content {
  @override
  int id;
  /// Album name.
  final String? album;
  final int? albumId;
  final String artist;
  final int artistId;
  // TODO: vodoo shenanigans on android versions with this (and other places where i can)
  final String? genre;
  final int? genreId;
  final String title;
  /// The track number of this song on the album, if any.
  final String? track;
  final int dateAdded;
  final int dateModified;
  /// Duration in milliseconds
  final int duration;
  final int size;
  final String? data;

  /// Indicates that song is pending, and still being inserted by its owner.
  ///
  /// Available starting from Android Q, in lower is always `false`.
  final bool? isPending;

  /// Indicates that user marked this song as favorite.
  ///
  /// In native only available starting from Android R, below this favorite logic
  /// is implemented in app itself.
  final bool? isFavorite;

  /// Generation number at which metadata for this media item was first inserted.
  /// 
  /// Available starting from Android R, in lower is `null`.
  final int? generationAdded;

  /// Generation number at which metadata for this media item was last changed.
  /// 
  /// Available starting from Android R, in lower is `null`.
  final int? generationModified;

  /// The [PersistentQueue] this song comes from.
  /// This will help determining where the song comes from to show [CurrentIndicator]s.
  PersistentQueue? origin;

  @override
  List<Object?> get props => [id];

  int get sourceId => getSourceId(id);
  static int getSourceId(int id) {
    return id < 0 ? ContentControl.state.idMap[id.toString()]! : id;
  }

  /// Returns the album this song belongs to (if any).
  Album? getAlbum() => albumId == null ? null : ContentControl.state.albums[albumId!];

  /// Returns the album art for this (if any).
  String? get albumArt => getAlbum()?.albumArt;

  /// Needed to display [ContentArtSource] and passed to [ContentArtSource].
  String get contentUri => 'content://media/external/audio/media/$sourceId';

  Song({
    required this.id,
    required this.album,
    required this.albumId,
    required this.artist,
    required this.artistId,
    required this.genre,
    required this.genreId,
    required this.title,
    required this.track,
    required this.dateAdded,
    required this.dateModified,
    required this.duration,
    required this.size,
    required this.data,
    required this.isPending,
    required this.isFavorite,
    required this.generationAdded,
    required this.generationModified,
    this.origin,
  });

  Song copyWith({
    int? id,
    String? album,
    int? albumId,
    String? artist,
    int? artistId,
    String? genre,
    int? genreId,
    String? title,
    String? track,
    int? dateAdded,
    int? dateModified,
    int? duration,
    int? size,
    String? data,
    String? bucketDisplayName,
    int? bucketId,
    int? generationAdded,
    int? generationModified,
    bool? isFavorite,
    bool? isPending,
    PersistentQueue? origin,
  }) {
    return Song(
      id: id ?? this.id,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      genre: genre ?? this.genre,
      genreId: genreId ?? this.genreId,
      title: title ?? this.title,
      track: track ?? this.track,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      data: data ?? this.data,
      isPending: isPending ?? this.isPending,
      isFavorite: isFavorite ?? this.isFavorite,
      generationAdded: generationAdded ?? this.generationAdded,
      generationModified: generationModified ?? this.generationModified,
      origin: origin ?? this.origin,
    );
  }

  MediaItem toMediaItem() {
    return MediaItem(
      id: sourceId.toString(),
      uri: contentUri,
      defaultArtBlendColor: ThemeControl.colorForBlend.value,
      artUri: null,
      album: getAlbum()?.album,
      title: title,
      artist: formatArtist(artist, staticl10n),
      genre: genre,
      duration: Duration(milliseconds: duration),
      playable: true,
      rating: null,
      extras: null,
    );
  }

  factory Song.fromMap(Map map) {
    return Song(
      id: map['id'] as int,
      album: map['album'] as String?,
      albumId: map['albumId'] as int?,
      artist: map['artist'] as String,
      artistId: map['artistId'] as int,
      genre: map['genre'] as String?,
      genreId: map['genreId'] as int?,
      title: map['title'] as String,
      track: map['track'] as String?,
      dateAdded: map['dateAdded'] as int,
      dateModified: map['dateModified'] as int,
      duration: map['duration'] as int,
      size: map['size'] as int,
      data: map['data'] as String?,
      isPending: map['isPending'] as bool?,
      isFavorite: map['isFavorite'] as bool?,
      generationAdded: map['generationAdded'] as int?,
      generationModified: map['generationModified'] as int?,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
      'id': id,
      'album': album,
      'albumId': albumId,
      'artist': artist,
      'artistId': artistId,
      'genre': genre,
      'genreId': genreId,
      'title': title,
      'track': track,
      'dateAdded': dateAdded,
      'dateModified': dateModified,
      'duration': duration,
      'size': size,
      'data': data,
      'isPending': isPending,
      'isFavorite': isFavorite,
      'generationAdded': generationAdded,
      'generationModified': generationModified,
    };
}
