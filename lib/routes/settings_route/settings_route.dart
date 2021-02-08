/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:package_info/package_info.dart';
import 'package:sweyer/sweyer.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:flutter/material.dart' hide LicensePage;
import 'package:url_launcher/url_launcher.dart';

// import 'general_settings.dart';
import 'licenses_route.dart';
import 'theme_settings.dart';

void _pushRoute(
  Widget route, {
  StackFadeRouteTransitionSettings transitionSettings,
}) {
  App.navigatorKey.currentState.push(
    StackFadeRouteTransition(
      route: route,
      transitionSettings:
          transitionSettings ?? RouteControl.defaultTransitionSetttings,
    ),
  );
}

class SettingsRoute extends StatefulWidget {
  const SettingsRoute({Key key}) : super(key: key);
  @override
  _SettingsRouteState createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<SettingsRoute> {
  // void _handleClickGeneralSettings() {
  //   _pushRoute(const GeneralSettingsRoute());
  // }

  void _handleClickThemeSettings() {
    _pushRoute(
      const ThemeSettingsRoute(),
      transitionSettings: themeSettingsTransitionSetttings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return NFPageBase(
      name: l10n.settings,
      backButton: const NFBackButton(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: ListView(
              physics: NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 10.0),
              children: <Widget>[
                // MenuItem(
                //   l10n.general,
                //   icon: Icons.menu_book_rounded,
                //   iconSize: 25.0,
                //   fontSize: 16.0,
                //   onTap: _handleClickGeneralSettings,
                // ),
                MenuItem(
                  l10n.theme,
                  icon: Icons.palette_rounded,
                  iconSize: 25.0,
                  fontSize: 16.0,
                  onTap: _handleClickThemeSettings,
                ),
              ],
            ),
          ),
          _Footer(),
        ],
      ),
    );
  }
}

class _Footer extends StatefulWidget {
  _Footer({Key key}) : super(key: key);

  @override
  _FooterState createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  /// The amount of clicks to enter the dev mode
  static const int clicksForDevMode = 14;

  String appVersion = '';

  String get appName {
    var postFix = '';
    if (appVersion != null) {
      postFix = '@$appVersion';
    }
    return Constants.Config.APPLICATION_TITLE + postFix;
  }

  int _clickCount = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final info = await PackageInfo.fromPlatform();
    appVersion = '${info.version}+${info.buildNumber}';
    if (mounted) {
      setState(() {/* update ui after fetch */});
    }
  }

  void _handleGithubTap() {
    const url = Constants.Config.GITHUB_REPO_URL;
    launch(url);
  }

  void _handleLicenseTap() {
    _pushRoute(const LicensePage());
  }

  void _handleSecretLogoClick() {
    if (!ContentControl.state.devMode.value) {
      final int remainingClicks = clicksForDevMode - 1 - _clickCount;

      final textScaleFactor = MediaQuery.of(context).textScaleFactor;
      final l10n = getl10n(context);
      if (remainingClicks < 0) {
        return;
      } else if (remainingClicks == 0) {
        ContentControl.setDevMode(true);
        NFSnackbarControl.showSnackbar(
          NFSnackbarSettings(
            important: true,
            duration: const Duration(seconds: 7),
            child: NFSnackbar(
              leading: Icon(
                Icons.adb_rounded,
                color: Colors.white,
                size: Constants.iconSize * textScaleFactor,
              ),
              message: l10n.devModeGreet,
              color: Constants.AppColors.androidGreen,
            ),
          ),
        );
      } else if (_clickCount == 4) {
        NFSnackbarControl.showSnackbar(
          NFSnackbarSettings(
            important: true,
            child: NFSnackbar(
              message: l10n.onThePathToDevMode,
              color: Constants.AppColors.androidGreen,
            ),
          ),
        );
      } else if (remainingClicks < 5) {
        NFSnackbarControl.showSnackbar(
          NFSnackbarSettings(
            important: true,
            child: NFSnackbar(
              message: (() {
                return l10n.almostThere +
                    ', ' +
                    (remainingClicks == 1
                        ? l10n.onThePathToDevModeLastClick
                        : l10n.onThePathToDevModeClicksRemaining(
                            remainingClicks));
              })(),
              color: Constants.AppColors.androidGreen,
            ),
          ),
        );
      }

      _clickCount++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 2.5, right: 2.5),
                child: NFIconButton(
                  icon: const SweyerLogo(),
                  splashColor: ThemeControl.theme.colorScheme.primary,
                  size: 60.0,
                  iconSize: 42.0,
                  onPressed: _handleSecretLogoClick,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appName,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ThemeControl.theme.textTheme.headline6.color,
                    ),
                  ),
                  Text(
                    'Copyright (c) 2019, nt4f04uNd',
                    style: Theme.of(context)
                        .textTheme
                        .caption
                        .copyWith(height: 1.0),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: _handleGithubTap,
            child: Text(
              'github repo',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: ThemeControl.theme.colorScheme.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: _handleLicenseTap,
            child: Text(
              MaterialLocalizations.of(context).licensesPageTitle.toLowerCase(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: ThemeControl.theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
