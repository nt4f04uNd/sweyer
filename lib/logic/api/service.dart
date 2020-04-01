/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/services.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';

abstract class ServiceHandler {
  static MethodChannel _serviceChannel =
      const MethodChannel(Constants.ServiceChannel.CHANNEL_NAME);

  static Future<void> stopService() async {
      await _serviceChannel
          .invokeMethod(Constants.ServiceChannel.METHOD_STOP_SERVICE);
  }

  static Future<void> sendSong(Song song) async {
    await _serviceChannel.invokeMethod(
        Constants.ServiceChannel.METHOD_SEND_CURRENT_SONG, {"song": song.toJson()});
  }
}
