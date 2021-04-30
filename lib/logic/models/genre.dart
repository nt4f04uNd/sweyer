/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';
class Genre extends Content {
  @override
  final int id;
  final String name;
  final List<int> songIds;

  @override
  List<Object> get props => [id];

  const Genre({
    required this.id,
    required this.name,
    required this.songIds,
  });

  Genre copyWith({
    int? id,
    String? name,
    List<int>? songIds,
  }) {
    return Genre(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
    );
  }

  factory Genre.fromMap(Map map) {
    return Genre(
      id: map['id'] as int,
      name: map['name'] as String,
      songIds: map['songIds'].cast<int>(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'songIds': songIds,
  };
}