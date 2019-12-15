import 'package:flutter/services.dart';

import 'package:app/constants/constants.dart' as Constants;

class ServiceHandler {
  static MethodChannel _serviceChannel =
      const MethodChannel(Constants.ServiceChannel.CHANNEL_NAME);

  static bool _started = false;

  static void startService() {
    if (!_started) {
      _serviceChannel
          .invokeMethod(Constants.ServiceChannel.METHOD_START_SERVICE);
      _started = true;
    }
  }

  static void stopService() {
    if (_started) {
       _started = false;
      _serviceChannel
          .invokeMethod(Constants.ServiceChannel.METHOD_STOP_SERVICE);
    }
  }
}
