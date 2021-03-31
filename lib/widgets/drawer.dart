/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Widget that builds drawer
///
/// todo: rewrite this and add to nt4f04unds_widgets
class DrawerWidget extends StatefulWidget {
  const DrawerWidget({
    Key key,
    this.swipeGesture = trueCallback,
    this.canBeOpened = trueCallback,
  }) : super(key: key);

  /// Function that checks if drawer swipe gesture is enabled.
  final BoolCallback swipeGesture;

  /// Function that checks if drawer can be opened.
  final BoolCallback canBeOpened;

  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget>
    with SingleTickerProviderStateMixin {
  /// Indicates that current route with drawer is ontop and it can take the control
  /// over the ui animations.
  bool _onTop = true;
  SlidableController controller;

  @override
  void initState() {
    super.initState();
    controller = getDrawerControllerProvider(context).controller;
    controller.addStatusListener(_handleControllerStatusChange);
  }

  @override
  void dispose() {
    controller.removeStatusListener(_handleControllerStatusChange);
    super.dispose();
  }

  void _handleControllerStatusChange(AnimationStatus status) {
    // Change system UI on expanding/collapsing the drawer.
    if (_onTop && widget.canBeOpened()) {
      if (status == AnimationStatus.dismissed) {
        SystemUiStyleController.animateSystemUiOverlay(
          to: Constants.UiTheme.grey.auto,
        );
      } else {
        SystemUiStyleController.animateSystemUiOverlay(
          to: Constants.UiTheme.drawerScreen.auto,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canBeOpened() && controller.value > 0.0) {
      controller.reset();
    }

    /// I don't bother myself applying drawer screen ui theme after
    /// the next route pops, like I do for [ShowFunctions.showBottomSheet] for example
    /// because I close the drawer after route push, so there's no way it will be open at this moment.
    return RouteAwareWidget(
      onPushNext: () {
        _onTop = false;
      },
      onPopNext: () {
        _onTop = true;
      },
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Slidable(
          direction: SlideDirection.right,
          start: -304.0 / screenWidth,
          end: 0.0,
          shouldGiveUpGesture: (event) {
            return controller.value == 0.0 &&
                // when on another drag on the right to next tab
                (event.delta.dx < 0.0 ||
                    // when on another tab
                    !widget.swipeGesture() ||
                    // when player route is opened, for example
                    !widget.canBeOpened());
          },
          onBarrierTap: controller.close,
          barrier: Container(color: Colors.black26),
          controller: controller,
          barrierIgnoringStrategy: const IgnoringStrategy(dismissed: true),
          hitTestBehaviorStrategy: const HitTestBehaviorStrategy.opaque(dismissed: HitTestBehavior.translucent),
          child:  Container(
            height: screenHeight,
            width: screenWidth,
            child: Container(
              width: 304.0,
              alignment: Alignment.centerLeft,
              child: _DrawerWidgetContent(controller: controller),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerWidgetContent extends StatefulWidget {
  _DrawerWidgetContent({Key key, @required this.controller}) : super(key: key);
  final SlidableController controller;

  @override
  _DrawerWidgetContentState createState() => _DrawerWidgetContentState();
}

class _DrawerWidgetContentState extends State<_DrawerWidgetContent> {
  double elevation = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    if (widget.controller.value <= 0.01) {
      if (elevation != 0.0) {
        setState(() {
          elevation = 0.0;
        });
      }
    } else {
      if (elevation == 0.0) {
        setState(() {
          elevation = 16.0;
        });
      }
    }
  }

  void _handleClickSettings() {
    widget.controller.close();
    AppRouter.instance.goto(AppRoutes.settings);
  }

  void _handleClickDebug() {
    widget.controller.close();
    AppRouter.instance.goto(AppRoutes.dev);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return Theme(
      data: Theme.of(context).copyWith(
        //This will change the drawer background
        canvasColor: ThemeControl.theme.colorScheme.surface,
      ),
      child: Drawer(
        elevation: elevation,
        child: ListView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              padding:
                  const EdgeInsets.only(left: 22.0, top: 45.0, bottom: 7.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SweyerLogo(),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      Constants.Config.APPLICATION_TITLE,
                      style: TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.w800,
                        color: ThemeControl.theme.textTheme.headline6.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            const SizedBox(
              height: 7.0,
            ),
            MenuItem(
              l10n.settings,
              icon: Icons.settings_rounded,
              onTap: _handleClickSettings,
            ),
            ValueListenableBuilder(
              valueListenable: ContentControl.state.devMode,
              builder: (context, value, child) =>
                  value ? child : const SizedBox.shrink(),
              child: MenuItem(
                l10n.debug,
                icon: Icons.adb_rounded,
                onTap: _handleClickDebug,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double iconSize;
  final double fontSize;
  const MenuItem(
    this.title, {
    Key key,
    this.icon,
    this.onTap,
    this.onLongPress,
    this.iconSize = 22.0,
    this.fontSize = 15.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: NFListTile(
        dense: true,
        leading: icon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: ThemeControl.theme.iconTheme.color,
                ),
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            color: Constants.AppTheme.menuItem.auto,
          ),
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
