import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final textScaleFactorStateNotifierProvider = StateNotifierProvider<TextScaleFactorStateNotifier, double>(
  (ref) => TextScaleFactorStateNotifier(),
);

class TextScaleFactorStateNotifier extends StateNotifier<double> {
  TextScaleFactorStateNotifier() : super(WidgetsBinding.instance.window.platformDispatcher.textScaleFactor);

  void setValue(double value) => state = value;
  double get() => state;
}
