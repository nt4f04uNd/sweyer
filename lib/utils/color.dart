import 'package:flutter/material.dart';

/// Shades a color.
///
/// If [factor] is from 0.0 to 1.0 - lightens;
/// If [factor] is from -1.0 to 0.0 - darkens.
///
/// Inspired by https://stackoverflow.com/a/13532993
Color shadeColor(double factor, Color color, {int minBit = 0, int maxBit = 0xff}) {
  assert(factor >= -1 && factor <= 1);
  final minBound = minBit / 255.0;
  final maxBound = maxBit / 255.0;
  factor = (1 + factor);
  return color.withValues(
    red: (color.r * factor).clamp(minBound, maxBound),
    green: (color.g * factor).clamp(minBound, maxBound),
    blue: (color.b * factor).clamp(minBound, maxBound),
  );
}
