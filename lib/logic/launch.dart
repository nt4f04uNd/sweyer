import 'package:app/logic/player/player.dart';
import 'package:app/logic/player/playlist.dart';
import 'package:app/logic/theme.dart';
import 'package:app/utils/async.dart';
import 'package:app/logic/error_bridge.dart';
import 'package:catcher/core/catcher.dart';

import 'package:app/logic/api/api.dart' as API;

abstract class LaunchControl {
  static final ManualStreamController<bool> _streamController =
      ManualStreamController<bool>();

  static Stream<bool> get onLaunch => _streamController.stream;

  static Future<void> init() async {

    API.EventsHandler.start();
    
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
