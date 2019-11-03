import 'package:app/components/SlideStackRightRoute.dart';
import 'package:flutter/material.dart';

/// @oldRoute needed cause this route transition utilizes `SlideStackRightRoute`
Route createExifRoute(Widget oldRoute) {
  return SlideStackRightRoute(exitPage: oldRoute, enterPage: ExifRoute());
}

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
