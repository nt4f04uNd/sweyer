import 'package:app/components/buttons.dart';
import 'package:app/constants/routes.dart';
import 'package:app/player/theme.dart';
import 'package:flutter/material.dart';

class SettingsRoute extends StatefulWidget {
  const SettingsRoute({Key key}) : super(key: key);

  @override
  _SettingsRouteState createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<SettingsRoute> {
  bool _switched;

  @override
  void initState() {
    super.initState();
    _switched = ThemeControl.isDark;
  }

  void _switchTheme() {
    setState(() {
      ThemeControl.switchTheme(true);
      _switched = !_switched;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(63.0), // here the desired height
        child: AppBar(
          titleSpacing: 0.0,
          backgroundColor: Colors.transparent,
          title: Text("Настройки",
              style: TextStyle(color: Theme.of(context).textTheme.title.color)),
          leading:CustomBackButton(),
          automaticallyImplyLeading: false,
        ),
      ),
      body: Container(
        child: ListView(
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            ListTile(
              title: Text("Расширенные настройки"),
              onTap: () {
                Navigator.of(context).pushNamed(Routes.extendedSettings.value);
              },
            ),
            GestureDetector(
              onTap: _switchTheme,
              child: ListTile(
                title: Text("Темная тема"),
                trailing: Switch(
                  activeColor: Theme.of(context).primaryColor,
                  value: _switched,
                  onChanged: (value) {
                    _switchTheme();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
