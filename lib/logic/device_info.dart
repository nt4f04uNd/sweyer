import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:sweyer/sweyer.dart';

/// Provides an information about the device.
class DeviceInfoControl extends Control {
  static DeviceInfoControl instance = DeviceInfoControl();

  /// Android SDK integer.
  int get sdkInt => _sdkInt;
  late int _sdkInt = 0; // Default to 0 for non-Android platforms

  /// Whether to use scoped storage to modify system files.
  ///
  /// Doesn't apply to [ContentArt], which uses scoped storage
  /// starting from API 29.
  bool get useScopedStorageForFileModifications => sdkInt >= 30;

  /// Whether to use the more granular audio permission (READ_MEDIA_AUDIO).
  ///
  /// This must be used instead of the storage permission on API level 33 and onward.
  bool get useAudioPermission => sdkInt >= 33;

  @override
  Future<void> init() async {
    super.init();

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        _sdkInt = androidInfo.version.sdkInt;
      } catch (e) {
        _sdkInt = 0;
      }
    }
  }
}
