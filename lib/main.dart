import 'package:app/player/player.dart';
import 'package:app/routes/exifRoute.dart';
import 'package:app/routes/mainRoute.dart';
import 'package:app/routes/playerRoute.dart';
import 'package:app/routes/settingsRoute.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:catcher/catcher_plugin.dart';
import 'package:app/components/route_transitions.dart';

void main() {
// Color of system bottom navigation bar and status bar
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xff262626), // navigation bar color
    statusBarColor: Colors.transparent, // status bar color
  ));

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
  static final nativeTheme = SystemUiOverlayStyle(
    // systemNavigationBarColor: Colors.grey.shade900, // navigation bar color
    systemNavigationBarColor: Colors.grey.shade900, // navigation bar color
    statusBarColor: Colors.transparent, // status bar color
  );
  static const nativeThemeMainScreen = SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xff262626), // navigation bar color
    statusBarColor: Colors.transparent, // status bar color
  );

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
      // color: Colors.grey.shade900,
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
        // appBarTheme: AppBarTheme(color: Colors.black, elevation: 0,),
        appBarTheme: AppBarTheme(
          color: Colors.grey.shade900,
          elevation: 0,
        ),
        // scaffoldBackgroundColor: Colors.black,
        scaffoldBackgroundColor: Colors.grey.shade900,
        brightness: Brightness.dark,
        accentColor: Colors.grey.shade900,
        backgroundColor: Colors.grey.shade900,
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
          return createRouteTransition(
            checkExitAnimationEnabled: () => _currentRouteEquals("/settings"),
            checkEntAnimationEnabled: () => false,
            exitCurve: Curves.linearToEaseOut,
            exitReverseCurve: Curves.fastOutSlowIn,
            maintainState: true,
            enterSystemUI: nativeThemeMainScreen,
            transitionDuration: const Duration(milliseconds: 500),
            route: WillPopScope(
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: nativeThemeMainScreen,
                  child: MainRoute(),
                ),
                onWillPop: _handleHomePop),
          );
        } else if (settings.name == "/player") {
          return createRouteTransition(
            playMaterial: true,
            entCurve: Curves.fastOutSlowIn,
            exitCurve: Curves.linearToEaseOut,
            exitReverseCurve: Curves.fastOutSlowIn,
            entBegin: Offset(0.0, 1.0),
            checkExitAnimationEnabled: () => _currentRouteEquals("/exif"),
            opaque: false,
            enterSystemUI: nativeTheme,
            exitSystemUI: nativeThemeMainScreen,
            exitIgnoreEventsForward: true,
            transitionDuration: const Duration(milliseconds: 500),
            route: PlayerRoute(),
          );
        } else if (settings.name == "/settings") {
          return createRouteTransition(
             transitionDuration: const Duration(milliseconds: 500),
            enterSystemUI: nativeTheme,
            exitSystemUI: nativeThemeMainScreen,
            entCurve: Curves.linearToEaseOut,
            entReverseCurve: Curves.fastOutSlowIn,
            route: SettingsRoute(),
          );
        } else if (settings.name == "/exif") {
          return createRouteTransition(
             transitionDuration: const Duration(milliseconds: 500),
            entCurve: Curves.linearToEaseOut,
            entReverseCurve: Curves.fastOutSlowIn,
            route: AnnotatedRegion<SystemUiOverlayStyle>(
              value: nativeTheme,
              child: ExifRoute(),
            ),
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
