/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// It is a unite container for all the shared preferences of the application.
/// It contains even ones that aren't used in dart side directly, but only on native
class _PrefKeys {
  /// Search history list
  final Pref<List<String>> searchHistoryStringList =
      const Pref<List<String>>(key: 'search_history');

  /// Track position
  /// 
  /// NOTE IN SECONDS
  final Pref<int> songPositionInt = const Pref<int>(key: 'song_position');

  /// Last playing track id
  final Pref<int> songIdInt = const Pref<int>(key: 'song_id');

  /// Last playing track id
  /// 
  /// NOTE Used on native side only to allow service be sticky
  final Pref<int> songIsPlayingBool = const Pref<int>(key: 'song_is_playing');

  /// Loop mode
  /// 
  /// NOTE Used on native
  final Pref<bool> loopModeBool = const Pref<bool>(key: 'loop_mode');

  /// Sort feature
  ///
  /// `0` represents date feature
  ///
  /// `1` represents title feature
  final Pref<int> sortFeatureInt = const Pref<int>(key: 'sort_feature');

  /// Last played [_currentPlaylistType]
  ///
  /// `0` represents [global]
  ///
  /// `1` represents [searched]
  ///
  /// `2` represents [shuffled]
  final Pref<int> playlistTypeInt = const Pref<int>(key: 'playlist_type');

  /// Minimal file duration to be considered as a song
  /// 
  /// Stored in seconds
  final Pref<int> settingMinFileDurationInt =
      const Pref<int>(key: 'setting_min_file_duration');

  /// Stores theme brightness
  /// 
  /// [false] means light
  /// 
  /// [true] means dark
  final Pref<bool> settingThemeBrightnessBool =
      const Pref<bool>(key: 'setting_theme_brightness');

  const _PrefKeys();
}

/// Class to save and get [SharedPreferences]
abstract class Prefs {
  /// Keys to save shared preferences
  static const _PrefKeys byKey = _PrefKeys();

  /// Returns [SharedPreferences] instance
  static Future<SharedPreferences> getSharedInstance() async {
    return await SharedPreferences.getInstance();
  }
}

/// Class that represents single pref
class Pref<T> {
  final String key;
  const Pref({@required this.key}) : assert(key != null);

  /// Set pref value
  ///
  /// @param value new pref value to set
  /// @param prefs optional [SharedPreferences] instance
  Future<bool> setPref(T value, [SharedPreferences prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    if (value is bool) {
      return prefs.setBool(key, value);
    } else if (value is int) {
      return prefs.setInt(key, value);
    } else if (value is double) {
      return prefs.setDouble(key, value);
    } else if (value is String) {
      return prefs.setString(key, value);
    } else if (value is List<String>) {
      return prefs.setStringList(key, value);
    }
    throw Exception("setPref: Wrong type of pref generic: T = $T");
  }

  /// Get pref value
  ///
  /// @param prefs optional [SharedPreferences] instance
  Future<T> getPref([SharedPreferences prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    // Convert type to string because [is] operator doesn't work
    final String strT = T.toString();
    if (strT == "bool") {
      return prefs.getBool(key) as T;
    } else if (strT == "int") {
      return prefs.getInt(key) as T;
    } else if (strT == "double") {
      return prefs.getDouble(key) as T;
    } else if (strT == "String") {
      return prefs.getString(key) as T;
    } else if (strT == "List<String>") {
      return prefs.getStringList(key) as T;
    }
    throw Exception("getPref: type of pref generic: T = $T");
  }
}
