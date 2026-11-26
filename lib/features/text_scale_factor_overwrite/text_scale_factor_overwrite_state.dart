import 'package:flutter_riverpod/legacy.dart'; // TODO: Switch from StateNotifierProvider to Notifier

final textScaleFactorStateNotifierProvider = StateNotifierProvider<TextScaleFactorStateNotifier, double?>(
  (ref) => TextScaleFactorStateNotifier(),
);

class TextScaleFactorStateNotifier extends StateNotifier<double?> {
  TextScaleFactorStateNotifier() : super(null);

  void setValue(double? value) => state = value;
  double? get() => state;
}
