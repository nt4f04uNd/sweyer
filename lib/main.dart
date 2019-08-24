import 'dart:io';
import 'package:flutter/material.dart';
// import 'marquee.dart';
import 'musicPlayer.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData.dark(),
      home: Player(),
    );
  }
}

class PlayerState extends State<Player> {
  final _biggerFont = const TextStyle(fontSize: 19.0);
  MusicPlayer _musicPlayer;

  // PlayerState() {
  // }
  @override
  void initState() {
    super.initState();
    // Init music player instance
    _musicPlayer = MusicPlayer(setState);
  }

  void _pushToPlayerPage() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(0.0, 1.0);
          var end = Offset.zero;
          var curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        pageBuilder: (context, animation, secondaryAnimation) {
          // final Iterable<ListTile> tiles = _saved.map(
          //   (WordPair pair) {
          //     return ListTile(
          //       title: Text(
          //         pair.asPascalCase,
          //         style: _biggerFont,
          //       ),
          //     );
          //   },
          // );

          // final List<Widget> divided = ListTile.divideTiles(
          //   context: context,
          //   tiles: tiles,
          // ).toList();

          return Scaffold(appBar: AppBar(title: Text('')));
        },
      ),
    );
  }

  void _trackPressHandler(int index) async {
    debugPrint(_musicPlayer.playerState.toString());
    switch (_musicPlayer.playerState) {
      case PlayerStateType.playing:
        // If user clicked the same track
        if (_musicPlayer.playingIndexState == index) {
          _musicPlayer.pause();
        }
        // If user decided to click a new track
        else {
          _musicPlayer.stop();
          _musicPlayer.play(index);
        }
        break;
      case PlayerStateType.paused:
        // If user clicked the same track
        if (_musicPlayer.playingIndexState == index) {
          _musicPlayer.play(index);
        }
        // If user decided to click a new track
        else {
          _musicPlayer.stop();
          _musicPlayer.play(index);
        }
        break;
      case PlayerStateType.stopped:
        _musicPlayer.play(index);
        break;
      default:
        break;
    }
  }

  Widget _buildRow(int index) {
    /// Song in current row
    final rowSong = _musicPlayer.getSong(index);

    return ListTile(
        title: Text(
          rowSong.title,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: false,
        subtitle: Text(rowSong.artist != '<unknown>'
            ? rowSong.artist
            : 'Неизестный исполнитель'),
        leading: rowSong.albumArt != null
            ? Image.file(
                File(rowSong.albumArt),
                height: 40,
                width: 40,
                // alignment: Alignment.center,
                // height: 50,
                fit: BoxFit.cover,
              )
            : Image.asset(
                'assets/img/defaultAlbumArt.png',
                // width: 35,
                height: 40,
                fit: BoxFit.contain,
              ),
        contentPadding: EdgeInsets.only(left: 10, top: 0),
        onTap: () => _trackPressHandler(index));
  }

  @override
  Widget build(BuildContext context) {
    var temp = Text(
      _musicPlayer.currentSong.title,
      overflow: TextOverflow.ellipsis,
      style: _biggerFont,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Startup Name Generator'),
      ),
      body: ListView.builder(
        // padding: EdgeInsets.all(5),
        itemExtent: 50,
        itemCount: _musicPlayer.songsCount,
        itemBuilder: (context, index) {
          return Container(height: 50, child: _buildRow(index));
        },
      ),
      bottomNavigationBar: Container(
        child: BottomAppBar(
            child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 7, horizontal: 16),
          title: temp,
          leading: _musicPlayer.currentSong.albumArt != null
              ? Image.file(
                  File(_musicPlayer.currentSong.albumArt),
                  fit: BoxFit.contain,
                )
              : Image.asset(
                  'assets/img/defaultAlbumArt.png',
                  // width: 35,
                  fit: BoxFit.contain,
                ),
          dense: true,
          onTap: _pushToPlayerPage,
        )),
      ),
    );
  }
}

class Player extends StatefulWidget {
  @override
  PlayerState createState() => PlayerState();
}
