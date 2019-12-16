/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_music_player/logic/player/player.dart';
import 'package:flutter_music_player/logic/player/playlist.dart';
import 'package:flutter_music_player/logic/theme.dart';
import 'package:flutter_music_player/utils/async.dart';
import 'package:flutter_music_player/logic/error_bridge.dart';
import 'package:catcher/core/catcher.dart';

import 'package:flutter_music_player/logic/api/api.dart' as API;

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
  static final ManualStreamController<bool> _streamController =
      ManualStreamController<bool>();

  static Stream<bool> get onLaunch => _streamController.stream;

  static Future<void> init() async {
    API.EventsHandler.start();

    // Add callback to stop service when app is destroyed, temporary
    WidgetsBinding.instance
        .addObserver(LifecycleEventHandler(detachedCallback: () async {
      API.ServiceHandler.stopService();
    }));

    try {
      // Init playlist control
      // we don't want to wait it
      PlaylistControl.init();
      await Future.wait([
        // Init music player
        // It is not in main function, because we need catcher to catch errors
        MusicPlayer.init(),
        // Init theme control
        ThemeControl.init()
      ]);
    } catch (exception, stacktrace) {
      CatcherErrorBridge.add(CaughtError(exception, stacktrace));
    } finally {
      _streamController.emitEvent(true);
    }
  }

  static void afterAppMount() {
    CatcherErrorBridge.report((e) {
      Catcher.reportCheckedError(e.exception, e.stackTrace);
    });
  }
}
