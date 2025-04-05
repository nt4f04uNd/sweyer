import 'dart:io';

/// Utility class to check platform support for various features.
class PlatformFeatures {
  /// Private constructor to prevent instantiation.
  PlatformFeatures._();

  /// Whether the current platform supports deleting songs.
  ///
  /// Currently only supported on Android.
  static bool get supportsDeleteSongs => Platform.isAndroid;

  /// Whether the current platform supports creating playlists.
  ///
  /// Currently only supported on Android.
  static bool get supportsCreatePlaylists => Platform.isAndroid;

  /// Whether the current platform supports renaming playlists.
  ///
  /// Currently only supported on Android.
  static bool get supportsRenamePlaylist => Platform.isAndroid;

  /// Whether the current platform supports removing playlists.
  ///
  /// Currently only supported on Android.
  static bool get supportsRemovePlaylists => Platform.isAndroid;

  /// Whether the current platform supports modifying playlist contents.
  ///
  /// Currently only supported on Android.
  static bool get supportsModifyPlaylistContents => Platform.isAndroid;
}
