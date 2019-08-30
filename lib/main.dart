import 'package:app/components/search.dart';
import 'package:app/routes/mainRoute.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  DateTime currentBackPressTime;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(brightness: Brightness.dark, accentColor: Colors.black),
      home: WillPopScope(child: MainRoute(), onWillPop: onWillPop),
      // home: WillPopScope(child: SearchDemo(), onWillPop: onWillPop),
    );
  }

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(
          msg: 'Нажмите еще раз для выхода',
          backgroundColor: Color.fromRGBO(18, 18, 18, 1));
      return Future.value(false);
    }
    return Future.value(true);
  }
}
