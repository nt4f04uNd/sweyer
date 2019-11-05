import 'package:app/components/albumArt.dart';
import 'package:app/components/bottomTrackPanel.dart';
import 'package:app/components/custom_refresh_indicator.dart';
import 'package:app/components/drawer.dart';
import 'package:app/components/gestures.dart';
import 'package:app/components/show_functions.dart';
import 'package:app/constants/routes.dart';
import 'package:app/constants/themes.dart';
import 'package:app/player/player_widgets.dart';
import 'package:app/player/playlist.dart';
import 'package:app/player/song.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/player/player.dart';
import 'custom_icon_button.dart';
import 'scrollable_positioned_list/scrollable_positioned_list.dart';

/// List of fetched tracks
class MainRouteTrackList extends StatefulWidget {
  final EdgeInsets bottomPadding;
  MainRouteTrackList({Key key, this.bottomPadding: const EdgeInsets.only(bottom: 0.0)})
      : super(key: key);

  @override
  _MainRouteTrackListState createState() => _MainRouteTrackListState();
}

class _MainRouteTrackListState extends State<MainRouteTrackList> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool refreshing = false;

  /// Performs tracks refetch
  Future<void> _refreshHandler() async {
    return await PlaylistControl.refetchSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: //This will change the drawer background
              AppTheme.drawer.auto(context),
        ),
        child: DrawerWidget(),
      ),
      appBar: AppBar(
        leading: DrawerButton(),
        actions: <Widget>[
          // IconButton(
          Padding(
            padding: const EdgeInsets.only(left:5.0, right:5.0),
            child: CustomIconButton(
              icon: Icon(Icons.sort),
              color: Theme.of(context).iconTheme.color,
              onPressed: () => ShowFunctions.showSongsSortModal(context),
            ),
          ),
        ],
        titleSpacing: 0.0,
        title: Padding(
          padding: const EdgeInsets.only(left: 0.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GestureDetector(
              onTap: () => ShowFunctions.showSongsSearch(context),
              child: FractionallySizedBox(
                widthFactor: 1,
                child: Container(
                  padding: const EdgeInsets.only(
                      left: 12.0, top: 7.0, bottom: 7.0, right: 12.0),
                  decoration: BoxDecoration(
                    color: AppTheme.searchFakeInput.auto(context),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.search,
                      color: Theme.of(context).textTheme.caption.color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Padding(
            padding: widget.bottomPadding,
            child: Container(
              child: CustomRefreshIndicator(
                color: Colors.white,
                backgroundColor: Color(0xff101010),
                strokeWidth: 2.5,
                key: _refreshIndicatorKey,
                onRefresh: _refreshHandler,
                child: SingleTouchRecognizerWidget(
                  child: Container(
                    child: ListView.builder(
                      itemCount: PlaylistControl.length(PlaylistType.global),
                      padding: EdgeInsets.only(bottom: 65, top: 0),
                      itemBuilder: (context, index) {
                        return StreamBuilder(
                            stream: PlaylistControl.onSongChange,
                            builder: (context, snapshot) {
                              return TrackTile(
                                index,
                                key: UniqueKey(),
                                playing: index ==
                                    PlaylistControl.currentSongIndex(
                                        PlaylistType.global),
                                additionalClickCallback: () {
                                  PlaylistControl.resetPlaylists();
                                },
                              );
                            });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          BottomTrackPanel(),
        ],
      ),
    );
  }
}

/// Widget to render current playlist in player right right tab
///
/// Stateful because I need its state is needed to use global key
class PlayerRoutePlaylist extends StatefulWidget {
  PlayerRoutePlaylist({
    Key key,
  }) : super(key: key);

  @override
  PlayerRoutePlaylistState createState() =>
      PlayerRoutePlaylistState();
}

class PlayerRoutePlaylistState extends State<PlayerRoutePlaylist> {
  final ItemScrollController itemScrollController = ItemScrollController();

  final ScrollController frontScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    int initialScrollIndex;
    final int length = PlaylistControl.length();
    final int currentSongIndex = PlaylistControl.currentSongIndex();
    if (length > 11) {
      initialScrollIndex =
          currentSongIndex > length - 6 ? length - 6 : currentSongIndex;
    } else
      initialScrollIndex = 0;

    return Container(
      child: SingleTouchRecognizerWidget(
        child: ScrollablePositionedList.builder(
          frontScrollController: frontScrollController,
          itemScrollController: itemScrollController,
          itemCount: length,
          padding: EdgeInsets.only(bottom: 10, top: 5),
          initialScrollIndex: initialScrollIndex,
          itemBuilder: (context, index) {
            return StreamBuilder(
                stream: PlaylistControl.onSongChange,
                builder: (context, snapshot) {
                  return TrackTile(
                    index,
                    key: UniqueKey(),
                    playing: index == currentSongIndex,
                    song: PlaylistControl.getSongByIndex(index),
                    pushToPlayerRouteOnClick: false,
                  );
                });
          },
        ),
      ),
    );
  }
}

/// `TrackTile` that represents a single track in `TrackList`
class TrackTile extends StatefulWidget {
  TrackTile(this.trackTileIndex,
      {Key key,
      this.pushToPlayerRouteOnClick: true,
      this.playing: false,
      this.song,
      this.enabled: true,
      this.additionalClickCallback})
      : super(key: key);

  /// Index of rendering element from
  final int trackTileIndex;

  /// Enables animated indicator at the end of the tile
  final bool playing;

  /// Whether to push user to player route when tile got clicked
  final bool pushToPlayerRouteOnClick;

  final Function additionalClickCallback;

  final bool enabled;

  /// Provide song data to render it directly, not from playlist (e.g. used in search)
  final Song song;

  @override
  _TrackTileState createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  /// Instance of music player
  Song _song;

  @override
  void initState() {
    super.initState();

    /// If song data is not provided, then find it by index of row in current row
    _song = widget.song ??
        PlaylistControl.getSongByIndex(
            widget.trackTileIndex, PlaylistType.global);
  }

  void _handleTap() async {
    await MusicPlayer.clickTrackTile(_song.id);
    if (widget.additionalClickCallback != null)
      widget.additionalClickCallback();
    // Playing because clickTrackTile changes any other type to it
    if (widget.pushToPlayerRouteOnClick &&
        MusicPlayer.playState == AudioPlayerState.PLAYING)
      Navigator.of(context).pushNamed(Routes.player.value);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(
          _song.title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 16 /* Default flutter title font size (not dense) */),
        ),
        subtitle: Artist(artist: _song.artist),
        dense: true,
        isThreeLine: false,
        leading: AlbumArt(path: _song.albumArtUri),
        trailing: widget.playing
            ? Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(10)),
                ),
              )
            : null,
        contentPadding: const EdgeInsets.only(left: 10, top: 0),
        onTap: _handleTap);
  }
}
