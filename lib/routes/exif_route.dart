/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';


class ExifRoute extends StatefulWidget {
  const ExifRoute({Key key}) : super(key: key);

  @override
  _ExifRouteState createState() => _ExifRouteState();
}

class _ExifRouteState extends State<ExifRoute> {
  TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: 'Имя трека');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(63.0), // here the desired height
        child: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          // actions: <Widget>[
          //   IconButton(
          //     icon: Icon(Icons.more_vert),
          //     onPressed: () => Navigator.pop(context),
          //   ),
          // ],
          automaticallyImplyLeading: false,
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 7.0),
              child: Text('Название'),
            ),
            Flexible(
              child: TextField(controller: _textController),
            ),
          ],
        ),
      ),
    );
  }
}
