import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

/// Utility class to check platform support for various features.
class PlatformFeatures {
  /// Private constructor to prevent instantiation.
  PlatformFeatures._();

  static bool get _isAndroidTarget => defaultTargetPlatform == TargetPlatform.android;

  /// Whether the current platform supports deleting songs.
  ///
  /// Currently only supported on Android.
  static bool get supportsDeleteSongs => _isAndroidTarget;

  /// Whether the current platform supports creating playlists.
  ///
  /// Currently only supported on Android.
  static bool get supportsCreatePlaylists => _isAndroidTarget;

  /// Whether the current platform supports renaming playlists.
  ///
  /// Currently only supported on Android.
  static bool get supportsRenamePlaylist => _isAndroidTarget;

  /// Whether the current platform supports removing playlists.
  ///
  /// Currently only supported on Android.
  static bool get supportsRemovePlaylists => _isAndroidTarget;

  /// Whether the current platform supports modifying playlist contents.
  ///
  /// Currently only supported on Android.
  static bool get supportsModifyPlaylistContents => _isAndroidTarget;
}
