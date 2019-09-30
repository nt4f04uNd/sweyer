import 'package:app/player/player.dart';
import 'package:app/routes/mainRoute.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:catcher/catcher_plugin.dart';

void main() {
  CatcherOptions debugOptions =
      CatcherOptions(DialogReportMode(), [ConsoleHandler()]);
  CatcherOptions releaseOptions = CatcherOptions(DialogReportMode(), [
    EmailManualHandler(["nt4f04uNd@gmail.com"])
  ]);

  Catcher(MyApp(), debugConfig: debugOptions, releaseConfig: releaseOptions);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DateTime currentBackPressTime;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Catcher.navigatorKey,
      // Uncomment to replace red screen of death 
      builder: (BuildContext context, Widget widget) {
        // Catcher.addDefaultErrorWidget(
        //     showStacktrace: true,
        //     customTitle: "Custom error title",
        //     customDescription: "Custom error description");
        return widget;
      },
      supportedLocales: [const Locale('ru')],
      locale: Locale('ru'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      title: 'Музыка',
      theme: ThemeData(
        // appBarTheme: AppBarTheme(color: Color(0xff070707)),
        appBarTheme: AppBarTheme(color: Colors.black),
        brightness: Brightness.dark,
        accentColor: Colors.grey.shade900,
        backgroundColor: Colors.black,
        primaryColor: Colors.deepPurple,
        bottomSheetTheme: BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          backgroundColor: Color(0xff070707),
        ),
        scaffoldBackgroundColor: Colors.black,
        textSelectionColor: Colors.deepPurple,
        textSelectionHandleColor: Colors.deepPurple,
      ),
      home: WillPopScope(child: MainRoute(), onWillPop: onWillPop),
    );
  }

  Future<bool> onWillPop() async {
    DateTime now = DateTime.now();
    // Show toast when user presses back button on main route, that asks from user to press again to confirm that he wants to quit the app
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(
          msg: 'Нажмите еще раз для выхода',
          backgroundColor: Color.fromRGBO(18, 18, 18, 1));
      return Future.value(false);
    }
    // Stop player before exiting app
    await MusicPlayer.instance.stop();
    return Future.value(true);
  }
}
