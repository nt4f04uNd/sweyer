/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:fluttertoast/fluttertoast.dart';
import 'package:sweyer/sweyer.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class Permissions {
  /// Whether storage permission is granted
  static late PermissionStatus _permissionStorageStatus;

  /// Returns true if permissions were granted
  static bool get granted => _permissionStorageStatus == PermissionStatus.granted;

  /// Returns true if permissions were not granted
  static bool get notGranted => !granted;

  static Future<void> init() async {
    _permissionStorageStatus = await Permission.storage.status;
  }

  static Future<void> requestClick() async {
    _permissionStorageStatus = await Permission.storage.request();
    if (_permissionStorageStatus == PermissionStatus.granted) {
      await ContentControl.init();
    } else if (_permissionStorageStatus == PermissionStatus.permanentlyDenied) {
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
