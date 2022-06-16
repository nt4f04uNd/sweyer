import 'dart:ui';

import 'package:rive/rive.dart';

extension ColorableArtboard on Artboard {
  /// Set the color of all strokes and filled areas in the animation to the given [color].
  void setForegroundColor(Color color) {
    forEachComponent((component) {
      if (component is Shape) {
        for (var stroke in component.strokes) {
          stroke.paint.color = color;
        }
        for (var fill in component.fills) {
          fill.paint.color = color;
        }
      }
    });
  }
}
