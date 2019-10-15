import 'package:app/player/player.dart';
import 'package:app/routes/exifRoute.dart';
import 'package:app/routes/mainRoute.dart';
import 'package:app/routes/playerRoute.dart';
import 'package:app/routes/settingsRoute.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:catcher/catcher_plugin.dart';
import 'package:app/components/route_transitions.dart';

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
  /// Needed to disable animations on some routes
  String _currentRoute = "/";

  // Var to show toast in `_handleHomePop`
  DateTime _currentBackPressTime;

  @override
  void dispose() {
    MusicPlayer.stop();
    super.dispose();
  }

  /// Changes the value of `_currentRoute`
  void _setCurrentRoute(String newValue) {
    _currentRoute = newValue;
  }

  /// Check the equality of `_currentRoute` to some value
  bool _currentRouteEquals(String value) {
    return _currentRoute == value;
  }

  /// Handles pop in main '/' route and shows user toast
  Future<bool> _handleHomePop() async {
    DateTime now = DateTime.now();
    // Show toast when user presses back button on main route, that asks from user to press again to confirm that he wants to quit the app
    if (_currentBackPressTime == null ||
        now.difference(_currentBackPressTime) > Duration(seconds: 2)) {
      _currentBackPressTime = now;
      Fluttertoast.showToast(
          msg: 'Нажмите еще раз для выхода',
          backgroundColor: Color.fromRGBO(18, 18, 18, 1));
      return Future.value(false);
    }
    // Stop player before exiting app
    await MusicPlayer.stop();
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Catcher.navigatorKey,

      // Uncomment to replace red screen of death
      builder: (BuildContext context, Widget widget) {
        // Catcher.addDefaultErrorWidget(
        //     showStacktrace: true,
        //     customTitle: "Custom error title",
        //     customDescription: "Custom error description",
        //     );
        return widget;
      },
      supportedLocales: [const Locale('ru')],
      locale: const Locale('ru'),
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
        cursorColor: Colors.deepPurple,
      ),
      // home: WillPopScope(child: MainRoute(), onWillPop: onWillPop),
      initialRoute: "/",
      onGenerateRoute: (settings) {
        _setCurrentRoute(settings.name);
        print(_currentRoute);

        if (settings.isInitialRoute) {
          return createRouteTransition<WillPopScope>(
            checkExitAnimationEnabled: () => _currentRouteEquals("/settings"),
            checkEntAnimationEnabled: () => false,
            exitCurve: Curves.linearToEaseOut,
            exitReverseCurve: Curves.easeInToLinear,
            maintainState: true,
            route: WillPopScope(child: MainRoute(), onWillPop: _handleHomePop),
          );
        } else if (settings.name == "/player") {
          return createRouteTransition<PlayerRoute>(
            entCurve: Curves.linearToEaseOut,
            entReverseCurve: Curves.fastOutSlowIn,
            exitCurve: Curves.linearToEaseOut,
            exitReverseCurve: Curves.easeInToLinear,
            entBegin: Offset(0.0, 1.0),
            entIgnoreEvents: true,
            checkExitAnimationEnabled: () => _currentRouteEquals("/exif"),
            transitionDuration: const Duration(milliseconds: 500),
            route: PlayerRoute(),
          );
        } else if (settings.name == "/settings") {
          return createRouteTransition<SettingsRoute>(
            entCurve: Curves.linearToEaseOut,
            entReverseCurve: Curves.easeInToLinear,
            route: SettingsRoute(),
          );
        } else if (settings.name == "/exif") {
          return createRouteTransition<ExifRoute>(
            entCurve: Curves.linearToEaseOut,
            entReverseCurve: Curves.easeInToLinear,
            route: ExifRoute(),
          );
        } else if (settings.name == "/search") {
          return (settings.arguments as Map<String, Route>)["route"];
        }
        // FIXME: add unknown route
        return null;
      },
    );
  }
}
