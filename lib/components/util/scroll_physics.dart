/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/


import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

class FMMBouncingScrollPhysics extends BouncingScrollPhysics {
  /// Creates scroll physics that bounce back from the edge.
  const FMMBouncingScrollPhysics({ ScrollPhysics parent }) : super(parent: parent);
 @override
  FMMBouncingScrollPhysics applyTo(ScrollPhysics ancestor) {
    return FMMBouncingScrollPhysics(parent: buildParent(ancestor));
  }

@override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity.sign *
        math.min(0.000816 * math.pow(existingVelocity.abs(), 1.967).toDouble(), 20000.0);
  }


}
