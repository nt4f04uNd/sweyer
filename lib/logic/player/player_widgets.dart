/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'player.dart';
import 'package:flutter/material.dart';

/// Component to show artist, or automatically show "Неизвестный исполнитель" instead of "<unknown>"
class Artist extends StatelessWidget {
  final String artist;
  final TextStyle textStyle;
  const Artist({Key key, @required this.artist, this.textStyle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(
        artistString(artist),
        overflow: TextOverflow.ellipsis,
        style:  TextStyle(
          //Default flutter subtitle font size (not densed)
          fontSize: 13.5,
          // This is used in ListTile elements
          color: Theme.of(context).textTheme.caption.color,
          // fontWeight: ThemeControl.isDark ? FontWeight.w300 : FontWeight.w600,
          height: 0.9
        ).merge(textStyle),
      ),
    );
  }
}
