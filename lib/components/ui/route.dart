/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

// const double kSMMAppBarPreferredSize = 63.0;
const double kSMMAppBarPreferredSize = 52.0;

/// Creates [Scaffold] with preferred size [AppBar]
class PageBase extends StatelessWidget {
  final Widget child;

  /// Text that will be displayed in app bar title
  final String name;
  final Color backgroundColor;
  final Color appBarBackgroundColor;
final double appBarElevation;
  /// Actions in [AppBar]
  final List<Widget> actions;

  /// Overrides default [SMMBackButton] widget
  final Widget backButton;

  const PageBase({
    Key key,
    @required this.child,
    this.name = "",
    this.backgroundColor,
    this.appBarBackgroundColor,
    this.appBarElevation,
    this.actions = const [],
    this.backButton = const SMMBackButton(),
  })  : assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(kSMMAppBarPreferredSize), // here the desired height
        child: AppBar(
          elevation: appBarElevation,
          titleSpacing: 0.0,
          automaticallyImplyLeading: false,
          backgroundColor: appBarBackgroundColor,
          leading: backButton,
          actions: actions,
          title: Text(
            name,
            style:  Theme.of(context).appBarTheme.textTheme.headline6.copyWith(fontSize:21.0,),
            // TextStyle(
            //   color: Theme.of(context).textTheme.headline6.color,
            //   fontWeight: FontWeight.w600,
            //   fontSize:22.0,
            //   // fontWeight: FontWE
            // ),
          ),
        ),
      ),
      body: child,
    );
  }
}

/// Creates [Scaffold] with preferred size [AppBar]
///
/// Also receives the color animation to change the background color
class AnimatedPageBase extends AnimatedWidget {
  final Widget child;
  final Animation<Color> animation;

  /// Text that will be displayed in app bar title
  final String name;
  final Color backgroundColor;

  /// Actions in [AppBar]
  final List<Widget> actions;

  /// Overrides default [SMMBackButton] widget
  final Widget backButton;

  const AnimatedPageBase({
    Key key,
    @required this.child,
    @required this.animation,
    this.name = "",
    this.backgroundColor,
    this.actions = const [],
    this.backButton = const SMMBackButton(),
  })  : assert(child != null),
        super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: animation.value,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(kSMMAppBarPreferredSize), // here the desired height
        child: AppBar(
          titleSpacing: 0.0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: backButton,
          actions: actions,
          title: Text(
            name,
            style: TextStyle(
              color: Theme.of(context).textTheme.headline6.color,
              // fontWeight: FontWE
            ),
          ),
        ),
      ),
      body: child,
    );
  }
}
