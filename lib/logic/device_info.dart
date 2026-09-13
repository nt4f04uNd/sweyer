import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:sweyer/sweyer.dart';

/// Provides an information about the device.
class DeviceInfoControl extends Control {
  static DeviceInfoControl instance = DeviceInfoControl();

  int _androidSdkInt = 0;

  bool get _isAndroidTarget => defaultTargetPlatform == TargetPlatform.android;
  bool get _isIOSTarget => defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether to use scoped storage to modify system files.
  ///
  /// Doesn't apply to [ContentArt], which uses scoped storage
  /// starting from API 29.
  bool get useScopedStorageForFileModifications => _isAndroidTarget && _androidSdkInt >= 30;

  /// Whether to use the more granular audio permission (READ_MEDIA_AUDIO).
  ///
  /// This must be used instead of the storage permission on API level 33 and onward.
  bool get useAudioPermission => _isAndroidTarget && _androidSdkInt >= 33;

  /// Whether album art must be loaded as bytes instead of from a file path.
  bool get useBytesForAlbumArt => _isIOSTarget || _androidSdkInt >= 29;

  /// Whether songs can be deleted from their source library.
  bool get supportsDeleteSongs => _isAndroidTarget;

  /// Whether playlists can be created in the source library.
  bool get supportsCreatePlaylists => _isAndroidTarget;

  /// Whether source playlists can be renamed.
  bool get supportsRenamePlaylist => _isAndroidTarget;

  /// Whether playlists can be deleted from the source library.
  bool get supportsRemovePlaylists => _isAndroidTarget;

  /// Whether songs can be added to, removed from, or reordered in playlists.
  bool get supportsModifyPlaylistContents => _isAndroidTarget;

  @override
  Future<void> init() async {
    super.init();

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        _androidSdkInt = androidInfo.version.sdkInt;
      } catch (e) {
        _androidSdkInt = 0;
      }
    }
  }
}
