import 'package:app/components/albumArt.dart';
// import 'package:app/components/albumArtPlaceholder.dart';
import 'package:flutter/material.dart';
import 'package:app/musicPlayer.dart';

/// List of fetched tracks
class TrackList extends StatelessWidget {
  const TrackList({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: MusicPlayer.getInstance.songsCount,
      itemBuilder: (context, index) {
        return TrackTile(index);
      },
    );
  }
}

/// `TrackTile` that represents a single track in `TrackList`
class TrackTile extends StatelessWidget {
  /// Index of rendering element from
  final trackTileIndex;
  TrackTile(this.trackTileIndex);

//TODO: add comments
  @override
  Widget build(BuildContext context) {
    /// Instance of music player
    final musicPlayer = MusicPlayer.getInstance;

    /// Song in current row
    final song = musicPlayer.getSong(trackTileIndex);
    void _handleTap() {
      musicPlayer.clickTrackTile(trackTileIndex);
    }

    return ListTile(
        title: Text(
          song.title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 16 /* Default flutter title font size (not densed) */),
        ),
        subtitle: Text(
          // TODO: make unknown artist null istead of '<unknown>'
          song.artist != '<unknown>' ? song.artist : 'Неизестный исполнитель',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize:
                  14 /* Default flutter subtitle font size (not densed) */),
        ),
        dense: true,
        isThreeLine: false,
        leading: AlbumArt(path: song.albumArtUri),
        contentPadding: EdgeInsets.only(left: 10, top: 0),
        onTap: _handleTap);
  }
}
