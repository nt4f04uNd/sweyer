/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

/// Will draw ink well with taking the splash color and splash factory from theme
class SMMInkWell extends StatelessWidget {
  const SMMInkWell({
    Key key,
    this.child,
    this.borderRadius,
    this.splashColor,
    this.onTap,
  }) : super(key: key);
  final Widget child;
  final BorderRadius borderRadius;
  final Color splashColor;
  final Function onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: child,
      splashColor: splashColor ?? Theme.of(context).splashColor,
      borderRadius: borderRadius,
      splashFactory: ListTileInkRipple.splashFactory,
      onTap: onTap,
    );
  }
}
