/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';

class SMMBouncingScrollPhysics extends BouncingScrollPhysics {
  /// Creates scroll physics that bounce back from the edge.
  const SMMBouncingScrollPhysics({ScrollPhysics parent})
      : super(parent: parent);
  @override
  SMMBouncingScrollPhysics applyTo(ScrollPhysics ancestor) {
    return SMMBouncingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get maxFlingVelocity => kMaxFlingVelocity;

  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity.sign *
        math.min(
          0.000816 * math.pow(existingVelocity.abs(), 1.967).toDouble(),
          kMaxFlingVelocity,
        );
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;
}

/// Default scroll behavior, but doesn't have glow effect on overscroll
class SMMScrollBehaviorGlowless extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}