/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PermissionState { granted, notGranted, doNotAskAgain }

abstract class Permissions {
  /// Whether storage permission is granted
  static PermissionState _permissionStorageStatus = PermissionState.notGranted;

  /// Returns true if permissions were granted
  static bool get granted =>
      _permissionStorageStatus == PermissionState.granted;

  /// Returns true if permissions were not granted
  static bool get notGranted =>
      _permissionStorageStatus != PermissionState.granted;

  static Future<void> init() async {
    if ((await checkPermissionStatus(PermissionGroup.storage)) ==
        PermissionStatus.granted)
      _permissionStorageStatus = PermissionState.granted;
  }

  static Future<void> requestClick() async {
    bool canOpen = false;
    if (_permissionStorageStatus == PermissionState.doNotAskAgain) {
      await ShowFunctions.showToast(msg: 'Предоставьте доступ вручную');
      canOpen = await PermissionHandler().openAppSettings();
      _permissionStorageStatus = PermissionState.notGranted;
    }
    if (!canOpen) {
      await Permissions.requestPermission(PermissionGroup.storage);
      if (_permissionStorageStatus == PermissionState.granted) {
        await ContentControl.init();
      }
    }
  }

  static Future<PermissionStatus> checkPermissionStatus(
      PermissionGroup permissionGroup) async {
    return await PermissionHandler().checkPermissionStatus(permissionGroup);
  }

  /// See https://github.com/BaseflowIT/flutter-permission-handler/issues/96#issuecomment-526617086
  static Future<void> requestPermission(PermissionGroup permissionGroup) async {
    PermissionState status;
    Map<PermissionGroup, PermissionStatus> permissionsGranted =
        await PermissionHandler()
            .requestPermissions(<PermissionGroup>[permissionGroup]);
    PermissionStatus permissionStatus = permissionsGranted[permissionGroup];

    if (permissionStatus == PermissionStatus.granted) {
      status = PermissionState.granted;
    } else {
      bool beenAsked = await checkPermissionBeenAsked(permissionGroup);
      bool rationale = await PermissionHandler()
          .shouldShowRequestPermissionRationale(permissionGroup);
      if (beenAsked && !rationale) {
        status = PermissionState.doNotAskAgain;
      } else {
        status = PermissionState.notGranted;
      }
    }

    setPermissionAsked(permissionGroup);
    _permissionStorageStatus = status;
  }

  static Future<void> setPermissionAsked(
      PermissionGroup permissionGroup) async {
    // TODO: move this to prefs
    (await SharedPreferences.getInstance())
        .setBool('permission_asked_${permissionGroup.value}', true);
  }

  static Future<bool> checkPermissionBeenAsked(
      PermissionGroup permissionGroup) async {
    // TODO: move this to prefs
    return (await SharedPreferences.getInstance())
            .getBool('permission_asked_${permissionGroup.value}') ??
        false;
  }
}
