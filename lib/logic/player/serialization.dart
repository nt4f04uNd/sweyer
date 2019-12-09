/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:convert';
import 'dart:io';

import 'song.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Class to create serialization objects
///
/// @param TRead denotes type of list that is returned from `readJson` method
/// @param TSave denotes type that has to be provided into `saveJson` method
abstract class Serialization<TRead, TSave> {
  final String fileName = "";

  /// Create file json if it does not exists or of it is empty then write to it empty array
  Future<void> initJson() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    if (!await file.exists()) {
      await file.create();
      await file.writeAsString(jsonEncode([]));
    } else if (await file.readAsString() == "") {
      await file.writeAsString(jsonEncode([]));
    }
  }

  /// Reads json and returns decoded data
  Future<List<TRead>> readJson() async {}

  /// Serializes provided data
  Future<void> saveJson(List<TSave> data) async {}
}

/// Implementation of `Serialization` to serialize songs
class SongsSerialization extends Serialization<Song, Song> {
  @override
  final String fileName = 'songs.json';

  // / Reads json and returns decoded data
  @override
  Future<List<Song>> readJson() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      String jsonContent = await file.readAsString();
      return [...jsonDecode(jsonContent).map((el) => Song.fromJson(el))];
    } catch (e) {
      debugPrint(
          '$fileName: Error reading songs json, setting to empty songs list');
      return []; // Return empty array if error has been caught
    }
  }

  /// Serializes provided songs data list
  @override
  Future<void> saveJson(List<Song> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    var jsonContent = jsonEncode(data);
    await file.writeAsString(jsonContent);
    debugPrint('$fileName: json saved');
  }
}

/// Implementation of `Serialization` to serialize playlists
///
/// Saves only songs ids, so you have to search indexes in `globalPlaylist` to restore playlist
class PlaylistSerialization extends Serialization<int, Song> {
  @override
  final String fileName = 'playlist.json';

  // / Reads json and returns decoded data
  @override
  Future<List<int>> readJson() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      String jsonContent = await file.readAsString();
      return jsonDecode(jsonContent).cast<int>();
    } catch (e) {
      debugPrint(
          '$fileName: Error reading songs json, setting to empty songs list');
      return []; // Return empty array if error has been caught
    }
  }

  /// Serializes provided playlist
  @override
  Future<void> saveJson(List<Song> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    var idsArray = data.map((el) => el.id).toList();
    var jsonContent = jsonEncode(idsArray);
    await file.writeAsString(jsonContent);
    debugPrint('$fileName: json saved');
  }
}
