/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Class to save and get [SharedPreferences]
/// It is a unite container for all the shared preferences of the application.
/// Though it doesn't contain settings prefs, that are used in the settings route, they can be found in [Settings] class.
/// It contains even ones that aren't used in dart side directly, but only on native.
abstract class Prefs {
  /// Search history list
  static final Pref<List<String>> searchHistoryStringList =
      Pref<List<String>>(key: 'search_history', defaultValue: <String>[]);

  /// Track position
  ///
  /// NOTE IN SECONDS
  static final Pref<int> songPositionInt =
      Pref<int>(key: 'song_position', defaultValue: 0);

  /// Last playing track id
  static final Pref<int> songIdIntNullable =
      Pref<int>(key: 'song_id', defaultValue: null);

  /// Last playing track id
  ///
  /// NOTE Used on native side only to allow service be sticky
  static final Pref<bool> songIsPlayingBool =
      Pref<bool>(key: 'song_is_playing', defaultValue: false);

  /// Loop mode
  ///
  /// NOTE Used on native side
  static final Pref<bool> loopModeBool =
      Pref<bool>(key: 'loop_mode', defaultValue: false);

  /// Sort feature
  ///
  /// `0` represents date feature
  ///
  /// `1` represents title feature
  // static final Pref<int> sortFeatureInt =
  //     Pref<int>(key: 'sort_feature', defaultValue: 0);
  static final Pref<int> sortFeatureInt =
      Pref<int>(key: 'sort_feature', defaultValue: 0);

  /// Last played [_currentPlaylistType]
  ///
  /// `0` represents [global]
  ///
  /// `1` represents [searched]
  ///
  /// `2` represents [shuffled]
  static final Pref<int> playlistTypeInt =
      Pref<int>(key: 'playlist_type', defaultValue: 0);

  /// Developer mode pref.
  /// When true, special dev menu in the drawer gets unlocked.
  /// Activated through taps on app logo in settings menu.
  static final Pref<bool> developerModeBool =
      Pref<bool>(key: 'developer_mode', defaultValue: false);

  /// Returns [SharedPreferences] instance
  static Future<SharedPreferences> getSharedInstance() async {
    return SharedPreferences.getInstance();
  }
}

/// Prefs specially for settings route
abstract class Settings {
  /// Minimal file duration to be considered as a song
  ///
  /// Stored in seconds
  static final Pref<int> minFileDurationInt =
      Pref<int>(key: 'setting_min_file_duration', defaultValue: 30);

  /// Stores theme brightness
  ///
  /// [false] means light
  ///
  /// [true] means dark
  static final Pref<bool> darkThemeBool =
      Pref<bool>(key: 'setting_dark_theme', defaultValue: false);
}

/// Class that represents single pref
///
/// Even if default value is null, you should specify it explicitly and give a pref variable "Nullable" postfix
class Pref<T> {
  Pref({
    @required this.key,
    @required this.defaultValue,
  }) : assert(key != null) {
    /// Call this to check current pref value and set it to default, if it's null
    getPref();
  }

  final String key;
  final T defaultValue;

  /// Set pref value.
  /// Without [value] will set the pref to its [defaultValue].
  ///
  /// @param [value] new pref value to set.
  ///
  /// @param [prefs] optional [SharedPreferences] instance.
  Future<bool> setPref({T value, SharedPreferences prefs}) async {
    value ??= defaultValue;
    prefs ??= await SharedPreferences.getInstance();

    // Convert type to string because [is] operator doesn't work
    final String strT = T.toString();

    if (strT == "bool") {
      return prefs.setBool(key, value as bool);
    } else if (strT == "int") {
      return prefs.setInt(key, value as int);
    } else if (strT == "double") {
      return prefs.setDouble(key, value as double);
    } else if (strT == "String") {
      return prefs.setString(key, value as String);
    } else if (strT == "List<String>") {
      return prefs.setStringList(key, value as List<String>);
    }
    throw Exception("setPref: Wrong type of pref generic: T = $T");
  }

  /// Get pref value.
  /// If the current value is `null`, will return [defaultValue] call [setPref] to reset the pref to the [defaultValue].
  ///
  /// @param prefs optional [SharedPreferences] instance
  Future<T> getPref([SharedPreferences prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    // Convert type to string because [is] operator doesn't work
    final String strT = T.toString();

    T res;

    if (strT == "bool") {
      res = prefs.getBool(key) as T;
    } else if (strT == "int") {
      res = prefs.getInt(key) as T;
    } else if (strT == "double") {
      res = prefs.getDouble(key) as T;
    } else if (strT == "String") {
      res = prefs.getString(key) as T;
    } else if (strT == "List<String>") {
      res = prefs.getStringList(key) as T;
    } else {
      throw Exception("getPref: Wrong type of pref generic: T = $T");
    }

    // Reset pref value to default value if defaultValue is not null
    if (res == null && defaultValue != null) {
      res = defaultValue;
      setPref(prefs: prefs);
    }

    return res;
  }
}
