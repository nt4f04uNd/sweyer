/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';

/// Used to constrain min width of action
/// Constraints were copied from flutter framework itself, leading uses them
class SingleAppBarAction extends StatelessWidget {
  final Widget child;
  const SingleAppBarAction({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 56.0),
      child: child,
    );
  }
}
