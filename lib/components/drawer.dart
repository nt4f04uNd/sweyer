import 'package:app/components/custom_icon_button.dart';
import 'package:app/constants/routes.dart';
import 'package:app/constants/themes.dart';
import 'package:app/player/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Drawer icon button to place in `AppBar`
class DrawerButton extends StatelessWidget {
  const DrawerButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomIconButton(
      icon: Icon(Icons.menu),
      splashColor: AppTheme.splash.auto(context),
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
      await Navigator.of(context).popAndPushNamed(Routes.settings.value);

  void _handleClickSendLog() => Logger.send();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUIThemes.allScreens.auto(context),
      child: Drawer(
        child: ListView(
          physics: NeverScrollableScrollPhysics(),
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              padding:
                  const EdgeInsets.only(left: 18.0, top: 60.0, bottom: 20.0),
              child: Text('Меню', style: TextStyle(fontSize: 35.0)),
            ),
            ListTile(
                leading: Icon(
                  Icons.settings,
                  color: AppTheme.drawerListItem.auto(context),
                ),
                title: Text('Настройки',
                    style: TextStyle(
                        fontSize: 17.0,
                        color: AppTheme.drawerListItem.auto(context))),
                onTap: _handleClickSettings),
            ListTile(
                leading: Icon(Icons.assignment,
                    color: AppTheme.drawerListItem.auto(context)),
                title: Text('Отправить лог',
                    style: TextStyle(
                        fontSize: 17.0,
                        color: AppTheme.drawerListItem.auto(context))),
                onTap: _handleClickSendLog),
          ],
        ),
      ),
    );
  }
}
