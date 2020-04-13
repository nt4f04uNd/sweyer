/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Creates a SVG Sweyer logo
class SweyerLogo extends StatefulWidget {
  const SweyerLogo({
    Key key,
    this.size = 40.0,
  }) : super(key: key);
  final double size;
  @override
  _SweyerLogoState createState() => _SweyerLogoState();
}

class _SweyerLogoState extends State<SweyerLogo> {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Constants.Paths.ASSET_LOGO_SVG,
      width: widget.size,
      height: widget.size,
    );
  }
}
