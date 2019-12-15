/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app/constants/constants.dart' as Constants;

abstract class GeneralHandler {
  static MethodChannel _generalChannel =
      const MethodChannel(Constants.GeneralChannel.CHANNEL_NAME);

  /// Checks if open intent is view (user tried to open file with app)
  static Future<void> isIntentActionView() async {  
    return debugPrint((await _generalChannel
            .invokeMethod(Constants.GeneralChannel.METHOD_INTENT_ACTION_VIEW))
        .toString());
  }

  /// Test method that will kill activity, for test purposes
  static Future<void> killActivity() async {
    return debugPrint((await _generalChannel
            .invokeMethod(Constants.GeneralChannel.METHOD_INTENT_ACTION_VIEW))
        .toString());
  }
}
