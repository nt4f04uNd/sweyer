/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:ui';

/// This is the color of the mask background (by RGBs, full color would be `0x1a1a1a`).
/// It's twice lighter than the shadow color on the mask,
/// which is `0x001d0d0d`. This is needed to blend the image color
/// onto mask properly by subtracting it from the desired image background color.
const int _mask = 0x1a;
Color getColorForBlend(Color color) {
  final int r = (((color.value >> 16) & 0xff) - _mask).clamp(0, 0xff);
  final int g = (((color.value >> 8) & 0xff) - _mask).clamp(0, 0xff);
  final int b = ((color.value & 0xff) - _mask).clamp(0, 0xff);
  return Color((0xff << 24) + (r << 16) + (g << 8) + b);
}
