/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:catcher/core/catcher.dart';

import 'package:sweyer/logic/api/api.dart' as API;

class LifecycleEventHandler extends WidgetsBindingObserver {
  LifecycleEventHandler({@required this.detachedCallback})
      : assert(detachedCallback != null);

  final AsyncCallback detachedCallback;

  @override
  Future<Null> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        await detachedCallback();
        break;
      case AppLifecycleState.resumed:
        break;
    }
  }
}

abstract class LaunchControl {
  static final StreamController<bool> _streamController =
      StreamController<bool>.broadcast();

  static Stream<bool> get onLaunch => _streamController.stream;

  static Future<void> init() async {
    API.EventsHandler.start();

    // Add callback to stop service when app is destroyed, temporary
    // WidgetsBinding.instance
    //     .addObserver(LifecycleEventHandler(detachedCallback: () async {
    //   await API.ServiceHandler.stopService();
    // }));

    try {
      // Init playlist control
      // we don't want to wait it
      await Permissions.init();
      PlaylistControl.init();
      await Future.wait([
        // Init theme control
        ThemeControl.init(),
        // Init music player
        // It is not in main function, because we need catcher to catch errors
        MusicPlayer.init(),
      ]);
    } catch (exception, stacktrace) {
      CatcherErrorBridge.add(CaughtError(exception, stacktrace));
    } finally {
      _streamController.add(true);
    }
  }

  static void afterAppMount() {
    CatcherErrorBridge.report((e) {
      Catcher.reportCheckedError(e.exception, e.stackTrace);
    });
  }
}
