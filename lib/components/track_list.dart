import 'package:app/components/albumArt.dart';
import 'package:app/player/playerWidgets.dart';
import 'package:app/player/song.dart';
import 'package:app/routes/playerRoute.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:app/player/player.dart';

/// List of fetched tracks
class TrackList extends StatelessWidget {
  TrackList({Key key}) : super(key: key);

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  // TODO: exctract this to constnant
  // final _pageScrollKey = PageStorageKey('MainListView');

  Future<void> _refreshHandler() async {
    await MusicPlayer.instance.playlistControl.refetchSongs();
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 55.0),
      child: Container(
        child: RefreshIndicator(
          color: Colors.white,
          key: _refreshIndicatorKey,
          onRefresh: _refreshHandler,
          child: SingleTouchRecognizerWidget(
            child: ListView.builder(
              // key: _pageScrollKey,
              itemCount:
                  MusicPlayer.instance.playlistControl.globalPlaylist.length,
              padding: EdgeInsets.only(bottom: 10, top: 5),
              itemBuilder: (context, index) {
                return TrackTile(
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
    );
  }
}

/// `TrackTile` that represents a single track in `TrackList`
class TrackTile extends StatelessWidget {
  /// Index of rendering element from
  final int trackTileIndex;

  /// Provide song data to render it directly, not from playlist (e.g. used in search)
  Song song;
  final Function additionalClickCallback;
  TrackTile(this.trackTileIndex, {this.song, this.additionalClickCallback});

//TODO: add comments
  @override
  Widget build(BuildContext context) {
    /// Instance of music player
    final musicPlayer = MusicPlayer.instance;

    /// If song data is not provided, then find it by index of row in current row
    if (song == null)
      song = musicPlayer.playlistControl.globalPlaylist
          .getSongByIndex(trackTileIndex);

    void _handleTap() async {
      // TODO: this should be re-declared on every widget rebuild
      await musicPlayer.clickTrackTile(song.id);
      if (additionalClickCallback != null) additionalClickCallback();
      // Playing because clickTrackTile changes any other type to it
      if (musicPlayer.playState == AudioPlayerState.PLAYING)
        Navigator.of(context).push(createPlayerRoute());
    }

    return ListTile(
        title: Text(
          song.title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 16 /* Default flutter title font size (not densed) */),
        ),
        subtitle: Artist(artist: song.artist),
        dense: true,
        isThreeLine: false,
        leading: AlbumArt(path: song.albumArtUri),
        contentPadding: const EdgeInsets.only(left: 10, top: 0),
        onTap: _handleTap);
  }
}

/// TODO: move this to separate file
class _SingleTouchRecognizer extends OneSequenceGestureRecognizer {
  int _p = 0;
  @override
  void addAllowedPointer(PointerDownEvent event) {
    //first register the current pointer so that related events will be handled by this recognizer
    startTrackingPointer(event.pointer);
    //ignore event if another event is already in progress
    if (_p == 0) {
      resolve(GestureDisposition.rejected);
      _p = event.pointer;
    } else {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  // TODO: implement debugDescription
  String get debugDescription => null;

  @override
  void didStopTrackingLastPointer(int pointer) {
    // TODO: implement didStopTrackingLastPointer
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!event.down && event.pointer == _p) {
      _p = 0;
    }
  }
}

class SingleTouchRecognizerWidget extends StatelessWidget {
  final Widget child;
  SingleTouchRecognizerWidget({this.child});

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        _SingleTouchRecognizer:
            GestureRecognizerFactoryWithHandlers<_SingleTouchRecognizer>(
          () => _SingleTouchRecognizer(),
          (_SingleTouchRecognizer instance) {},
        ),
      },
      child: child,
    );
  }
}
