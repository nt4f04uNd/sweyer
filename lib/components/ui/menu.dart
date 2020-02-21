/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Widget that builds drawer
class DrawerWidget extends StatefulWidget {
  const DrawerWidget({Key key}) : super(key: key);

  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  Future<void> _handleClickSettings() async {
    try {
      return Navigator.of(context).popAndPushNamed(Constants.Routes.settings.value);
    } catch (e) {}
  }

  // void _handleClickSendLog() => Logger.send();

  Future<void> _handleClickDebug() async {
    try {
      return Navigator.of(context).popAndPushNamed(Constants.Routes.debug.value);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Constants.AppSystemUIThemes.allScreens.auto(context),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: //This will change the drawer background
              Constants.AppTheme.drawer.auto(context),
        ),
        child: Drawer(
          child: ListView(
            physics: NeverScrollableScrollPhysics(),
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.only(left: 22.0, top: 45.0, bottom: 7.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SvgPicture.asset('assets/images/icons/note_rounded.svg',
                        width: 40.0, height: 40.0),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text(
                        'Sweyer',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w800,
                          color: Constants.AppTheme.main.autoInverse(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // SizedBox(height: 45),
              Divider(),
              SizedBox(
                height: 7.0,
              ),
              MenuItem(
                'Настройки',
                icon: Icons.settings,
                onTap: _handleClickSettings,
              ),
              // MenuItem(
              //   'Отправить лог',
              //   icon: Icons.assignment,
              //   onTap: _handleClickSendLog,
              // ),
              MenuItem(
                'Дебаг',
                icon: Icons.adb,
                onTap: _handleClickDebug,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Function onTap;
  final Function onLongPress;
  const MenuItem(
    this.title, {
    Key key,
    this.icon,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListTile(
        dense: true,
        leading: icon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Icon(
                  icon,
                  size: 22.0,
                  color: Constants.AppTheme.mainContrast.auto(context),
                  // color: Constants.AppTheme,
                ),
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.0,
            color: Constants.AppTheme.menuItem.auto(context),
          ),
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

class AnimatedMenuCloseButton extends StatefulWidget {
  AnimatedMenuCloseButton({
    Key key,
    this.animateDirection,
    this.iconSize,
    this.size,
    this.iconColor,
    this.onMenuClick,
    this.onCloseClick,
  }) : super(key: key);

  /// If true, on mount will animate to close icon
  /// Else will animate backwards
  /// If omitted - menu icon will be shown on mount without any animation
  final bool animateDirection;
  final double iconSize;
  final double size;
  final Color iconColor;

  /// Handle click when menu is shown
  final Function onMenuClick;

  /// Handle click when close icon is shown
  final Function onCloseClick;

  AnimatedMenuCloseButtonState createState() => AnimatedMenuCloseButtonState();
}

class AnimatedMenuCloseButtonState extends State<AnimatedMenuCloseButton>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    if (widget.animateDirection != null) {
      if (widget.animateDirection) {
        _animationController.forward();
      } else {
        _animationController.value = 1.0;
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SMMIconButton(
        size: widget.size ?? kSMMIconButtonSize,
        iconSize: widget.iconSize ?? kSMMIconButtonIconSize,
        splashColor: Constants.AppTheme.splash.auto(context),
        color: Constants.AppTheme.mainContrast.auto(context),
        onPressed: widget.animateDirection != null && widget.animateDirection
            ? widget.onCloseClick
            : widget.onMenuClick,
        icon: AnimatedIcon(
          icon: AnimatedIcons.menu_close,
          color: widget.iconColor ??
              Constants.AppTheme.playPauseIcon.auto(context),
          progress: _animationController,
        ),
      ),
    );
  }
}
