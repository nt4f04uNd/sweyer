/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:isolate';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/api.dart' as API;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'routes/routes.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';

final RouteObserver<Route> routeObserver = RouteObserver();
final RouteObserver<Route> homeRouteObserver = RouteObserver();

/// Builds up the error report message from the exception and stacktrace.
String buildErrorReport(dynamic ex, dynamic stack) {
  return '''$ex
                      
$stack''';
}

Future<void> reportError(dynamic ex, StackTrace stack) async {
  if (await Prefs.devModeBool.get()) {
    ShowFunctions.instance.showError(
      errorDetails: buildErrorReport(ex, stack),
    );
  }
  await FirebaseCrashlytics.instance.recordError(
    ex,
    stack,
  );
}

Future<void> reportFlutterError(FlutterErrorDetails details) async {
  if (await Prefs.devModeBool.get()) {
    ShowFunctions.instance.showError(
      errorDetails: buildErrorReport(details.exception, details.stack),
    );
  }
  await FirebaseCrashlytics.instance.recordFlutterError(details);
}

void main() async {
  // Disabling automatic system UI adjustment, which causes system nav bar
  // color to be reverted to black when the bottom player route is being expanded.
  //
  // Related to https://github.com/flutter/flutter/issues/40590
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  binding.renderView.automaticSystemUiAdjustment = false;

  await Firebase.initializeApp();
  if (kDebugMode) {
    // Force disable Crashlytics collection while doing every day development.
    // Temporarily toggle this to true if you want to test crash reporting in your app.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
  Isolate.current.addErrorListener(RawReceivePort((pair) async {
    final List<dynamic> errorAndStacktrace = pair;
    await reportError(errorAndStacktrace.first, errorAndStacktrace.last);
  }).sendPort);
  FlutterError.onError = reportFlutterError;
  runZonedGuarded<Future<void>>(() async {
    // Add callback to stop service when app is destroyed, temporary
    WidgetsBinding.instance.addObserver(
      NFWidgetsBindingObserver(
        // ignore: missing_return
        onResumed: () {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarIconBrightness: ThemeControl.contrastBrightness,
              systemNavigationBarIconBrightness:
                  ThemeControl.contrastBrightness,
            ),
          );
        },
      ),
    );

    API.EventsHandler.init();
    await ThemeControl.init();
    ThemeControl.initSystemUi();
    await Permissions.init();
    await Future.wait([
      ContentControl.init(),
      MusicPlayer.init(),
    ]);
    runApp(App());
  }, reportError);
}

class App extends StatefulWidget {
  /// A global key to obtain the roote navigator.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  /// A global key to obtain sub navigator on home page.
  static final GlobalKey<NavigatorState> homeNavigatorKey = GlobalKey();

  static void rebuildAllChildren() {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (navigatorKey.currentContext as Element).visitChildren(rebuild);
  }

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin {
  AnimationController playerRouteController;
  AnimationController drawerWidgetController;

  @override
  void initState() {
    super.initState();
    drawerWidgetController = SlidableController(vsync: this);
    playerRouteController = SlidableController(
      vsync: this,
      springDescription: playerRouteSpringDescription,
    );
    NFWidgets.init(
      navigatorKey: App.navigatorKey,
      routeObservers: [routeObserver, homeRouteObserver],
      defaultSystemUiStyle: Constants.UiTheme.black.auto,
      defaultModalSystemUiStyle: Constants.UiTheme.modal.auto,
      defaultBottomSheetSystemUiStyle: Constants.UiTheme.bottomSheet.auto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlidableControllerProvider<DrawerWidget>(
      controller: drawerWidgetController,
      child: SlidableControllerProvider<PlayerRoute>(
        controller: playerRouteController,
        child: StreamBuilder(
          stream: ThemeControl.onThemeChange,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return MaterialApp(
              // showPerformanceOverlay: true,
              title: Constants.Config.APPLICATION_TITLE,
              navigatorKey: App.navigatorKey,
              color: ThemeControl.theme.colorScheme.primary,
              supportedLocales: Constants.Config.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                NFLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              theme: ThemeControl.theme,
              initialRoute: Constants.Routes.home.value,
              navigatorObservers: [routeObserver],
              onGenerateRoute: RouteControl.handleOnGenerateRoute,
              onGenerateInitialRoutes:
                  RouteControl.handleOnGenerateInitialRoutes,
              onUnknownRoute: RouteControl.handleOnUnknownRoute,
            );
          },
        ),
      ),
    );
  }
}

SlidableControllerProvider<DrawerWidget> getDrawerControllerProvider(
        BuildContext context) =>
    SlidableControllerProvider.of<DrawerWidget>(context);
SlidableControllerProvider<PlayerRoute> getPlayerRouteControllerProvider(
        BuildContext context) =>
    SlidableControllerProvider.of<PlayerRoute>(context);

mixin DrawerControllerMixin<T extends StatefulWidget> on State<T> {
  SlidableController drawerController;
  @override
  void initState() {
    super.initState();
    drawerController = getDrawerControllerProvider(context).controller;
  }
}

mixin PlayerRouteControllerMixin<T extends StatefulWidget> on State<T> {
  SlidableController playerRouteController;
  @override
  void initState() {
    super.initState();
    playerRouteController =
        getPlayerRouteControllerProvider(context).controller;
  }
}
