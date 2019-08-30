import 'package:app/heroes/albumArtHero.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:app/components/animatedPlayPauseButton.dart';
import 'package:app/components/track_list.dart';
import 'package:app/musicPlayer.dart';
import 'package:app/routes/playerRoute.dart';
import 'package:audioplayers/audioplayers.dart';

class MainRouteState extends State<MainRoute> {
  static final _biggerFont = const TextStyle(fontSize: 19.0);

  /// Music player class instance
  MusicPlayer _musicPlayer;

  /// Music player change subscription
  StreamSubscription<AudioPlayerState> _playerChangeSubscription;

  /// Event channel for receiving native android events
  static const _eventChannel = const EventChannel('eventChannelStream');

  /// Subscription for android headphones disconnect event
  StreamSubscription _noisySubscription;

  @override
  void initState() {
    super.initState();
    // Init music player instance
    _musicPlayer = MusicPlayer();

    _playerChangeSubscription =
        _musicPlayer.onPlayerStateChanged.listen((event) {
      setState(() {});
    });
  _musicPlayer.onDurationChanged.listen((event) {
      _musicPlayer.switching = false;
    });

    if (_noisySubscription == null) {
      _noisySubscription =
          _eventChannel.receiveBroadcastStream().listen((kavo) {
        debugPrint(kavo.toString());
        if (kavo == "became_noisy") {
          _musicPlayer.pause();
        }
      });
    }
  }

  void _pushToPlayerPage() {
    Navigator.of(context).push(createPlayerRoute());
  }

//TODO: continue splitting code to classes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Music Player'),
      ),
      body: _musicPlayer.songsReady
          ? TrackList()
          : Center(
              child: CircularProgressIndicator(),
            ),
      bottomNavigationBar: _musicPlayer.songsReady
          ? GestureDetector(
              onTap: _pushToPlayerPage,
              child: Container(
                child: BottomAppBar(
                  color: Colors.black,
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                    title: Text(
                      _musicPlayer.currentSong.title,
                      overflow: TextOverflow.ellipsis,
                      style: _biggerFont,
                    ),
                    leading: AlbumArtHero(
                        path: _musicPlayer.currentSong.albumArtUri),
                    trailing: Container(
                      child: Container(
                        child: AnimatedPlayPauseButton(),
                      ),
                    ),
                    dense: true,
                  ),
                ),
              ),
            )
          : SizedBox.shrink(),
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
