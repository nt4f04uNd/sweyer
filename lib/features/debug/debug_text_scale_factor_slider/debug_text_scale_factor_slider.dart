import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sweyer/sweyer.dart';

class DebugTextScaleFactorSlider extends ConsumerWidget {
  const DebugTextScaleFactorSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = getl10n(context);
    final textScaleFactor = ref.watch(textScaleFactorStateNotifierProvider.select((value) => value));
    final textScaleFactorStateNotifier = ref.watch(textScaleFactorStateNotifierProvider.notifier);

    final theme = Theme.of(context);

    const min = 0.5;
    const max = 2.5;
    const divisionStep = 0.01;

    return SettingItem(
      title: l10n.debugTextScaleFactor,
      trailing: ChangedSwitcher(
        changed: textScaleFactor != 1.0,
        child: ButtonTheme(
          height: 36.0,
          child: AppButton(
            text: l10n.reset,
            onPressed: () {
              textScaleFactorStateNotifier.setValue(1.0);
            },
          ),
        ),
      ),
      content: LabelledSlider(
        inactiveColor: theme.appThemeExtension.sliderInactiveColor,
        min: min,
        max: max,
        divisions: (max - min) ~/ divisionStep,
        value: textScaleFactor,
        onChanged: textScaleFactorStateNotifier.setValue,
        onChangeEnd: textScaleFactorStateNotifier.setValue,
        label: textScaleFactor.toStringAsFixed(2),
        minLabel: '$min',
        maxLabel: '$max',
        themeData: SliderThemeData(
          tickMarkShape: SliderTickMarkShape.noTickMark,
        ),
      ),
    );
  }
}
