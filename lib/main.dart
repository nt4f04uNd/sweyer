import 'package:app/player/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:catcher/catcher_plugin.dart';
import 'constants/constants.dart';
import 'routes/route_control.dart';

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

class MyApp extends StatelessWidget {
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
            initialRoute: Routes.main.value,
            onGenerateRoute: RouteControl.handleOnGenerateRoute,
          );
        });
  }
}
