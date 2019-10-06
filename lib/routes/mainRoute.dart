import 'package:app/components/bottomTrackPanel.dart';
import 'package:app/components/search.dart';
import 'package:app/player/playlist.dart';
import 'package:app/player/song.dart';
import 'package:flutter/material.dart';
import 'package:app/components/track_list.dart';
import 'package:app/player/player.dart';

class MainRouteState extends State<MainRoute> {
  /// Music player class instance
  MusicPlayer _musicPlayer;

  /// Delegate for search
  final SongsSearchDelegate _songsSearchDelegate = SongsSearchDelegate();

  @override
  void initState() {
    super.initState();
    // Init music player instance
    // It is not in main function, because we need catcher to catch errors
    _musicPlayer = MusicPlayer();
  }

  void _showSearch() async {
    await showSearch<Song>(
      context: context,
      delegate: _songsSearchDelegate,
    );
  }

  void _showSortModal() {
    // TODO: add indicatior to current sort feature
    // TODO: maybe make bottom sheet transparent and add container, so it would fly on the center of the screen
    // TODO: maybe make search results to ignore sort order
    // TODO: add sort order to shared prefs
    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 15, left: 12),
                  child: Text("Сортировать",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.caption.color,
                      ))),
              ListTile(
                title: Text("По названию"),
                onTap: () {
                  _musicPlayer.playlistControl.sortSongs(SortFeature.title);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("По дате"),
                onTap: () {
                  _musicPlayer.playlistControl.sortSongs(SortFeature.date);
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.sort),
            // padding: EdgeInsets.all(0),
            onPressed: () {
              _showSortModal();
            },
          ),
        ],
        titleSpacing: 0.0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: ClipRRect(
            // FIXME: cliprrect doesn't work for material for some reason
            borderRadius: BorderRadius.circular(10),
            child: GestureDetector(
              onTap: _showSearch,
              child: FractionallySizedBox(
                // heightFactor: 1,
                widthFactor: 1,
                child: Container(
                  padding: const EdgeInsets.only(
                      left: 12.0, top: 10.0, bottom: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Поиск треков на устройстве',
                        style: TextStyle(
                            color: Theme.of(context).hintColor, fontSize: 17),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder(
          stream: _musicPlayer.onPlaylistListChange,
          builder: (context, snapshot) {
            return !_musicPlayer.playlistControl.playReady
                ? SizedBox.shrink()
                // TODO: do something to replace `searchingState` !!
                // : _musicPlayer.searchingState && _musicPlayer.songsEmpty
                : _musicPlayer.playlistControl.songsEmpty(PlaylistType.global)
                    ? Center(
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
                      )
                    : _musicPlayer.playlistControl
                            .songsEmpty(PlaylistType.global) // FIXME: this ternary will never be reached
                        ? Center(
                            child: Text('На вашем устройстве нету музыки :( '))
                        : Stack(
                            children: <Widget>[
                              TrackList(
                                bottomPadding:
                                    const EdgeInsets.only(bottom: 55.0),
                              ),
                              BottomTrackPanel(),
                            ],
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
