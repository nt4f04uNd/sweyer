/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:flutter/material.dart';

class MainRoute extends StatefulWidget {
  @override
  MainRouteState createState() => MainRouteState();
}

class MainRouteState extends State<MainRoute> {
  // Var to show toast in `_handleHomePop`
  static DateTime _currentBackPressTime;

  @override
  void initState() {
    super.initState();
    LaunchControl.afterAppMount();
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
    // Stop player before exiting app
    await MusicPlayer.stop();
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleHomePop,
      child: StreamBuilder(
          stream: PlaylistControl.onPlaylistListChange,
          builder: (context, snapshot) {
            return PlaylistControl.playReady
                ? Permissions.permissionStorageStatus != PermissionState.granted
                    ? NoPermissionsScreen()
                    : PlaylistControl.songsEmpty(PlaylistType.global)
                        ? PlaylistControl.initFetching
                            ? SearchingSongsScreen()
                            : SongsEmptyScreen()
                        : MainRouteTrackList()
                : EmptyScreen(); // TODO: probably add some fancy list loading animation here or when fetching songs instead of spinner
          }),
    );
  }
}

/// Screen displayed when songs array is empty and searching is being performed
class SearchingSongsScreen extends StatelessWidget {
  const SearchingSongsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.AppTheme.main.auto(context),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Text('Ищем треки...'),
          ),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
          ),
        ]),
      ),
    );
  }
}

/// Screen displayed when no songs had been found
class SongsEmptyScreen extends StatefulWidget {
  const SongsEmptyScreen({Key key}) : super(key: key);

  @override
  _SongsEmptyScreenState createState() => _SongsEmptyScreenState();
}

class _SongsEmptyScreenState extends State<SongsEmptyScreen> {
  bool _fetching = false;
  Future<void> _refetchHandler() async {
    return await PlaylistControl.refetchSongs();
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
                  child: Text('На вашем устройстве нету музыки :( '))),
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
class NoPermissionsScreen extends StatefulWidget {
  const NoPermissionsScreen({Key key}) : super(key: key);

  @override
  _NoPermissionsScreenState createState() => _NoPermissionsScreenState();
}

class _NoPermissionsScreenState extends State<NoPermissionsScreen> {
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
    print(Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: Constants.AppTheme.main.auto(context),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text('Пожалуйста, предоставьте доступ к хранилищу'))),
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

class EmptyScreen extends StatelessWidget {
  const EmptyScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Constants.AppTheme.main.auto(context));
  }
}
