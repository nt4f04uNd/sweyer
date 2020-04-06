/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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
    // TODO: move to const
    return SvgPicture.asset(
      'assets/images/icons/note_rounded.svg',
      width: widget.size,
      height: widget.size,
    );
  }
}
