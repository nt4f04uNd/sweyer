import 'package:flutter/material.dart';

/// Shades a color.
///
/// If [factor] is from 0.0 to 1.0 - lightens;
/// If [factor] is from -1.0 to 0.0 - darkens.
///
/// Inspired by https://stackoverflow.com/a/13532993
Color shadeColor(double factor, Color color) {
  assert(factor >= -1 && factor <= 1);
  var r = ((color.value >> 16) & 0xff).clamp(0, 0xff);
  var g = ((color.value >> 8) & 0xff).clamp(0, 0xff);
  var b = (color.value & 0xff).clamp(0, 0xff);

  factor = (1 + factor);
  r = (r * factor).toInt().clamp(0, 0xff);
  g = (g * factor).toInt().clamp(0, 0xff);
  b = (b * factor).toInt().clamp(0, 0xff);

  return Color((0xff << 24) + (r << 16) + (g << 8) + b);
}
