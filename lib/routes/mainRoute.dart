import 'package:app/components/bottomTrackPanel.dart';
import 'package:app/components/search.dart';
import 'package:flutter/material.dart';
import 'package:app/components/track_list.dart';
import 'package:app/musicPlayer.dart';

class MainRouteState extends State<MainRoute> {
  /// Music player class instance
  MusicPlayer _musicPlayer;

  /// Delegate for search
  final SongsSearchDelegate _songsSearchDelegate = SongsSearchDelegate();

  @override
  void initState() {
    super.initState();
    // Init music player instance
    _musicPlayer = MusicPlayer();
  }

  void _showSearch() async {
    await showSearch<Song>(
      context: context,
      delegate: _songsSearchDelegate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              fillColor: Colors.white.withOpacity(0.05),
              filled: true,
              hintText: 'Поиск треков на устройстве',
            ),
            onTap: _showSearch,
          ),
        ),
      ),
      body: StreamBuilder(
          stream: _musicPlayer.onTrackListChange,
          builder: (context, snapshot) {
            return _musicPlayer.songsReady
                ? Stack(
                    children: <Widget>[
                      TrackList(),
                      BottomTrackPanel(),
                    ],
                  )
                : Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                    ),
                  );
          }),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class MainRoute extends StatefulWidget {
  @override
  MainRouteState createState() => MainRouteState();
}
