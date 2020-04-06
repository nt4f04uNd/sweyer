/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:package_info/package_info.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsRoute extends StatefulWidget {
  const SettingsRoute({Key key}) : super(key: key);

  @override
  _SettingsRouteState createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<SettingsRoute> {
  /// The amount of clicks to enter the dev mode
  static const int _clicksForDevMode = 14;

  bool _switched = ThemeControl.isDark;
  bool _devMode = false;
  String _appVersion = "";
  String get appName {
    var postFix = "";
    if (_appVersion != null) {
      postFix = "@v" + _appVersion;
    }
    return "Sweyer" + postFix;
  }

  int _clickCount = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    // Fetch dev mode
    _devMode = await Prefs.developerModeBool.getPref();
    _appVersion = (await PackageInfo.fromPlatform()).version;
    if (mounted) {
      setState(() {});
    }
  }

  void _switchTheme() {
    setState(() {
      ThemeControl.switchTheme();
      _switched = !_switched;
    });
  }

  void _handleSecretLogoClick() {
    if (!_devMode) {
      final int remainingClicks = _clicksForDevMode - 1 - _clickCount;

      if (remainingClicks < 0) {
        return;
      } else if (remainingClicks == 0) {
        Prefs.developerModeBool.setPref(value: true);
        SnackBarControl.showSnackBar(
          SMMSnackbarSettings(
            important: true,
            duration: const Duration(seconds: 7),
            child: SMMSnackBar(
              leading: Icon(
                Icons.adb,
                color: Colors.white,
              ),
              message: "Готово! Вы вошли в режим разработчика",
              color: Constants.AppColors.androidGreen,
            ),
          ),
        );
      } else if (_clickCount == 4) {
        SnackBarControl.showSnackBar(
          SMMSnackbarSettings(
            important: true,
            child: SMMSnackBar(
              message: "Сейчас должно что-то произойти...",
              color: Constants.AppColors.androidGreen,
            ),
          ),
        );
      } else if (remainingClicks < 5) {
        SnackBarControl.showSnackBar(
          SMMSnackbarSettings(
            important: true,
            child: SMMSnackBar(
              message: (() {
                final bool lastClick = remainingClicks == 1;
                return "Вы почти у цели, " +
                    (lastClick ? "остался всего " : "осталось всего ") +
                    remainingClicks.toString() +
                    (lastClick ? " клик..." : " клика...");
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
    return PageBase(
      name: "Настройки",
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: ListView(
              physics: NeverScrollableScrollPhysics(),
              children: <Widget>[
                SMMListTile(
                  title: Text('Расширенные настройки'),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed(Constants.Routes.extendedSettings.value);
                  },
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    splashFactory: ListTileInkRipple.splashFactory,
                  ),
                  child: SwitchListTile(
                    title: Text("Темная тема"),
                    activeColor: Theme.of(context).colorScheme.onSurface,
                    value: _switched,
                    onChanged: (value) {
                      _switchTheme();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: ThemeControl.isDark
                    ? Constants.AppColors.androidGreen.withOpacity(0.9)
                    : null,
                splashFactory: ListTileInkRipple.splashFactory,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 2.5, right: 2.5),
                        child: SMMIconButton(
                          icon: const SweyerLogo(),
                          size: 60.0,
                          iconSize: 42.0,
                          onPressed: _handleSecretLogoClick,
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.only(bottom: 0.0, top: 30),
                      //   child: Column(
                      //     children: <Widget>[
                      Text(
                        appName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      //       Padding(
                      //         padding: const EdgeInsets.only(top: 4.0),
                      //         child:
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      SizedBox(
                        width: 32.0,
                      ),
                    ],
                  ),
                  GestureDetector(
                    child: Text(
                      "github repo",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onTap: () async {
                      final url = Constants.Config.GITHUB_REPO_URL;
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch ${url}';
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
