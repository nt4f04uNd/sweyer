/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

const double _kPreferredSize = 63.0;

/// Creates `Scaffold` with preferred size `AppBar`
class PageBase extends StatelessWidget {
  final Widget child;

  /// Overrides default `SMMBackButton` widget
  final Widget backButton;

  /// Text that will be dispalyed in app bar title
  final String name;

  /// Actions in `AppBar`
  final List<Widget> actions;
  const PageBase({
    Key key,
    @required this.child,
    this.name = "",
    this.actions = const [],
    this.backButton = const SMMBackButton(),
  })  : assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize:
              Size.fromHeight(_kPreferredSize), // here the desired height
          child: AppBar(
            titleSpacing: 0.0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: backButton,
            actions: actions,
            title: Text(
              name,
              style: TextStyle(
                color: Theme.of(context).textTheme.title.color,
                // fontWeight: FontWE
              ),
            ),
          ),
        ),
        body: child,
      ),
    );
  }
}
