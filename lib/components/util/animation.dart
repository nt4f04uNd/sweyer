/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';

/// Creates a usual for SMM curved animation which is:
/// 
/// Curve [Curves.easeOutCubic].
/// 
/// Reverse Ccrve [Curves.easeInCubic].
class SMMDefaultAnimation extends CurvedAnimation {
  SMMDefaultAnimation({
    Curve curve = Curves.easeOutCubic,
    Curve reverseCurve = Curves.easeInCubic,
    @required Animation parent,
  }) : super(curve: curve, reverseCurve: reverseCurve, parent: parent);
}
