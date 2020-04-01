/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:flutter/material.dart';

class InitialRoute extends StatefulWidget {
  @override
  InitialRouteState createState() => InitialRouteState();
}

class InitialRouteState extends State<InitialRoute> {
  // Var to show toast in `_handleHomePop`
  static DateTime _currentBackPressTime;

  @override
  void initState() {
    super.initState();
    LaunchControl.init();
    // LaunchControl.afterAppMount();
  }

  /// Handles route pop and shows user toast
  static Future<bool> _handleHomePop() async {
    DateTime now = DateTime.now();
    // Show toast when user presses back button on main route, that asks from user to press again to confirm that he wants to quit the app
    if (_currentBackPressTime == null ||
        now.difference(_currentBackPressTime) > Duration(seconds: 2)) {
      _currentBackPressTime = now;
      ShowFunctions.showToast(msg: 'Нажмите еще раз для выхода');
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleHomePop,
      child: StreamBuilder(
          stream: ContentControl.state.onPlaylistListChange,
          builder: (context, snapshot) {
            return !ContentControl.playReady
                ? LoadingScreen()
                : Permissions.notGranted
                    ? _NoPermissionsScreen()
                    : ContentControl.state.getPlaylist(PlaylistType.global).isEmpty
                        ? ContentControl.initFetching
                            ? _SearchingSongsScreen()
                            : _SongsEmptyScreen()
                        : TrackListScreen();
          }),
    );
  }
}

/// Screen displayed when songs array is empty and searching is being performed
class _SearchingSongsScreen extends StatelessWidget {
  const _SearchingSongsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.AppTheme.main.auto(context),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Ищем треки...',
                textAlign: TextAlign.center,
              ),
            ),
            CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation(Colors.deepPurple),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen displayed when no songs had been found
class _SongsEmptyScreen extends StatefulWidget {
  const _SongsEmptyScreen({Key key}) : super(key: key);

  @override
  _SongsEmptyScreenState createState() => _SongsEmptyScreenState();
}

class _SongsEmptyScreenState extends State<_SongsEmptyScreen> {
  bool _fetching = false;
  Future<void> _refetchHandler() async {
    return await ContentControl.refetchSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.AppTheme.main.auto(context),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'На вашем устройстве нету музыки :( ',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: ButtonTheme(
              minWidth: 130.0, // specific value
              height: 40.0,
              child: PrimaryRaisedButton(
                loading: _fetching,
                text: "Обновить",
                onPressed: () async {
                  setState(() {
                    _fetching = true;
                  });
                  await _refetchHandler();
                  setState(() {
                    _fetching = false;
                  });
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

/// Screen displayed when there are not permissions
class _NoPermissionsScreen extends StatefulWidget {
  const _NoPermissionsScreen({Key key}) : super(key: key);

  @override
  _NoPermissionsScreenState createState() => _NoPermissionsScreenState();
}

class _NoPermissionsScreenState extends State<_NoPermissionsScreen> {
  bool _fetching = false;

  Future<void> _handlePermissionRequest() async {
    if (mounted)
      setState(() {
        _fetching = true;
      });
    else
      _fetching = true;

    await Permissions.requestClick();

    if (mounted)
      setState(() {
        _fetching = false;
      });
    else
      _fetching = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.AppTheme.main.auto(context),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Пожалуйста, предоставьте доступ к хранилищу',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: ButtonTheme(
              minWidth: 130.0, // specific value
              height: 40.0,
              child: PrimaryRaisedButton(
                loading: _fetching,
                text: "Предоставить",
                onPressed: _handlePermissionRequest,
              ),
            ),
          )
        ],
      ),
    );
  }
}
