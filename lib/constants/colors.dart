/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color deepPurpleAccent = Color(0xFF7c4dff);

  /// Grey color, used in dark mode for the app bar, for example
  static const Color grey = Color(0xff1d1d1d);

  /// Light grey color, used for text in some places in light theme
  static const Color greyText = Color(0xff343434);

  /// Color of the logo of android 10
  static const Color yellow = Color(0xffe9b451);
  static const Color blue = Color(0xff4995f7);
  static const Color red = Color(0xffe53935);
  static const Color orange = Color(0xffff7043);
  static const Color pink = Color(0xffff9ebf);
  static const Color androidGreen = Color(0xff2edf85);

  /// A little bit darkened white color,
  /// used for marking some parts as headers from the rest of UI in light mode
  static const Color whiteDarkened = Color(0xfff1f2f4);
  static const Color eee = Color(0xffeeeeee);
}
