import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sweyer/sweyer.dart';
import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Permissions instance = Permissions();

  /// Whether storage permission is granted
  @visibleForTesting
  late PermissionStatus permissionStorageStatus;

  /// Returns true if permissions were granted
  bool get granted => permissionStorageStatus == PermissionStatus.granted;

  /// Returns true if permissions were not granted
  bool get notGranted => !granted;

  Future<void> init() async {
    permissionStorageStatus = await Permission.storage.status;
  }

  Future<void> requestClick() async {
    permissionStorageStatus = await Permission.storage.request();
    if (permissionStorageStatus == PermissionStatus.granted) {
      await ContentControl.instance.init();
    } else if (permissionStorageStatus == PermissionStatus.permanentlyDenied) {
      final l10n = staticl10n;
      await ShowFunctions.instance.showToast(
        msg: l10n.allowAccessToExternalStorageManually,
      );
      if (!(await openAppSettings())) {
        await Fluttertoast.cancel();
        await ShowFunctions.instance.showToast(msg: l10n.openAppSettingsError);
      }
    }
  }
}
