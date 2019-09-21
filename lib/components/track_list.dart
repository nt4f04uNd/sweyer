import 'package:app/components/albumArt.dart';
import 'package:app/routes/playerRoute.dart';
import 'package:flutter/material.dart';
import 'package:app/player/player.dart';

/// List of fetched tracks
class TrackList extends StatelessWidget {
  TrackList({Key key}) : super(key: key);

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  // TODO: exctract this to constnant
  final _pageScrollKey = PageStorageKey('MainListView');

  Future<void> _refreshHandler() async {
    await MusicPlayer.getInstance.fetchSongs();
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
          child: ListView.builder(
            key: _pageScrollKey,
            itemCount: MusicPlayer.getInstance.songsCount,
            padding: EdgeInsets.only(bottom: 10, top: 5),
            itemBuilder: (context, index) {
              return TrackTile(
                index,
                additionalClickCallback: () {
                  MusicPlayer.getInstance.resetPlaylist();
                },
              );
            },
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
  final Function additionalClickCallback;
  TrackTile(this.trackTileIndex, {this.additionalClickCallback});

//TODO: add comments
  @override
  Widget build(BuildContext context) {
    /// Instance of music player
    final musicPlayer = MusicPlayer.getInstance;

    /// Song in current row
    final song = musicPlayer.getSongByIndex(trackTileIndex);

    void _handleTap() async {
      if (additionalClickCallback != null) additionalClickCallback();
      await musicPlayer.clickTrackTile(song.id);
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
