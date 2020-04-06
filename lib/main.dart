/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:catcher/catcher_plugin.dart';
import 'constants/constants.dart';
import 'routes/routes.dart';

final RouteObserver<Route> routeObserver = RouteObserver();

void main() {
  final CatcherOptions debugOptions = CatcherOptions(SnackBarReportMode(), [
    ConsoleHandler(),
  ]);
  final CatcherOptions releaseOptions = CatcherOptions(SnackBarReportMode(), [
    // EmailManualHandler([Constants.Config.REPORT_EMAIL]),
    FirebaseReportHandler(),
  ]);

  Catcher(App(), debugConfig: debugOptions, releaseConfig: releaseOptions);

  // runApp(App());
}

class App extends StatelessWidget {
  /// A global key to obtain the navigator
  static GlobalKey<NavigatorState> get navigatorKey => Catcher.navigatorKey;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: LaunchControl.onLaunch,
        builder: (context, snapshot) {
          return StreamBuilder(
              stream: ThemeControl.onThemeChange,
              builder: (context, snapshot) {
                return MaterialApp(
                  title: Constants.Config.APPLICATION_TITLE,
                  navigatorKey: navigatorKey,
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  supportedLocales: [const Locale('ru')],
                  locale: const Locale('ru'),
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                  ],
                  themeMode: !ThemeControl.isReady
                      ? ThemeMode.system
                      : ThemeControl.isDark ? ThemeMode.dark : ThemeMode.light,
                  theme: AppTheme.materialApp.light,
                  darkTheme: AppTheme.materialApp.dark,
                  initialRoute: Routes.main.value,
                  navigatorObservers: [routeObserver],
                  onGenerateRoute: RouteControl.handleOnGenerateRoute,
                  onGenerateInitialRoutes:
                      RouteControl.handleOnGenerateInitialRoutes,
                  onUnknownRoute: RouteControl.handleOnUnknownRoute,
                  // Uncomment to replace red screen of death
                  builder: (BuildContext context, Widget widget) {
                    // Catcher.addDefaultErrorWidget(
                    //     showStacktrace: true,
                    //     customTitle: "Custom error title",
                    //     customDescription: "Custom error description",
                    //     );

                    return widget;
                  },
                );
              });
        });
  }
}
