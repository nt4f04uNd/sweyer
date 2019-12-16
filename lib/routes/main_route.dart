/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter_music_player/components/buttons.dart';
import 'package:flutter_music_player/constants/themes.dart';
import 'package:flutter_music_player/logic/lifecycle.dart';
import 'package:flutter_music_player/logic/permissions.dart';
import 'package:flutter_music_player/logic/player/playlist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_music_player/components/track_list.dart';

class MainRoute extends StatefulWidget {
  @override
  MainRouteState createState() => MainRouteState();
}

class MainRouteState extends State<MainRoute> {
  @override
  void initState() {
    super.initState();
    LaunchControl.afterAppMount();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: PlaylistControl.onPlaylistListChange,
        builder: (context, snapshot) {
          return PlaylistControl.playReady
              ? Permissions.permissionStorageStatus !=
                      MyPermissionStatus.granted
                  ? NoPermissionsScreen()
                  : PlaylistControl.songsEmpty(PlaylistType.global)
                      ? PlaylistControl.initFetching
                          ? SearchingSongsScreen()
                          : SongsEmptyScreen()
                      : MainRouteTrackList()
              : SizedBox.shrink();
        });
  }
}

/// Screen displayed when songs array is empty and searching is being performed
class SearchingSongsScreen extends StatelessWidget {
  const SearchingSongsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.main.auto(context),
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
      backgroundColor: AppTheme.main.auto(context),
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

    await Permissions.requestStorage();

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
      backgroundColor: AppTheme.main.auto(context),
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
