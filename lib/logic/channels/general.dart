/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:ui';

import 'package:flutter/services.dart';

abstract class GeneralChannel {
  static MethodChannel _channel = const MethodChannel('general_channel');

  /// Checks if open intent is view (user tried to open file with app)
  static Future<bool> isIntentActionView() async {
    return _channel.invokeMethod<bool>('isIntentActionView');
  }

  static Future<bool> stopService() async {
    return _channel.invokeMethod<bool>('stopService');
  }

  static Future<bool> reloadArtPlaceholder(Color color) async {
    return _channel.invokeMethod<bool>('reloadArtPlaceholder', color.value);
  }
}
