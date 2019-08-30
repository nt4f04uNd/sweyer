import 'dart:async';
import 'dart:io';
import 'package:app/components/animatedPlayPauseButton.dart';
import 'package:app/heroes/albumArtHero.dart';
// import 'package:app/heroes/noteIconHero.dart';
import 'package:flutter/material.dart';

import 'package:app/musicPlayer.dart';
import 'dart:math' as math;

Route createPlayerRoute() {
  return PageRouteBuilder(
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = Offset(0.0, 1.0);
      var end = Offset.zero;
      var curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return _PlayerRoute();
    },
  );
}

class _PlayerRoute extends StatefulWidget {
  @override
  _PlayerPageState createState() => _PlayerPageState();
}

class _PlayerPageState extends State<_PlayerRoute> {
  /// Actual track position value
  Duration _value = Duration(seconds: 0);
  // Duration of playing track
  Duration _duration = Duration(seconds: 0);

  /// Value to perform drag
  double _localValue;

  /// Subscription for audio position change stream
  StreamSubscription<Duration> _changePositionSubscription;
  StreamSubscription<dynamic> _changeStateSubscription;

  /// Is user dragging slider right now
  bool _isDragging = false;
  MusicPlayer _musicPlayer = MusicPlayer.getInstance;

  @override
  void initState() {
    super.initState();

    _setInitialCurrentPosition();

    _changePositionSubscription =
        _musicPlayer.onAudioPositionChanged.listen((event) {
      setState(() {
        _value = event;
      });
    });
    _changeStateSubscription =
        _musicPlayer.onPlayerStateChanged.listen((event) {
      setState(() {
        _duration = Duration(milliseconds: _musicPlayer.currentSong.duration);
      });
    });
  }

  _setInitialCurrentPosition() async {
    var res = await _musicPlayer.currentPosition;
    setState(() {
      _value = Duration(milliseconds: res);
      _duration = Duration(milliseconds: _musicPlayer.currentSong.duration);
    });
  }

  void _handleChangeStart(double newValue) async {
    setState(() {
      _localValue = newValue;
      _isDragging = true;
    });
  }

  void _handleChanged(double newValue) {
    setState(() {
      _localValue = newValue;
    });
  }

  void _handleChangeEnd(double newValue) async {
    await _musicPlayer.seek(newValue.toInt());
    setState(() {
      _value = Duration(seconds: newValue.toInt());
      _isDragging = false;
    });
  }

// TODO: refactor these to functions
  String _calculateDisplayedPositionTime() {
    /// Value to work with, depends on `_isDragging` state, either `_value` or `_localValue`
    Duration workingValue;
    if (_isDragging)
      workingValue = Duration(seconds: _localValue.toInt());
    else
      workingValue = _value;

    int minutes = workingValue.inMinutes;
    // Seconds in 0-59 format
    int seconds = workingValue.inSeconds % 60;
    return '${minutes.toString().length < 2 ? 0 : ''}$minutes:${seconds.toString().length < 2 ? 0 : ''}$seconds';
  }

  String _calculateDisplayedDurationTime() {
    int minutes = _duration.inMinutes;
    // Seconds in 0-59 format
    int seconds = _duration.inSeconds % 60;
    return '${minutes.toString().length < 2 ? 0 : ''}$minutes:${seconds.toString().length < 2 ? 0 : ''}$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(63.0), // here the desired height
        child: AppBar(
          /// TODO: make back button effect to be overflowen out of appbar
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.pop(context, false),
          ),
          automaticallyImplyLeading: false,
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 0),
            child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      _musicPlayer.currentSong.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 21),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 5, bottom: 30),
                    child: Text(
                      _musicPlayer.currentSong.artist != '<unknown>'
                          ? _musicPlayer.currentSong.artist
                          : 'Неизестный исполнитель',
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                    child: AlbumArtHero(
                      path: _musicPlayer.currentSong.albumArtUri,
                      isLarge: true,
                    ),
                  ),
                ]),
          ),
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      transform: Matrix4.translationValues(5, 0, 0),
                      child: Text(
                        // TODO: move and refactor this code, and by the way split a whole page for separate widgets
                        _calculateDisplayedPositionTime(),
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        activeColor: Colors.deepPurple.shade500,
                        inactiveColor: Colors.white.withOpacity(0.2),
                        value: _isDragging
                            ? _localValue
                            : _value.inSeconds.toDouble(),
                        max: Duration(
                                milliseconds: _musicPlayer.currentSong.duration)
                            .inSeconds
                            .toDouble(),
                        min: 0,
                        onChangeStart: _handleChangeStart,
                        onChanged: _handleChanged,
                        onChangeEnd: _handleChangeEnd,
                      ),
                    ),
                    Container(
                      transform: Matrix4.translationValues(-5, 0, 0),
                      child: Text(
                        _calculateDisplayedDurationTime(),
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 40, top: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 1,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: InkWell(
                          radius: 50,
                          borderRadius: BorderRadius.circular(100),
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.skip_previous,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          onTap: () {
                            if (!_musicPlayer.switching)
                              _musicPlayer.clickTrackTile(
                                  _musicPlayer.playingIndexState - 1 < 0
                                      // Additional svae
                                      ? _musicPlayer.songsCount - 1
                                      : _musicPlayer.playingIndexState - 1);
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                              width: 1, color: Colors.white.withOpacity(0.15)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: AnimatedPlayPauseButton(),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              width: 1, color: Colors.white.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: InkWell(
                          radius: 50,
                          borderRadius: BorderRadius.circular(100),
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.skip_next,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          onTap: () {
                            if (!_musicPlayer.switching) {
                              _musicPlayer.clickTrackTile(
                                  _musicPlayer.playingIndexState + 1 >=
                                          _musicPlayer.songsCount
                                      ? 0
                                      : _musicPlayer.playingIndexState + 1);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _changePositionSubscription.cancel();
    _changeStateSubscription.cancel();
    super.dispose();
  }
}
