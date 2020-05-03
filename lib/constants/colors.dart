/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';

abstract class AppColors {
  /// Grey color, used in dark mode for the app bar, for example
  static const Color grey = Color(0xff1d1d1d);
  /// Light grey color, used for text in some places in light theme
  static const Color greyText = Color(0xff343434);

  /// Color of the logo of android 10
  static const Color androidGreen = Color(0xff2edf85);

  /// A little bit darkened white color, 
  /// used for marking some parts as headers from the rest of UI in light mode
  static const Color whiteDarkened = Color(0xfff1f2f4);
  /// Color used for text in dark mode
  static const Color almostWhite = Color(0xfffffffe);
}
