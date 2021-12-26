/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:isolate';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Builds up the error report message from the exception and stacktrace.
String buildErrorReport(dynamic ex, dynamic stack) {
  return '''
$ex
                      
$stack''';
}

Future<void> reportError(dynamic ex, StackTrace stack) async {
  if (Prefs.devMode.get()) {
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
  if (Prefs.devMode.get()) {
    ShowFunctions.instance.showError(
      errorDetails: buildErrorReport(details.exception, details.stack),
    );
  }
  await FirebaseCrashlytics.instance.recordFlutterError(details);
}


class _WidgetsBindingObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      /// This ensures that proper UI will be applied when activity is resumed.
      /// 
      /// See:
      /// * https://github.com/flutter/flutter/issues/21265
      /// * https://github.com/ryanheise/audio_service/issues/662
      /// 
      /// [SystemUiOverlayStyle.statusBarBrightness] is only honored on iOS,
      /// so I can safely use that here.
      final lastUi = SystemUiStyleController.lastUi;
      SystemUiStyleController.setSystemUiOverlay(SystemUiStyleController.lastUi.copyWith(
        statusBarBrightness:
          lastUi.statusBarBrightness == null ||
          lastUi.statusBarBrightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark
      ));
      /// Defensive programming if I some time later decide to add iOS support.
      SystemUiStyleController.setSystemUiOverlay(SystemUiStyleController.lastUi.copyWith(
        statusBarBrightness: lastUi.statusBarBrightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark
      ));
    }
  }
}

Future<void> main() async {
  // Disabling automatic system UI adjustment, which causes system nav bar
  // color to be reverted to black when the bottom player route is being expanded.
  //
  // Related to https://github.com/flutter/flutter/issues/40590
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  binding.renderView.automaticSystemUiAdjustment = false;
  await NFPrefs.initialize();

  await Firebase.initializeApp();
  if (kDebugMode) {
    FirebaseFunctions.instance.useFunctionsEmulator(origin: 'http://localhost:5001');
  
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
    WidgetsBinding.instance!.addObserver(_WidgetsBindingObserver());

    await initL10n();
    ThemeControl.init();
    ThemeControl.initSystemUi();
    await Permissions.init();
    await ContentControl.init();
    runApp(const App());
  }, reportError);
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  static NFThemeData nfThemeData = NFThemeData(
    systemUiStyle: Constants.UiTheme.black.auto,
    modalSystemUiStyle: Constants.UiTheme.modal.auto,
    bottomSheetSystemUiStyle: Constants.UiTheme.bottomSheet.auto,
  );

  static void rebuildAllChildren() {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }
    (AppRouter.instance.navigatorKey.currentContext as Element?)!.visitChildren(rebuild);
  }

  @override
  _AppState createState() => _AppState();
}

late SlidableController _playerRouteController;
late SlidableController _drawerController;
SlidableController get playerRouteController => _playerRouteController;
SlidableController get drawerController => _drawerController;

class _AppState extends State<App> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _drawerController = SlidableController(
      vsync: this,
      springDescription: DismissibleRoute.springDescription,
    );
    _playerRouteController = SlidableController(
      vsync: this,
      springDescription: playerRouteSpringDescription,
    );
    NFWidgets.init(
      navigatorKey: AppRouter.instance.navigatorKey,
      routeObservers: [routeObserver, homeRouteObserver],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ThemeControl.themeChaning,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return NFTheme(
        data: App.nfThemeData,
          child: MaterialApp.router(
            // debugShowCheckedModeBanner: false,
            // showPerformanceOverlay: true,
            // checkerboardRasterCacheImages: true,
            title: Constants.Config.APPLICATION_TITLE,
            color: ThemeControl.theme.colorScheme.primary,
            supportedLocales: Constants.Config.supportedLocales,
            scrollBehavior: _ScrollBehavior(),
            localizationsDelegates:
              AppLocalizations.localizationsDelegates
              + const [
                NFLocalizations.delegate,
              ],
            theme: ThemeControl.theme,
            routerDelegate: AppRouter.instance,
            routeInformationParser: AppRouteInformationParser(),
          ),
        );
      },
    );
  }
}

class _ScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return GlowingOverscrollIndicator(
      axisDirection: axisDirection,
      color: ThemeControl.theme.colorScheme.background,
      child: child,
    );
  }
}
