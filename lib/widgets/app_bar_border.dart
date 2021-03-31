/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';

/// Themed border divider that can be shown and hidden with animation.
/// 
/// Used in list views when they are scrolled and displayed below the [AppBar],
/// instead of elevation.
class AppBarBorder extends StatelessWidget {
  const AppBarBorder({Key key, this.shown = true}) : super(key: key);

  final bool shown;

  static const height = 1.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 400),
      color: shown
          // ? theme.colorScheme.secondary
          ? Color(0xff191b1a)
          : theme.colorScheme.secondary.withOpacity(0.0),
      height: height,
    );
  }
}