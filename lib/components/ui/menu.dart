/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_music_player/flutter_music_player.dart';
import 'package:flutter_music_player/constants.dart' as Constants;

/// Drawer icon button to place in `AppBar`
class DrawerButton extends StatelessWidget {
  const DrawerButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomIconButton(
      icon: Icon(Icons.menu),
      splashColor: Constants.AppTheme.splash.auto(context),
      color: Theme.of(context).iconTheme.color,
      onPressed: Scaffold.of(context).openDrawer,
    );
  }
}

/// Widget that builds drawer
class DrawerWidget extends StatefulWidget {
  const DrawerWidget({Key key}) : super(key: key);

  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  Future<void> _handleClickSettings() async =>
      await Navigator.of(context).popAndPushNamed(Constants.Routes.settings.value);

  void _handleClickSendLog() => Logger.send();

  void _handleClickDebug() async =>
      await Navigator.of(context).popAndPushNamed(Constants.Routes.debug.value);

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
                        'Музыка',
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
              MenuItem(
                'Отправить лог',
                icon: Icons.assignment,
                onTap: _handleClickSendLog,
              ),
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
                child: Icon(icon,
                    size: 22.0, color: Constants.AppTheme.menuItemIcon.auto(context)),
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
