/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';
import 'package:catcher/core/catcher.dart';

import 'package:sweyer/logic/api/api.dart' as API;

class WidgetBindingHandler extends WidgetsBindingObserver {
  WidgetBindingHandler({
    this.onInactive,
    this.onPaused,
    this.onDetached,
    this.onResumed,
  });

  final AsyncCallback onInactive;
  final AsyncCallback onPaused;
  final AsyncCallback onDetached;
  final AsyncCallback onResumed;

  @override
  Future<Null> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        if (onInactive != null) await onInactive();
        break;
      case AppLifecycleState.paused:
        if (onPaused != null) await onPaused();
        break;
      case AppLifecycleState.detached:
        if (onDetached != null) await onDetached();
        break;
      case AppLifecycleState.resumed:
        if (onResumed != null) await onResumed();
        break;
    }
  }
}

abstract class LaunchControl {
  static final StreamController<bool> _streamController =
      StreamController<bool>.broadcast();

  static Stream<bool> get onLaunch => _streamController.stream;

  static Future<void> init() async {
    // Add callback to stop service when app is destroyed, temporary
    WidgetsBinding.instance.addObserver(
      WidgetBindingHandler(
        // onDetached: () async {
        //   await API.ServiceHandler.stopService();
        // },
        onResumed: () {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              systemNavigationBarIconBrightness:
                  ThemeControl.contrastBrightness,
            ),
          );
        },
      ),
    );

    try {
      API.EventsHandler.init();
      API.SongsHandler.init();
      FirebaseControl.init();

      await Permissions.init();
      await Future.wait([
        ThemeControl.init(),
        ContentControl.init(),
        MusicPlayer.init(),
      ]);
      // Init playlist control, we don't want to wait it
    } catch (exception, stacktrace) {
      CatcherErrorBridge.add(CaughtError(exception, stacktrace));
      // print("ERROR ON STARTUP:  " + exception);
      // print(stacktrace);
    } finally {
      _streamController.add(true);
    }
  }

  static Future<void> afterAppMount() async {
    CatcherErrorBridge.report((e) {
      Catcher.reportCheckedError(e.exception, e.stackTrace);
    });
  }
}
