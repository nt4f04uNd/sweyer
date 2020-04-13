/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class SelectionAppBar extends AppBar {
  SelectionAppBar({
    Key key,
    @required SelectionController selectionController,
    @required Widget title,

    /// Title to show in selection
    @required Widget titleSelection,
    @required List<Widget> actions,

    /// Actions to show in selection
    @required List<Widget> actionsSelection,

    /// Go to selection animation
    Curve curve = Curves.easeOutCubic,

    /// Back from selection animation
    Curve reverseCurve = Curves.easeInCubic,
    bool automaticallyImplyLeading = true,
    Widget flexibleSpace,
    PreferredSizeWidget bottom,
    double elevation = 2.0,

    /// Elevation in selection
    double elevationSelection = 2.0,
    ShapeBorder shape,
    Color backgroundColor,
    Brightness brightness,
    IconThemeData iconTheme,
    IconThemeData actionsIconTheme,
    TextTheme textTheme,
    bool primary = true,
    bool centerTitle,
    bool excludeHeaderSemantics = false,
    double titleSpacing = NavigationToolbar.kMiddleSpacing,
    double toolbarOpacity = 1.0,
    double bottomOpacity = 1.0,
  }) : super(
          key: key,
          leading: AnimatedBuilder(
            animation: selectionController.animationController,
            builder: (BuildContext context, Widget child) {
              final bool inSelection = !selectionController.wasEverSelected
                  ? null
                  : selectionController.inSelection;
              return AnimatedMenuCloseButton(
                key: ValueKey(inSelection),
                animateDirection: inSelection,
                onCloseClick: selectionController.close,
                onMenuClick: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          title: AnimationSwitcher(
            animation: CurvedAnimation(
              curve: curve,
              reverseCurve: reverseCurve,
              parent: selectionController.animationController,
            ),
            child1: title,
            child2: titleSelection,
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 5.0, right: 5.0),
              child: AnimationSwitcher(
                animation: CurvedAnimation(
                  curve: curve,
                  reverseCurve: reverseCurve,
                  parent: selectionController.animationController,
                ),
                child1: Row(children: actions),
                child2: Row(children: actionsSelection),
              ),
            ),
          ],
          automaticallyImplyLeading: automaticallyImplyLeading,
          flexibleSpace: flexibleSpace,
          bottom: bottom,
          elevation:
              selectionController.inSelection ? elevationSelection : elevation,
          shape: shape,
          backgroundColor: backgroundColor,
          brightness: brightness,
          iconTheme: iconTheme,
          actionsIconTheme: actionsIconTheme,
          textTheme: textTheme,
          primary: primary,
          centerTitle: centerTitle,
          excludeHeaderSemantics: excludeHeaderSemantics,
          titleSpacing: titleSpacing,
          toolbarOpacity: toolbarOpacity,
          bottomOpacity: bottomOpacity,
        );
}
