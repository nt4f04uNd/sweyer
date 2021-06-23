/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:audio_service/audio_service.dart';
import 'package:sweyer/sweyer.dart';
import 'package:equatable/equatable.dart';
import 'package:collection/collection.dart';

/// Represents some content in the app (songs, album, etc).
///
/// Each type of content have an approprate [Sort]s implemented.
///
/// See also:
/// * [ContentType], a list of all content types.
abstract class Content with EquatableMixin {
  const Content();

  /// A unique ID of the content.
  int get id;

  /// Title the content.
  String get title;

  /// Creates a copy of this content with the given fields replaced with new values.
  dynamic get copyWith;

  /// Converts the content to media item.
  MediaItem toMediaItem();

  /// Converts the content to map.  
  Map<String, dynamic> toMap();

  /// Enumerates all the types of content (derived from this class).
  static List<Type> enumerate() => [Song, Album, Playlist, Artist];
}

/// Content that can contain other songs inside it.
/// 
/// This class represents not duplicating, a.k.a. `true source` song origins.
/// For origins to allow duplication, see a protocol in [DuplicatingSongOriginMixin].
/// 
/// Examples:
///  * [Album]
///  * [Artist]
abstract class SongOrigin extends Content {
  const SongOrigin();

  /// List of songs.
  List<Song> get songs;

  /// Length of the queue.
  int get length;

  /// Used to serialize the origin.
  SongOriginEntry toSongOriginEntry();

  /// Creates origin from map.
  static SongOrigin? originFromMap(Map map) {
    final originEntry = SongOriginEntry.fromMap(map);
    if (originEntry == null)
      return null;
    switch (originEntry.type) {
      case SongOriginType.album:
        return ContentControl.state.albums[originEntry.id];
      case SongOriginType.playlist:
        return ContentControl.state.playlists.firstWhereOrNull((el) => el.id == originEntry.id);
      case SongOriginType.artist:
        return ContentControl.state.artists.firstWhereOrNull((el) => el.id == originEntry.id);
      default:
        throw UnimplementedError();
    }
  }
}

/// Song origin that allows duplication within the [songs].
/// 
/// Classes that are mixed in with this should in [songs] getter:
/// * create and fill the [idMap]
/// * set the [Song.idMap] and [Song.origin]
/// * call [debugAssertSongsAreValid] at the ennd of the getter, to check
///   that everything is set correctly.
///
/// Examples:
///  * [Playlist]
mixin DuplicatingSongOriginMixin on SongOrigin {
  /// Must be created and filled automatically each time the [songs] is called.
  Map<String, int>? get idMap;

  /// Ensures that [idMap] is initialized and receieved [Song.idMap]
  /// and the [Song.origin].
  bool debugAssertSongsAreValid(List<Song> songs) {
    // Check that new valid idMap is created.
    // ignore: unused_local_variable
    final value = idMap;

    for (final song in songs) {
      if (song.origin != this || song.idMap != idMap)
        return false;
    }
    return true;
  }
}

/// Model used to serialize song origin type.
class SongOriginType {
  const SongOriginType._(this._value);
  final String _value;

  static const album = SongOriginType._('album');
  static const playlist = SongOriginType._('playlist');
  static const artist = SongOriginType._('artist');

  static List<SongOriginType> get values => const [
    album, playlist, artist,
  ];
}

/// Model used to serialize song origin.
class SongOriginEntry {
  SongOriginEntry({
    required this.type,
    required this.id,
  });

  SongOriginType type;
  int id;

  /// Will return null of map doesn't contain origin.
  static SongOriginEntry? fromMap(Map map) {
    final rawType = map['origin_type'];
    if (rawType == null)
      return null;
    final id = map['origin_id'];
    assert(id != null);
    return SongOriginEntry(
      type: SongOriginType.values.firstWhere((el) => el._value == rawType),
      id: id,
    );
  }

  Map<String, dynamic> toMap() => {
    'origin_type': type._value,
    'origin_id': id,
  };
}
