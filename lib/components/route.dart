/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter_music_player/components/buttons.dart';
import 'package:flutter/material.dart';

/// Creates `Scaffold` with preferred size `AppBar`
class RouteBase extends StatelessWidget {
  final Widget child;

  /// Text that will be dispalyed in app bar title
  final String name;

  /// Actions in `AppBar`
  final List<Widget> actions;
  const RouteBase({
    Key key,
    @required this.child,
    this.name = "",
    this.actions = const [],
  })  : assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(63.0), // here the desired height
          child: AppBar(
            titleSpacing: 0.0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: CustomBackButton(),
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
