import 'package:flutter/material.dart';

/// Shades a color.
///
/// If [factor] is from 0.0 to 1.0 - lightens;
/// If [factor] is from -1.0 to 0.0 - darkens.
///
/// Inspired by https://stackoverflow.com/a/13532993
Color shadeColor(double factor, Color color, {int minBit = 0, int maxBit = 0xff}) {
  assert(factor >= -1 && factor <= 1);
  factor = (1 + factor);
  final r = (color.r * 255.0 * factor).toInt().clamp(minBit, maxBit);
  final g = (color.g * 255.0 * factor).toInt().clamp(minBit, maxBit);
  final b = (color.b * 255.0 * factor).toInt().clamp(minBit, maxBit);
  return Color.fromARGB(0xFF, r, g, b);
}
