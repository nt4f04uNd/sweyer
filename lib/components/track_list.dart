import 'package:app/components/SingleTouchRecognizer.dart';
import 'package:app/components/albumArt.dart';
import 'package:app/components/bottomTrackPanel.dart';
import 'package:app/components/search.dart';
import 'package:app/player/permissions.dart';
import 'package:app/player/playerWidgets.dart';
import 'package:app/player/playlist.dart';
import 'package:app/player/song.dart';
import 'package:app/routes/playerRoute.dart';
import 'package:app/routes/settingsRoute.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/player/player.dart';
import 'scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:app/components/refresh_indicator.dart';

class DrawerButton extends StatelessWidget {
  const DrawerButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.menu),
      onPressed: Scaffold.of(context).openDrawer,
    );
  }
}

/// List of fetched tracks
class TrackList extends StatefulWidget {
  final EdgeInsets bottomPadding;
  TrackList({Key key, this.bottomPadding: const EdgeInsets.only(bottom: 0.0)})
      : super(key: key);

  @override
  _TrackListState createState() => _TrackListState();
}

class _TrackListState extends State<TrackList> {
  // TODO: extract this to constant
  // static final PageStorageKey _pageScrollKey = PageStorageKey('MainListView');
  static final GlobalKey trackListGlobalKey = GlobalKey();
  static final GlobalKey<BottomTrackPanelState> bottomPanelGlobalKey =
      GlobalKey<BottomTrackPanelState>();
  static final int tileHeight = 64;
  final ScrollController listScrollController = ScrollController();
  bool didTapDrawerTile = false;

  bool refreshing = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  Future<void> _refreshHandler() async {
    await PlaylistControl.refetchSongs();
    return Future.value();
  }

  /// Delegate for search

  void _showSearch() async {
    await showSearch<Song>(
      context: context,
      delegate: SongsSearchDelegate(bottomPanelGlobalKey: bottomPanelGlobalKey),
    );
  }

