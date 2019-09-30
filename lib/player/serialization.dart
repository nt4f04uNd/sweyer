import 'dart:convert';
import 'dart:io';

import 'package:app/player/song.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

abstract class Serialization {
  final String fileName = "";

  /// Create file json if it does not exists or of it is empty then write to it empty array
  Future<void> initJson() async {}

  /// Reads json and returns decoded data
  Future<dynamic> readJson() async {}

  /// Serializes provided data
  Future<void> saveJson(List<Song> data) async {}
}

/// Implementation of `Serialization` to serialize songs
class SongsSerialization implements Serialization {
  final String fileName = 'songs.json';

  /// Create file json if it does not exists or of it is empty then write to it empty array
  @override
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

  // / Reads json and returns decoded data
  @override
  Future<List<Song>> readJson() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      String jsonContent = await file.readAsString();
      return [...jsonDecode(jsonContent).map((el) => Song.fromJson(el))];
    } catch (e) {
      debugPrint('Error reading songs json, setting to empty songs list');
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
    debugPrint('Json saved');
  }
}