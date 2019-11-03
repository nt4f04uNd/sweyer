import 'package:app/player/playlist.dart';
import 'package:app/player/theme.dart';
import 'package:flutter/material.dart';
import 'package:app/components/track_list.dart';
import 'package:app/player/player.dart';

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
              ? PlaylistControl.songsEmpty(PlaylistType.global) &&
                      PlaylistControl.initFetching
                  ? Scaffold(
                      body: Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Text('Ищем треки...'),
                              ),
                              CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            ]),
                      ),
                    )
                  : TrackList(
                      // bottomPadding: const EdgeInsets.only(bottom: 55.0),
                      )
              : SizedBox.shrink();
        });
  }
}

class MainRoute extends StatefulWidget {
  @override
  MainRouteState createState() => MainRouteState();
}
