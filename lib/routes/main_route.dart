import 'package:app/components/buttons.dart';
import 'package:app/logic/permissions.dart';
import 'package:app/logic/player/playlist.dart';
import 'package:app/logic/theme.dart';
import 'package:flutter/material.dart';
import 'package:app/components/track_list.dart';
import 'package:app/logic/player/player.dart';

class MainRoute extends StatefulWidget {
  @override
  MainRouteState createState() => MainRouteState();
}

class MainRouteState extends State<MainRoute> {
  @override
  void initState() {
    super.initState();
    // Init music player
    // It is not in main function, because we need catcher to catch errors
    MusicPlayer.init();
    // Init playlist control
    PlaylistControl.init();
    // Init theme control
    ThemeControl.init();
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
    return Scaffold(
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
