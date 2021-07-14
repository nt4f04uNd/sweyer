/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';

/// Creates slider with labels of min and max values
class LabelledSlider extends StatelessWidget {
  const LabelledSlider({
    Key? key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.semanticFormatterCallback,
    this.minLabel,
    this.maxLabel,
    this.themeData = const SliderThemeData(),
  })  : assert(min <= max),
        assert(value >= min && value <= max),
        assert(divisions == null || divisions > 0),
        super(key: key);

  /// See [Slider.value]
  final double value;

  /// See [Slider.onChanged]
  final ValueChanged<double> onChanged;

  /// See [Slider.onChangeStart]
  final ValueChanged<double>? onChangeStart;

  /// See [Slider.onChangeEnd]
  final ValueChanged<double>? onChangeEnd;

  /// See [Slider.min]
  final double min;

  /// See [Slider.min]
  final double max;

  /// See [Slider.divisions]
  final int? divisions;

  /// See [Slider.label]
  final String? label;

  /// See [Slider.activeColor]
  final Color? activeColor;

  /// See [Slider.inactiveColor]
  final Color? inactiveColor;

  /// See [Slider.semanticFormatterCallback]
  final SemanticFormatterCallback? semanticFormatterCallback;

  /// Label to display min value before the slider
  final String? minLabel;

  /// Label to display max value after the slider
  final String? maxLabel;

  final SliderThemeData themeData;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        //******** Min Label ********
        if (minLabel != null)
          Text(
            minLabel!,
            style: const TextStyle(fontSize: 13),
          ),

        //******** Slider ********
        Expanded(
          child: SizedBox(
            height: 30.0,
            child: SliderTheme(
              data: SliderThemeData(
                trackShape: themeData.trackShape ?? const TrackShapeWithMargin(horizontalMargin: 12.0),
                valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                overlayColor: Colors.transparent,
                activeTrackColor: activeColor ?? ThemeControl.theme.colorScheme.primary,
                inactiveTrackColor: inactiveColor ?? Constants.Theme.sliderInactiveColor.auto,
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
                onChangeStart: onChangeStart,
                onChangeEnd: onChangeEnd,
                min: min,
                max: max,
                divisions: divisions,
                label: label,
                semanticFormatterCallback: semanticFormatterCallback,
              ),
            ),
          ),
        ),

        //******** Max Label ********
        if (maxLabel != null)
          Text(
            maxLabel!,
            style: const TextStyle(fontSize: 13),
          ),
      ],
    );
  }
}
