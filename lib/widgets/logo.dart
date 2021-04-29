/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';

/// Creates a Sweyer logo.
class SweyerLogo extends StatelessWidget {
  const SweyerLogo({
    Key? key,
    this.size = kSongTileArtSize,
    this.color,
  }) : super(key: key);

  final double size;

  /// Background color to be used instead of [ThemeControl.colorForBlend],
  /// which is applied by default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(8.0),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Transform.scale(
              scale: 1.65,
              child: Image.asset(
                Constants.Assets.ASSET_LOGO_MASK,
                color: color != null
                    ? getColorForBlend(color!)
                    : ThemeControl.colorForBlend,
                colorBlendMode: BlendMode.plus,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
