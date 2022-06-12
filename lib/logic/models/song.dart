import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Represends a song.
///
/// Songs are always playable, trashed or pending songs on Android Q are excluded.
class Song extends Content {
  /// This is the main song ID used for comparisons.
  ///
  /// Initially, this is equal to the source song [sourceId], but if song is
  /// found to be duplicated within some queue and this queue is currently
  /// being processed in some way (for example, played), it might be altered
  /// with a negative value.
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
  @override
  final String title;

  /// The track number of this song on the album, if any.
  final String? track;
  final int dateAdded;
  final int dateModified;

  /// Duration in milliseconds
  final int duration;
  final int size;
  final String? data;

  /// Whether the content was marked as favorite in MediaStore.
  ///
  /// Only available starting from Android R (30), below this is always `null`.
  ///
  /// See also:
  ///  * [isFavorite] getter
  final bool? isFavoriteInMediaStore;

  /// Generation number at which metadata for this media item was first inserted.
  ///
  /// Available starting from Android R, in lower is `null`.
  final int? generationAdded;

  /// Generation number at which metadata for this media item was last changed.
  ///
  /// Available starting from Android R, in lower is `null`.
  final int? generationModified;

  /// The origin this song comes from.
  ///
  /// Particularly, this will help determining where the song comes from to show [CurrentIndicator]s.
  ///
  /// Set by [SongOrigin.songs] getters.
  SongOrigin? origin;

  /// Index of a duplicate song within its duplicates in its queue.
  ///
  /// For example if there are 4 duplicates a song in the queue,
  /// and the song is inserted to the end, its duplication index will be
  /// last `index + 1`, i.e `3 + 1 = 4`.
  ///
  /// Set by [DuplicatingSongOriginMixin]s.
  int? duplicationIndex;

  /// A supplementary ID map, inserted by origins that allow duplication,
  /// like [Playlist].
  ///
  /// Not copied with [copyWith].
  IdMap? idMap;

  /// An icon for this content type.
  static const icon = Icons.music_note_rounded;

  @override
  List<Object?> get props => [id];

  /// Returns source song ID.
  int get sourceId => ContentUtils.getSourceId(
        id,
        origin: origin,
        idMap: idMap,
      );

  /// Returns the song artist.
  Artist getArtist() => ContentControl.instance.state.artists.firstWhere((el) => el.id == artistId);

  /// Returns the album this song belongs to (if any).
  Album? getAlbum() => albumId == null ? null : ContentControl.instance.state.albums[albumId!];

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
    required this.isFavoriteInMediaStore,
    required this.generationAdded,
    required this.generationModified,
    this.duplicationIndex,
    this.origin,
  });

  @override
  SongCopyWith get copyWith => _SongCopyWith(this);

  @override
  MediaItem toMediaItem() {
    return MediaItem(
      id: sourceId.toString(),
      uri: contentUri,
      defaultArtBlendColor: ThemeControl.instance.colorForBlend.value,
      artUri: null,
      album: getAlbum()?.album,
      title: title,
      artist: ContentUtils.localizedArtist(artist, staticl10n),
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
      isFavoriteInMediaStore: map['isFavoriteInMediaStore'] as bool?,
      generationAdded: map['generationAdded'] as int?,
      generationModified: map['generationModified'] as int?,
    );
  }

  @override
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
        'isFavoriteInMediaStore': isFavoriteInMediaStore,
        'generationAdded': generationAdded,
        'generationModified': generationModified,
      };
}

/// The `copyWith` function type for [Song].
abstract class SongCopyWith {
  Song call({
    int id,
    String? album,
    int? albumId,
    String artist,
    int artistId,
    String? genre,
    int? genreId,
    String title,
    String? track,
    int dateAdded,
    int dateModified,
    int duration,
    int size,
    String? data,
    bool? isFavoriteInMediaStore,
    int? generationAdded,
    int? generationModified,
    int? duplicationIndex,
    SongOrigin? origin,
  });
}

/// The implementation of [Song]'s `copyWith` function allowing
/// parameters to be explicitly set to null.
class _SongCopyWith extends SongCopyWith {
  static const _undefined = Object();

  /// The object this function applies to.
  final Song value;

  _SongCopyWith(this.value);

  @override
  Song call({
    Object id = _undefined,
    Object? album = _undefined,
    Object? albumId = _undefined,
    Object artist = _undefined,
    Object artistId = _undefined,
    Object? genre = _undefined,
    Object? genreId = _undefined,
    Object title = _undefined,
    Object? track = _undefined,
    Object dateAdded = _undefined,
    Object dateModified = _undefined,
    Object duration = _undefined,
    Object size = _undefined,
    Object? data = _undefined,
    Object? isFavoriteInMediaStore = _undefined,
    Object? generationAdded = _undefined,
    Object? generationModified = _undefined,
    Object? duplicationIndex = _undefined,
    Object? origin = _undefined,
  }) {
    return Song(
      id: id == _undefined ? value.id : id as int,
      album: album == _undefined ? value.album : album as String?,
      albumId: albumId == _undefined ? value.albumId : albumId as int?,
      artist: artist == _undefined ? value.artist : artist as String,
      artistId: artistId == _undefined ? value.artistId : artistId as int,
      genre: genre == _undefined ? value.genre : genre as String?,
      genreId: genreId == _undefined ? value.genreId : genreId as int?,
      title: title == _undefined ? value.title : title as String,
      track: track == _undefined ? value.track : track as String?,
      dateAdded: dateAdded == _undefined ? value.dateAdded : dateAdded as int,
      dateModified: dateModified == _undefined ? value.dateModified : dateModified as int,
      duration: duration == _undefined ? value.duration : duration as int,
      size: size == _undefined ? value.size : size as int,
      data: data == _undefined ? value.data : data as String?,
      isFavoriteInMediaStore:
          isFavoriteInMediaStore == _undefined ? value.isFavoriteInMediaStore : isFavoriteInMediaStore as bool?,
      generationAdded: generationAdded == _undefined ? value.generationAdded : generationAdded as int?,
      generationModified: generationModified == _undefined ? value.generationModified : generationModified as int?,
      duplicationIndex: duplicationIndex == _undefined ? value.duplicationIndex : duplicationIndex as int?,
      origin: origin == _undefined ? value.origin : origin as SongOrigin?,
    );
  }
}
