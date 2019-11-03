import 'dart:async';

import 'package:app/player/player.dart';
import 'package:app/player/theme.dart';
import 'package:app/routes/exifRoute.dart';
import 'package:app/routes/extendedSettings.dart';
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

import 'constants/colors.dart';
import 'constants/themes.dart';

void main() {
// Color of system bottom navigation bar and status bar
  // SystemChrome.setSystemUIOverlayStyle(AppThemes.darkMainScreen);

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
    return StreamBuilder(
        stream: ThemeControl.onThemeChange,
        builder: (context, snapshot) {
          final themeMode =
              ThemeControl.isDark ? ThemeMode.dark : ThemeMode.light;
          return MaterialApp(
            title: 'Музыка',
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

            themeMode: themeMode,
            theme: AppTheme.materialApp.light,
            darkTheme: AppTheme.materialApp.dark,

            initialRoute: "/",

            onGenerateRoute: (settings) {
              _setCurrentRoute(settings.name);
              // print(_currentRoute);
              if (settings.isInitialRoute) {
                return createRouteTransition(
                  checkExitAnimationEnabled: () =>
                      _currentRouteEquals("/settings"),
                  checkEntAnimationEnabled: () => false,
                  exitCurve: Curves.linearToEaseOut,
                  exitReverseCurve: Curves.fastOutSlowIn,
                  maintainState: true,
                  routeSystemUI: () => AppSystemUIThemes.mainScreen
                      .autoBr(ThemeControl.brightness),
                  enterSystemUI: AppSystemUIThemes.mainScreen
                      .autoBr(ThemeControl.brightness),
                  exitIgnoreEventsReverse: true,
                  exitIgnoreEventsForward: true,
                  transitionDuration: const Duration(milliseconds: 500),
                  route: WillPopScope(
                      child:
                          // AnnotatedRegion<SystemUiOverlayStyle>(
                          //   value: AppSystemUIThemes.mainScreen
                          //       .autoBr(_brightness),
                          //   child:
                          MainRoute(),
                      // ),
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
                  enterSystemUI: AppSystemUIThemes.allScreens
                      .autoBr(ThemeControl.brightness),
                  exitSystemUI: () => AppSystemUIThemes.mainScreen
                      .autoBr(ThemeControl.brightness),
                  transitionDuration: const Duration(milliseconds: 500),
                  route: PlayerRoute(),
                );
              } else if (settings.name == "/settings") {
                return createRouteTransition(
                  transitionDuration: const Duration(milliseconds: 500),
                  enterSystemUI: AppSystemUIThemes.allScreens
                      .autoBr(ThemeControl.brightness),
                  exitSystemUI: () => AppSystemUIThemes.mainScreen
                      .autoBr(ThemeControl.brightness),
                  exitCurve: Curves.linearToEaseOut,
                  exitReverseCurve: Curves.fastOutSlowIn,
                  entCurve: Curves.linearToEaseOut,
                  entReverseCurve: Curves.fastOutSlowIn,
                  entIgnoreEventsForward: true,
                  exitIgnoreEventsReverse: true,
                  exitIgnoreEventsForward: true,
                  route: SettingsRoute(),
                );
              } else if (settings.name == "/extendedSettings") {
                return createRouteTransition(
                  transitionDuration: const Duration(milliseconds: 500),
                  enterSystemUI: AppSystemUIThemes.allScreens
                      .autoBr(ThemeControl.brightness),
                  exitSystemUI: () => AppSystemUIThemes.allScreens
                      .autoBr(ThemeControl.brightness),
                  entCurve: Curves.linearToEaseOut,
                  entReverseCurve: Curves.fastOutSlowIn,
                  exitIgnoreEventsReverse: true,
                  exitIgnoreEventsForward: true,
                  route: ExtendedSettingsRoute(),
                );
              } else if (settings.name == "/exif") {
                return createRouteTransition(
                  transitionDuration: const Duration(milliseconds: 500),
                  entCurve: Curves.linearToEaseOut,
                  entReverseCurve: Curves.fastOutSlowIn,
                  route: AnnotatedRegion<SystemUiOverlayStyle>(
                    value: AppSystemUIThemes.allScreens
                        .autoBr(ThemeControl.brightness),
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
        });
  }
}
