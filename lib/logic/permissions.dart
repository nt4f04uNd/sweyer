/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter_music_player/components/show_functions.dart';
import 'package:flutter_music_player/logic/player/playlist.dart';
import 'package:flutter_music_player/logic/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MyPermissionStatus { granted, notGranted, doNotAskAgain }

abstract class Permissions {
  /// Whether storage permission is granted
  static MyPermissionStatus permissionStorageStatus =
      MyPermissionStatus.notGranted;

  static Future<void> requestStorage() async {
    bool canOpen = false;
    if (Permissions.permissionStorageStatus ==
        MyPermissionStatus.doNotAskAgain) {
      await ShowFunctions.showToast(msg: 'Предоставьте доступ вручную');
      canOpen = await PermissionHandler().openAppSettings();
      Permissions.permissionStorageStatus = MyPermissionStatus.notGranted;
    }
    if (!canOpen) {
      await Permissions.requestPermission(PermissionGroup.storage);
      if (Permissions.permissionStorageStatus == MyPermissionStatus.granted) {
        await PlaylistControl.init();
        await ThemeControl.init();
      }
    }
  }

  /// See https://github.com/BaseflowIT/flutter-permission-handler/issues/96#issuecomment-526617086
  static Future<void> requestPermission(PermissionGroup permissionGroup) async {
    MyPermissionStatus status;
    Map<PermissionGroup, PermissionStatus> permissionsGranted =
        await PermissionHandler()
            .requestPermissions(<PermissionGroup>[permissionGroup]);
    PermissionStatus permissionStatus = permissionsGranted[permissionGroup];

    if (permissionStatus == PermissionStatus.granted) {
      status = MyPermissionStatus.granted;
    } else {
      bool beenAsked = await hasPermissionBeenAsked(permissionGroup);
      bool rationale = await PermissionHandler()
          .shouldShowRequestPermissionRationale(permissionGroup);
      if (beenAsked && !rationale) {
        status = MyPermissionStatus.doNotAskAgain;
      } else {
        status = MyPermissionStatus.notGranted;
      }
    }

    setPermissionHasBeenAsked(permissionGroup);
    permissionStorageStatus = status;
  }

  static Future<void> setPermissionHasBeenAsked(
      PermissionGroup permissionGroup) async {
    // TODO: move this to prefs
    (await SharedPreferences.getInstance())
        .setBool('permission_asked_${permissionGroup.value}', true);
  }

  static Future<bool> hasPermissionBeenAsked(
      PermissionGroup permissionGroup) async {
    // TODO: move this to prefs
    return (await SharedPreferences.getInstance())
            .getBool('permission_asked_${permissionGroup.value}') ??
        false;
  }
}
