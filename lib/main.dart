/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter_music_player/logic/errors.dart';
import 'package:flutter_music_player/logic/lifecycle.dart';
import 'package:flutter_music_player/logic/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:catcher/catcher_plugin.dart';
import 'constants/constants.dart';
import 'routes/routes.dart';

void main() {
  final CatcherOptions debugOptions = CatcherOptions(CustomDialogReportMode(), [
    ConsoleHandler(),
  ]);
  final CatcherOptions releaseOptions =
      CatcherOptions(CustomDialogReportMode(), [
    EmailManualHandler(["nt4f04uNd@gmail.com"]),
  ]);

  Catcher(App(), debugConfig: debugOptions, releaseConfig: releaseOptions);
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    LaunchControl.init();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: LaunchControl.onLaunch,
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data) return SizedBox.shrink();
          return StreamBuilder(
              stream: ThemeControl.onThemeChange,
              builder: (context, snapshot) {
                if (!ThemeControl.isReady) return SizedBox.shrink();
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
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                  ],
                  themeMode:
                      ThemeControl.isDark ? ThemeMode.dark : ThemeMode.light,
                  theme: AppTheme.materialApp.light,
                  darkTheme: AppTheme.materialApp.dark,
                  initialRoute: Routes.main.value,
                  onGenerateRoute: RouteControl.handleOnGenerateRoute,
                );
              });
        });
  }
}
