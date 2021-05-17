// /*---------------------------------------------------------------------------------------------
// *  Copyright (c) nt4f04und. All rights reserved.
// *  Licensed under the BSD-style license. See LICENSE in the project root for license information.
// *--------------------------------------------------------------------------------------------*/


// import 'package:flutter/material.dart';
// import 'package:palette_generator/palette_generator.dart';
// import 'package:sweyer/sweyer.dart';

// getPalette(ContentArtSource source) => PaletteGenerator.fromImageProvider(
//   source,
//   size: widget.imageSize,
//   maximumColorCount: 50,
// );

// /// A widget that draws the swatches for the [PaletteGenerator] it is given,
// /// and shows the selected target colors.
// class PaletteSwatches extends StatelessWidget {
//   /// Create a Palette swatch.
//   ///
//   /// The [generator] is optional. If it is null, then the display will
//   /// just be an empty container.
//   const PaletteSwatches({Key? key, this.generator}) : super(key: key);

//   /// The [PaletteGenerator] that contains all of the swatches that we're going
//   /// to display.
//   final PaletteGenerator? generator;

//   @override
//   Widget build(BuildContext context) {
//     final List<Widget> swatches = <Widget>[];
//     final PaletteGenerator? paletteGen = generator;
//     if (paletteGen == null || paletteGen.colors.isEmpty) {
//       return Container();
//     }
//     for (final Color color in paletteGen.colors) {
//       swatches.add(PaletteSwatch(color: color));
//     }
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: <Widget>[
//         Wrap(
//           children: swatches,
//         ),
//         const SizedBox(height: 30.0),
//         PaletteSwatch(label: 'Dominant', color: paletteGen.dominantColor?.color),
//         PaletteSwatch(label: 'Light Vibrant', color: paletteGen.lightVibrantColor?.color),
//         PaletteSwatch(label: 'Vibrant', color: paletteGen.vibrantColor?.color),
//         PaletteSwatch(label: 'Dark Vibrant', color: paletteGen.darkVibrantColor?.color),
//         PaletteSwatch(label: 'Light Muted', color: paletteGen.lightMutedColor?.color),
//         PaletteSwatch(label: 'Muted', color: paletteGen.mutedColor?.color),
//         PaletteSwatch(label: 'Dark Muted', color: paletteGen.darkMutedColor?.color),
//       ],
//     );
//   }
// }
