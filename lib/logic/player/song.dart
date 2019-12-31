/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// This allows the `Song` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'song.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class Song {
  final int id;
  final String album;
  final int albumId;
  final int albumKey;
  final String artist;
  final int artistId;
  final int artistKey;
  final String title;
  final int titleKey;
  final int dateAdded;
  final int dateModified;

  /// Duration in milliseconds
  final int duration;
  final int size;
  final String albumArtUri;

  Song(
      {@required this.id,
      @required this.album,
      @required this.albumId,
      @required this.albumKey,
      @required this.artist,
      @required this.artistId,
      @required this.artistKey,
      @required this.title,
      @required this.titleKey,
      @required this.dateAdded,
      @required this.dateModified,
      @required this.duration,
      @required this.size,
      @required this.albumArtUri});

  // Song.test()
  //     : id = 0,
  //       artist = "TEST",
  //       album = "TEST",
  //       albumArtUri = "TEST",
  //       title = "TEST",
  //       trackUri = "TEST",
  //       duration = 300000,
  //       dateModified = 100000000000000900;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$UserFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$SongToJson(this);
}
