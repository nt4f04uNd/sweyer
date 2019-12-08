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
  final String artist;
  final String album;
  final String albumArtUri;
  final String title;
  final String trackUri;
  final int duration;
  final int dateModified;

  Song({
    @required this.id,
    @required this.artist,
    @required this.album,
    @required this.albumArtUri,
    @required this.title,
    @required this.trackUri,
    @required this.duration,
    @required this.dateModified,
  });

   /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$UserFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$SongToJson(this);
}