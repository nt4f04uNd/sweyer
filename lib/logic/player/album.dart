/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sweyer/sweyer.dart';

part 'album.g.dart';

@JsonSerializable()
class Album {
  final int id;

  /// Album name
  final String album;
  final String artist;
  final int artistId;
  final int firstYear;
  final int lastYear;
  final int numberOfSongs;

  Album({
    @required this.id,
    @required this.album,
    @required this.artist,
    @required this.artistId,
    @required this.firstYear,
    @required this.lastYear,
    @required this.numberOfSongs,
  });

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
  Map<String, dynamic> toJson() => _$AlbumToJson(this);

  /// Returns the albumArt path, that is taken from album arts map in [ContentControl.state]
  String get albumArt => ContentControl.state.albumArts[id];
}
