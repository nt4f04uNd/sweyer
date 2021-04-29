/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

// @dart = 2.12

import 'package:sweyer/sweyer.dart';

class Playlist extends PersistentQueue {
  final String data;
  final int dateAdded;
  final int dateModified;
  final String name;
  final List<int> songIds;

  @override
  String get title => name;

  @override
  int get length => songIds.length;

  @override
  List<Song> get songs {
    final List<Song> found = [];
    final List<int> notFoundIndices = [];
    for (int i = 0; i < songIds.length; i++) {
      final song = ContentControl.state.allSongs.byId.get(songIds[i]);
      if (song != null) {
        found.add(song);
      } else {
        notFoundIndices.add(songIds[i]);
      }
    }
    for (int i = notFoundIndices.length - 1; i >= 0; i--) {
      songIds.remove(i);
    }
    return found;
  }

  /// Returns content URI of the first item in the album.
  String get firstSong {
    final song = ContentControl.state.allSongs.songs.firstWhere((el) => el.albumId == id);
    return song.contentUri;
  }

  const Playlist({
    required int id,
    required this.data,
    required this.dateAdded,
    required this.dateModified,
    required this.name,
    required this.songIds,
  }) : super(id: id);

  Playlist copyWith({
    required int id,
    required String data,
    required int dateAdded,
    required int dateModified,
    required String name,
    required List<int> songIds,
  }) {
    return Playlist(
      id: id,
      data: data,
      dateAdded: dateAdded,
      dateModified: dateModified,
      name: name,
      songIds: songIds,
    );
  }

  factory Playlist.fromMap(Map map) {
    return Playlist(
      id: map['id'] as int,
      data: map['data'] as String,
      dateAdded: map['dateAdded'] as int,
      dateModified: map['dateModified'] as int,
      name: map['name'] as String,
      songIds: (map['songIds'] as List).cast<int>(),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
      'id': id,
      'data': data,
      'dateAdded': dateAdded,
      'dateModified': dateModified,
      'name': name,
      'songIds': songIds,
    };
}
