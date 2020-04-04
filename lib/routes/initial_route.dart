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
  @override
  void initState() {
    super.initState();
    LaunchControl.init();
    // LaunchControl.afterAppMount();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: ContentControl.state.onPlaylistListChange,
        builder: (context, snapshot) {
          return !ContentControl.playReady
              ? LoadingScreen()
              : Permissions.notGranted
                  ? _NoPermissionsScreen()
                  : ContentControl.state
                          .getPlaylist(PlaylistType.global)
                          .isEmpty
                      ? ContentControl.initFetching
                          ? _SearchingSongsScreen()
                          : _SongsEmptyScreen()
                      : TrackListScreen();
        });
  }
}

/// Screen displayed when songs array is empty and searching is being performed
class _SearchingSongsScreen extends StatelessWidget {
  const _SearchingSongsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
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
              valueColor:
                  AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
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
      backgroundColor: Theme.of(context).colorScheme.secondary,
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
      backgroundColor: Theme.of(context).colorScheme.secondary,
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
