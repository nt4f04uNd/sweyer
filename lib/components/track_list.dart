import 'package:app/components/SingleTouchRecognizer.dart';
import 'package:app/components/albumArt.dart';
import 'package:app/player/playerWidgets.dart';
import 'package:app/player/song.dart';
import 'package:app/routes/playerRoute.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:app/player/player.dart';
import 'scrollable_positioned_list/scrollable_positioned_list.dart';

/// List of fetched tracks
class TrackList extends StatefulWidget {
  final EdgeInsets bottomPadding;
  TrackList({Key key, this.bottomPadding: const EdgeInsets.only(bottom: 0.0)})
      : super(key: key);

  @override
  _TrackListState createState() => _TrackListState();
}

class _TrackListState extends State<TrackList> {
  // TODO: exctract this to constnant
  static final PageStorageKey _pageScrollKey = PageStorageKey('MainListView');

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  Future<void> _refreshHandler() async {
    await MusicPlayer.instance.playlistControl.refetchSongs();
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.bottomPadding,
      child: Container(
        child: RefreshIndicator(
          color: Colors.white,
          key: _refreshIndicatorKey,
          onRefresh: _refreshHandler,
          child: SingleTouchRecognizerWidget(
            child: Container(
              child: ListView.builder(
                key: _pageScrollKey,
                itemCount:
                    MusicPlayer.instance.playlistControl.globalPlaylist.length,
                padding: EdgeInsets.only(bottom: 10, top: 5),
                itemBuilder: (context, index) {
                  // return StreamBuilder(
                  //     stream: MusicPlayer.instance.onDurationChanged,
                  //     builder: (context, snapshot) {
                  //       return TrackTile(
                  //         index,
                  //         playing: MusicPlayer
                  //                 .instance.playlistControl.globalPlaylist
                  //                 .getSongIndexById(MusicPlayer.instance
                  //                     .playlistControl.currentSong.id) ==
                  //             index,
                  //         additionalClickCallback: () {
                  //           MusicPlayer.instance.playlistControl
                  //               .resetPlaylist();
                  //         },
                  //       );
                  //     });
                  return TrackTile(
                    index,
                    playing: MusicPlayer.instance.playlistControl.globalPlaylist
                            .getSongIndexById(MusicPlayer
                                .instance.playlistControl.currentSong.id) ==
                        index,
                    additionalClickCallback: () {
                      MusicPlayer.instance.playlistControl.resetPlaylist();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// TODO: unite this into one class with `TrackList`
class TrackList2 extends StatefulWidget {
  final EdgeInsets bottomPadding;

  /// If button is already shown
  final bool scrollButtonShown;

  /// Function to show scroll button
  final Function showHideScrollButton;
  TrackList2({
    Key key,
    this.scrollButtonShown: false,
    @required this.showHideScrollButton,
    this.bottomPadding: const EdgeInsets.only(bottom: 0.0),
  })  : assert(showHideScrollButton != null),
        super(key: key);

  @override
  TrackListState2 createState() => TrackListState2();
}

class TrackListState2 extends State<TrackList2> {
  ItemScrollController itemScrollController = ItemScrollController();
  // TODO: FIXME: DELETE BACKSCROLLCONTROLLER AS IT DOES NOTHING AND ADD COMMENTS
  ScrollController _frontScrollController = ScrollController();
  ScrollController _backScrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((duration) {
      // itemScrollController.
      _frontScrollController.addListener(() {
        if (_frontScrollController.offset > 400) {
          if (!widget.scrollButtonShown)
            widget.showHideScrollButton(true, ScrollButtonType.up);
        } else if (_frontScrollController.offset < -400) {
          if (!widget.scrollButtonShown)
            widget.showHideScrollButton(true, ScrollButtonType.down);
        } else {
          if (widget.scrollButtonShown) widget.showHideScrollButton(false);
        }
      });
    });
    return Padding(
      padding: widget.bottomPadding,
      child: Container(
        child: SingleTouchRecognizerWidget(
          child: ScrollablePositionedList.builder(
            frontScrollController: _frontScrollController,
            itemScrollController: itemScrollController,
            itemCount: MusicPlayer.instance.playlistControl.playlist.length,
            padding: EdgeInsets.only(bottom: 10, top: 5),
            initialScrollIndex: MusicPlayer.instance.playlistControl.playlist
                .getSongIndexById(
                    MusicPlayer.instance.playlistControl.currentSong.id),
            itemBuilder: (context, index) {
              // return StreamBuilder(
              //     stream: MusicPlayer.instance.onDurationChanged,
              //     builder: (context, snapshot) {
              //       return TrackTile(
              //         index,
              //         playing: MusicPlayer
              //                 .instance.playlistControl.globalPlaylist
              //                 .getSongIndexById(MusicPlayer
              //                     .instance.playlistControl.currentSong.id) ==
              //             index,
              //         song: MusicPlayer.instance.playlistControl.playlist
              //             .getSongByIndex(index),
              //         pushToPlayerRouteOnClick: false,
              //       );
              //     });
             return TrackTile(
                index,
                playing: MusicPlayer.instance.playlistControl.globalPlaylist
                        .getSongIndexById(MusicPlayer
                            .instance.playlistControl.currentSong.id) ==
                    index,
                song: MusicPlayer.instance.playlistControl.playlist
                    .getSongByIndex(index),
                pushToPlayerRouteOnClick: false,
              );
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

  /// Provide song data to render it directly, not from playlist (e.g. used in search)
  Song song;
  TrackTile(this.trackTileIndex,
      {this.pushToPlayerRouteOnClick: true,
      this.playing: false,
      song,
      this.additionalClickCallback}) {
    /// If song data is not provided, then find it by index of row in current row
    if (song == null)
      this.song = MusicPlayer.instance.playlistControl.globalPlaylist
          .getSongByIndex(trackTileIndex);
    else
      this.song = song;
  }

  @override
  _TrackTileState createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  /// Instance of music player
  final musicPlayer = MusicPlayer.instance;

  void _handleTap() async {
    // TODO: this should be re-declared on every widget rebuild
    await musicPlayer.clickTrackTile(widget.song.id);
    if (widget.additionalClickCallback != null)
      widget.additionalClickCallback();
    // Playing because clickTrackTile changes any other type to it
    if (widget.pushToPlayerRouteOnClick &&
        musicPlayer.playState == AudioPlayerState.PLAYING)
      Navigator.of(context).push(createPlayerRoute());
  }

// TODO: add playing indicator
  @override
  Widget build(BuildContext context) {
    return ListTile(
        // title: Text("${widget.trackTileIndex}"));
        title: Text(
          widget.song.title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 16 /* Default flutter title font size (not densed) */),
        ),
        subtitle: Artist(artist: widget.song.artist),
        dense: true,
        isThreeLine: false,
        leading: AlbumArt(path: widget.song.albumArtUri),
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
