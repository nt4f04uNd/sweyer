/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter_music_player/flutter_music_player.dart';
import 'package:flutter_music_player/constants.dart' as Constants;
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
    return PageBase(
      name: "Настройки",
      child: Container(
        child: ListView(
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            ListTile(
              title: Text('Расширенные настройки'),
              onTap: () {
                Navigator.of(context)
                    .pushNamed(Constants.Routes.extendedSettings.value);
              },
            ),
            SwitchListTile(
              title: Text("Темная тема"),
              activeColor: Theme.of(context).primaryColor,
              value: _switched,
              onChanged: (value) {
                _switchTheme();
              },
            )
          ],
        ),
      ),
    );
  }
}
