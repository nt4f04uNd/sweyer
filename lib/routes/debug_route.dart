/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter_music_player/flutter_music_player.dart';
import 'package:flutter_music_player/api.dart' as API;
import 'package:flutter/material.dart';

class DebugRoute extends StatelessWidget {
  const DebugRoute({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageBase(
      name: "Дебаг",
      child: Container(
        child: ListView(
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            ListTile(
              title: Text('Остановить сервис'),
              onTap: () {
                API.ServiceHandler.stopService();
              },
            ),
          ],
        ),
      ),
    );
  }
}
