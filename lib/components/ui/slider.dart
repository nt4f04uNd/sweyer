/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';

/// Creates slider with labels of min and max values
class LabelledSlider extends StatelessWidget {
  const LabelledSlider({
    Key key,
    @required this.value,
    @required this.onChanged,
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
  })  : assert(value != null),
        assert(min != null),
        assert(max != null),
        assert(min <= max),
        assert(value >= min && value <= max),
        assert(divisions == null || divisions > 0),
        super(key: key);

  /// See [Slider.value]
  final double value;

  /// See [Slider.onChanged]
  final ValueChanged<double> onChanged;

  /// See [Slider.onChangeStart]
  final ValueChanged<double> onChangeStart;

  /// See [Slider.onChangeEnd]
  final ValueChanged<double> onChangeEnd;

  /// See [Slider.min]
  final double min;

  /// See [Slider.min]
  final double max;

  /// See [Slider.divisions]
  final int divisions;

  /// See [Slider.label]
  final String label;

  /// See [Slider.activeColor]
  final Color activeColor;

  /// See [Slider.inactiveColor]
  final Color inactiveColor;

  /// See [Slider.semanticFormatterCallback]
  final SemanticFormatterCallback semanticFormatterCallback;

  /// Label to display min value before the slider
  final String minLabel;

  /// Label to display max value after the slider
  final String maxLabel;

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
            minLabel,
            style: const TextStyle(fontSize: 13),
          ),

        //******** Slider ********
        Expanded(
          child: Container(
            height: 30.0,
            child: SliderTheme(
              data: themeData.copyWith(
                trackShape:
                    themeData.trackShape ?? const TrackShapeWithMargin(),
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
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                semanticFormatterCallback: semanticFormatterCallback,
              ),
            ),
          ),
        ),
        
        //******** Max Label ********
        if (maxLabel != null)
          Text(
            maxLabel,
            style: const TextStyle(fontSize: 13),
          ),
      ],
    );
  }
}

/// Put it into slider theme to make custom track margin
class TrackShapeWithMargin extends RoundedRectSliderTrackShape {
  const TrackShapeWithMargin({
    this.horizontalMargin = 12.0,
  });

  /// Margin to be applied for each side horizontally
  final double horizontalMargin;

  @override
  Rect getPreferredRect({
    @required RenderBox parentBox,
    Offset offset = Offset.zero,
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx + horizontalMargin;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - horizontalMargin * 2;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
