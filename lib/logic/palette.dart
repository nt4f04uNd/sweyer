import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

Future<PaletteGenerator> createPalette(ui.Image image) => PaletteGenerator.fromImage(
  image,
  maximumColorCount: 50,
);

/// A widget that draws the swatches for the [PaletteGenerator] it is given,
/// and shows the selected target colors.
class PaletteSwatches extends StatelessWidget {
  /// Create a Palette swatch.
  ///
  /// The [generator] is optional. If it is null, then the display will
  /// just be an empty container.
  const PaletteSwatches({Key? key, this.generator}) : super(key: key);

  /// The [PaletteGenerator] that contains all of the swatches that we're going
  /// to display.
  final PaletteGenerator? generator;

  @override
  Widget build(BuildContext context) {
    final List<Widget> swatches = <Widget>[];
    final PaletteGenerator? paletteGen = generator;
    if (paletteGen == null || paletteGen.colors.isEmpty) {
      return Container();
    }
    for (final Color color in paletteGen.colors) {
      swatches.add(PaletteSwatch(color: color));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Wrap(
          children: swatches,
        ),
        const SizedBox(height: 30.0),
        PaletteSwatch.forPalette(label: 'Dominant', color: paletteGen.dominantColor),
        PaletteSwatch.forPalette(label: 'Light Vibrant', color: paletteGen.lightVibrantColor),
        PaletteSwatch.forPalette(label: 'Vibrant', color: paletteGen.vibrantColor),
        PaletteSwatch.forPalette(label: 'Dark Vibrant', color: paletteGen.darkVibrantColor),
        PaletteSwatch.forPalette(label: 'Light Muted', color: paletteGen.lightMutedColor),
        PaletteSwatch.forPalette(label: 'Muted', color: paletteGen.mutedColor),
        PaletteSwatch.forPalette(label: 'Dark Muted', color: paletteGen.darkMutedColor),
      ],
    );
  }
}


const Color _kBackgroundColor = Color(0xffa0a0a0);
const Color _kSelectionRectangleBackground = Color(0x15000000);
const Color _kSelectionRectangleBorder = Color(0x80000000);
const Color _kPlaceholderColor = Color(0x80404040);

/// A small square of color with an optional label.
@immutable
class PaletteSwatch extends StatelessWidget {
  /// Creates a PaletteSwatch.
  ///
  /// If the [paletteColor] has property `isTargetColorFound` as `false`,
  /// then the swatch will show a placeholder instead, to indicate
  /// that there is no color.
  const PaletteSwatch({
    Key? key,
    this.color,
    this.label,
  }) : paletteColor = null,
       super(key: key);

  const PaletteSwatch.forPalette({
    Key? key,
    PaletteColor? color,
    this.label,
  }) : paletteColor = color,
       color = null,
       super(key: key);

  /// The color of the swatch.
  final Color? color;

  /// The palette color of the swatch.
  final PaletteColor? paletteColor;

  /// The optional label to display next to the swatch.
  final String? label;

  Widget _buildSwatch(Color? color) {
    // Compute the "distance" of the color swatch and the background color
    // so that we can put a border around those color swatches that are too
    // close to the background's saturation and lightness. We ignore hue for
    // the comparison.
    final HSLColor hslColor = HSLColor.fromColor(color ?? Colors.transparent);
    final HSLColor backgroundAsHsl = HSLColor.fromColor(_kBackgroundColor);
    final double colorDistance = math.sqrt(
      math.pow(hslColor.saturation - backgroundAsHsl.saturation, 2.0) +
      math.pow(hslColor.lightness - backgroundAsHsl.lightness, 2.0)
    );

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: color == null
        ? const Placeholder(
            fallbackWidth: 34.0,
            fallbackHeight: 20.0,
            color: Color(0xff404040),
            strokeWidth: 2.0,
          )
        : Container(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                width: 1.0,
                color: _kPlaceholderColor,
                style: colorDistance < 0.2
                  ? BorderStyle.solid
                  : BorderStyle.none,
              ),
            ),
            width: 34.0,
            height: 20.0,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _buildSwatch(this.color ?? paletteColor?.color);
    if (label == null)
      return color;
    final titleText = _buildSwatch(paletteColor?.titleTextColor);
    final bodyText = _buildSwatch(paletteColor?.bodyTextColor);
    return Container(
      color: Colors.white,
      constraints: const BoxConstraints(maxWidth: 130.0, minWidth: 130.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          titleText,
          const SizedBox(width: 5.0),
          bodyText,
          const SizedBox(width: 5.0),
          color,
          const SizedBox(width: 5.0),
          Text(label!),
        ],
      ),
    );
  }
}
