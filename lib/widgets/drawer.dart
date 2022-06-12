import 'dart:math';

import 'package:flutter/material.dart';

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Widget that builds drawer.
class DrawerWidget extends StatefulWidget {
  const DrawerWidget({Key? key}) : super(key: key);

  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  /// Indicates that current route with drawer is ontop and it can take the control
  /// over the ui animations.
  bool _onTop = true;
  late SlidableController controller;

  @override
  void initState() {
    super.initState();
    controller = drawerController;
    controller.addStatusListener(_handleControllerStatusChange);
  }

  @override
  void dispose() {
    controller.removeStatusListener(_handleControllerStatusChange);
    super.dispose();
  }

  void _handleControllerStatusChange(AnimationStatus status) {
    // Change system UI on expanding/collapsing the drawer.
    if (_onTop) {
      if (status == AnimationStatus.dismissed) {
        SystemUiStyleController.instance.animateSystemUiOverlay(
          to: Constants.UiTheme.grey.auto,
        );
      } else {
        SystemUiStyleController.instance.animateSystemUiOverlay(
          to: Constants.UiTheme.drawerScreen.auto,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!HomeRouter.instance.drawerCanBeOpened && controller.value > 0.0) {
      controller.reset();
    }

    final screenWidth = MediaQuery.of(context).size.width;

    /// I don't bother myself applying drawer screen ui theme after
    /// the next route pops, like I do for [ShowFunctions.showBottomSheet] for example
    /// because I close the drawer after route push, so there's no way it will be open at this moment.
    return RouteAwareWidget(
      onPushNext: () => _onTop = false,
      onPopNext: () => _onTop = true,
      child: Slidable(
        direction: SlideDirection.right,
        start: -304.0 / screenWidth,
        end: 0.0,
        shouldGiveUpGesture: (event) {
          return controller.value == 0.0 &&
              // when on another drag on the right to next tab
              (event.delta.dx < 0.0 ||
                // when player route is opened, for example
                !HomeRouter.instance.drawerCanBeOpened);
        },
        onBarrierTap: controller.close,
        barrier: Container(color: Colors.black26),
        controller: controller,
        barrierIgnoringStrategy: const IgnoringStrategy(dismissed: true),
        hitTestBehaviorStrategy: const HitTestBehaviorStrategy.opaque(dismissed: HitTestBehavior.translucent),
        child: SizedBox.expand(
          child: Container(
            width: 304.0,
            alignment: Alignment.centerLeft,
            child: _DrawerWidgetContent(controller: controller),
          ),
        ),
      ),
    );
  }
}

class _DrawerWidgetContent extends StatefulWidget {
  _DrawerWidgetContent({Key? key, required this.controller}) : super(key: key);
  final SlidableController? controller;

  @override
  _DrawerWidgetContentState createState() => _DrawerWidgetContentState();
}

class _DrawerWidgetContentState extends State<_DrawerWidgetContent> {
  /// Status bar height on my phone.
  static const _baseTopPadding = 24.0;
  double elevation = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller!.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    widget.controller!.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    if (widget.controller!.value <= 0.01) {
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
    widget.controller!.close();
    AppRouter.instance.goto(AppRoutes.settings);
  }

  void _handleClickDebug() {
    widget.controller!.close();
    AppRouter.instance.goto(AppRoutes.dev);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return Theme(
      data: Theme.of(context).copyWith(
        //This will change the drawer background
        canvasColor: ThemeControl.instance.theme.colorScheme.surface,
      ),
      child: Drawer(
        elevation: elevation,
        child: Padding(
          padding: EdgeInsets.only(top: max(0, MediaQuery.of(context).padding.top - _baseTopPadding)),
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(left: 22.0, top: 45.0, bottom: 7.0),
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
                          color: ThemeControl.instance.theme.textTheme.headline6!.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 7.0),
              DrawerMenuItem(
                l10n.settings,
                icon: Icons.settings_rounded,
                onTap: _handleClickSettings,
              ),
              ValueListenableBuilder<bool>(
                valueListenable: Prefs.devMode,
                builder: (context, value, child) => value ? child! : const SizedBox.shrink(),
                child: DrawerMenuItem(
                  l10n.debug,
                  icon: Icons.adb_rounded,
                  onTap: _handleClickDebug,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerMenuItem extends StatelessWidget {
  const DrawerMenuItem(
    this.title, {
    Key? key,
    this.icon,
    this.onTap,
    this.onLongPress,
    this.iconSize = 22.0,
    this.fontSize = 15.0,
  }) : super(key: key);

  final IconData? icon;
  final String title;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return NFListTile(
      dense: true,
      leading: icon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Icon(
                icon,
                size: iconSize,
                color: ThemeControl.instance.theme.iconTheme.color,
              ),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          color: Constants.Theme.drawerMenuItemColor.auto,
        ),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