  void _showSortModal() {
    // TODO: add indicator for a current sort feature
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
                  PlaylistControl.sortSongs(SortFeature.title);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("По дате"),
                onTap: () {
                  PlaylistControl.sortSongs(SortFeature.date);
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  Future<void> _handlePermissionRequest() async {
    if (mounted)
      setState(() {
        refreshing = true;
      });
    else
      refreshing = true;

    Permissions.requestStorage();

    if (mounted)
      setState(() {
        refreshing = false;
      });
    else
      refreshing = false;
  }

  Future<void> _handleClickSettings() async {
    if (!didTapDrawerTile) {
      setState(() {
        // Make sure that user won't be able to click drawer twice
        didTapDrawerTile = true;
      });
      // itemScrollController.jumpTo()
      Navigator.pop(context);
      await Future.delayed(Duration(
          milliseconds:
              246)); // Default drawer close time
      await Navigator.of(context).push(createSettingsRoute(_buildTracks(true)));
      setState(() {
        didTapDrawerTile = false;
      });
    }
  }

  Widget _buildTracks([bool isFake = false]) {
    /// `ScrollablePositionedList` initial index offset
    int indexOffset;

    /// `ScrollablePositionedList` initial scroll offset (in range of 0 to `tileHeight`)
    double additionalScrollOffset;

    if (isFake) {
      // Stop possible scrolling
      listScrollController.jumpTo(listScrollController.offset);

      // Calc init offsets
      indexOffset = listScrollController.offset ~/ tileHeight;
      additionalScrollOffset = listScrollController.offset % tileHeight;
    }
    return IgnorePointer(
      key: isFake ? null : trackListGlobalKey,
      ignoring: didTapDrawerTile, // Disable entire fake touch events
      child: Scaffold(
        drawer: Theme(
          data: Theme.of(context).copyWith(
            canvasColor:
                Color(0xff070707), //This will change the drawer background
          ),
          child: Drawer(
            child: ListView(
              physics: NeverScrollableScrollPhysics(),
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(
                      left: 15.0, top: 40.0, bottom: 20.0),
                  child: Text('Меню', style: TextStyle(fontSize: 35.0)),
                ),
                ListTile(
                    title: Text('Настройки',
                        style: TextStyle(
                            fontSize: 17.0, color: Colors.deepPurple.shade300)),
                    onTap: _handleClickSettings),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          leading: DrawerButton(),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.sort),
              onPressed: () {
                _showSortModal();
              },
            ),
          ],
          titleSpacing: 0.0,
          title: Padding(
            padding: const EdgeInsets.only(left: 0.0),
            child: ClipRRect(
              // FIXME: cliprrect doesn't work for material for some reason
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: _showSearch,
                child: FractionallySizedBox(
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
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).hintColor,
                              fontSize: 17),
                        )
                      ],
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
                  key: isFake ? null : _refreshIndicatorKey,
                  onRefresh: _refreshHandler,
                  child: SingleTouchRecognizerWidget(
                    child: Container(
                      child: ScrollablePositionedList.builder(
                        initialScrollIndex: isFake ? indexOffset : 0,
                        
                        frontScrollController: isFake
                            ? ScrollController(
                                initialScrollOffset: additionalScrollOffset)
                            : listScrollController,
                        itemCount: PlaylistControl.globalPlaylist.length,
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
            BottomTrackPanel(
              key: isFake ? null : bottomPanelGlobalKey,
              initAlbumArtRotation:
                  isFake ? bottomPanelGlobalKey.currentState.controller.value : 0.0,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Permissions.permissionStorageStatus != MyPermissionStatus.granted)
      return Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child:
                        Text('Пожалуйста, предоставьте доступ к хранилищу'))),
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: ButtonTheme(
                minWidth: 130.0, // specific value
                height: 40.0,
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(15.0),
                  ),
                  color: Colors.deepPurple,
                  child: refreshing
                      ? SizedBox(
                          width: 25.0,
                          height: 25.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text('Предоставить'),
                  onPressed: _handlePermissionRequest,
                ),
              ),
            )
          ],
        ),
      );
    if (PlaylistControl.songsEmpty(PlaylistType.global))
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
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(15.0),
                  ),
                  color: Colors.deepPurple,
                  child: refreshing
                      ? SizedBox(
                          width: 25.0,
                          height: 25.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text('Обновить'),
                  onPressed: () async {
                    setState(() {
                      refreshing = true;
                    });
                    await _refreshHandler();
                    setState(() {
                      refreshing = false;
                    });
                  },
                ),
              ),
            )
          ],
        ),
      );
    return _buildTracks();
  }
}

/// TODO: unite this into one class with `TrackList`
class CurrentPlaylistWidget extends StatefulWidget {
  final EdgeInsets bottomPadding;
  CurrentPlaylistWidget({
    Key key,
    this.bottomPadding: const EdgeInsets.only(bottom: 0.0),
  }) : super(key: key);

  @override
  CurrentPlaylistWidgetState createState() => CurrentPlaylistWidgetState();
}

class CurrentPlaylistWidgetState extends State<CurrentPlaylistWidget> {
  ItemScrollController itemScrollController = ItemScrollController();
  ScrollController frontScrollController = ScrollController();
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

    return Padding(
      padding: widget.bottomPadding,
      child: Container(
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
      ),
    );
  }
}

/// `TrackTile` that represents a single track in `TrackList`
class TrackTile extends StatefulWidget {
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
  TrackTile(this.trackTileIndex,
      {Key key,
      this.pushToPlayerRouteOnClick: true,
      this.playing: false,
      this.song,
      this.enabled: true,
      this.additionalClickCallback})
      : super(key: key);

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
        PlaylistControl.globalPlaylist.getSongByIndex(widget.trackTileIndex);
  }

  void _handleTap() async {
    await MusicPlayer.clickTrackTile(_song.id);
    if (widget.additionalClickCallback != null)
      widget.additionalClickCallback();
    // Playing because clickTrackTile changes any other type to it
    if (widget.pushToPlayerRouteOnClick &&
        MusicPlayer.playState == AudioPlayerState.PLAYING)
      Navigator.of(context).push(createPlayerRoute());
  }

// TODO: add playing indicator
  @override
  Widget build(BuildContext context) {
    return ListTile(
        // title: Text("${widget.trackTileIndex}"));
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
