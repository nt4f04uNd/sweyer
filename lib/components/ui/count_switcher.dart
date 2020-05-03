/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';

/// A widget that shows a widget and when it changes, based on given conditions,
/// it will perform top-to-down stack/fade animation (usually, when, e.g. new number is greater than the prev),
/// or same down-to-bot animation
///
/// Perfect for showing number counters.
class CountSwitcher extends StatelessWidget {
  const CountSwitcher({
    Key key,
    this.childKey,
    this.child,
    this.valueIncreased = true,
  }) : super(key: key);

  /// A key that will be applied to the child widget.
  ///
  /// Can be used to lock the switch animation.
  final Key childKey;
  final Widget child;

  /// `true` will play top-to-down animation, `false` vice-versa
  final bool valueIncreased;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 20.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final baseAnimation = CurvedAnimation(
            curve: Curves.easeOut,
            parent: animation,
          );
          final baseReversedAnimation = CurvedAnimation(
            curve: Curves.easeIn,
            parent: animation,
          );

          final inForwardAnimation = Tween<Offset>(
            begin: const Offset(0.0, -0.7),
            end: const Offset(0.0, 0.0),
          ).animate(baseAnimation);

          final inBackAnimation = Tween<Offset>(
            begin: const Offset(0.0, 0.7),
            end: const Offset(0.0, 0.0),
          ).animate(baseAnimation);

          final outForwardAnimation = Tween<Offset>(
            begin: const Offset(0.0, 0.7),
            end: const Offset(0.0, 0.0),
          ).animate(baseReversedAnimation);

          final outBackAnimation = Tween<Offset>(
            begin: const Offset(0.0, -0.7),
            end: const Offset(0.0, 0.0),
          ).animate(baseReversedAnimation);

          //* For entering widget
          if (child.key == childKey) {
            if (valueIncreased)
              return SlideTransition(
                position: inForwardAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            else
              return SlideTransition(
                position: inBackAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
          }
          //* For exiting widget
          else {
            if (valueIncreased) {
              return SlideTransition(
                position: outForwardAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            } else
              return SlideTransition(
                position: outBackAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
          }
        },
        child: Container(
          key: childKey,
          child: child,
        ),
      ),
    );
  }
}
