import 'package:app/heroes/albumArtHero.dart';
import 'package:app/routes/playerRoute.dart';
import 'package:flutter/material.dart';
import 'package:app/musicPlayer.dart';
import 'animatedPlayPauseButton.dart';

class BottomTrackPanel extends StatelessWidget {
  final _musicPlayer = MusicPlayer.getInstance;
  BottomTrackPanel({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
          child: GestureDetector(
        onTap: () async {
          // Push to player route
          Navigator.of(context).push(createPlayerRoute());
        },
        child: ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(7), topRight: Radius.circular(7)),
          child: Material(
            color: Color(0xff070707),
            child: StreamBuilder(
                stream: _musicPlayer.onPlayerStateChanged,
                builder: (context, snapshot) {
                  return ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _musicPlayer.currentSong.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child:
                              Artist(artist: _musicPlayer.currentSong.artist),
                        ),
                      ],
                    ),
                    isThreeLine: false,
                    leading: AlbumArtHero(
                        path: _musicPlayer.currentSong.albumArtUri),
                    trailing: Container(
                      child: Container(
                        child: AnimatedPlayPauseButton(),
                      ),
                    ),
                    dense: true,
                  );
                }),
          ),
        ),
      )),
    );
  }
}
