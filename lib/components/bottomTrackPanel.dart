import 'package:app/player/playerWidgets.dart';
import 'package:app/player/playlist.dart';
import 'package:app/routes/playerRoute.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:app/player/player.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'albumArt.dart';
import 'animatedPlayPauseButton.dart';
import 'dart:async';
import 'dart:math' as math;

class BottomTrackPanel extends StatefulWidget {
  BottomTrackPanel({Key key}) : super(key: key);

  @override
  _BottomTrackPanelState createState() => _BottomTrackPanelState();
}

/// FIXME: circular progress not rendering on app start
/// FIXME: art rotating on main and search routes are distinct
class _BottomTrackPanelState extends State<BottomTrackPanel>
    with SingleTickerProviderStateMixin {
  final _musicPlayer = MusicPlayer.instance;

  Animation<double> animation;
  AnimationController controller;

  /// Actual track position value
  Duration _value = Duration(seconds: 0);
  // Duration of playing track
  Duration _duration = Duration(seconds: 0);

  /// Subscription for audio position change stream
  StreamSubscription<Duration> _changePositionSubscription;
  StreamSubscription<void> _changeSongSubscription;
  StreamSubscription<AudioPlayerState> _playerStateChangeSubscription;

  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();

    _setInitialCurrentPosition();
    _getPrefsInstance();

    controller =
        AnimationController(duration: const Duration(seconds: 15), vsync: this);

    // animation = Tween<double>(begin: 0, end: 1).animate(controller)
    controller
      ..addListener(() {
        setState(() {
          // The state that has changed here is the animation object’s value.
        });
      });

    // Spawn animation settings
    if (_musicPlayer.playState == AudioPlayerState.PLAYING)
      controller.repeat();
    else if (_musicPlayer.playState == AudioPlayerState.PAUSED)
      controller.stop();
    else if (_musicPlayer.playState == AudioPlayerState.STOPPED)
      controller.stop();

    _playerStateChangeSubscription =
        _musicPlayer.onPlayerStateChanged.listen((event) {
      switch (event) {
        case AudioPlayerState.PLAYING:
          controller.repeat();
          break;
        case AudioPlayerState.PAUSED:
          controller.stop();
          break;
        case AudioPlayerState.COMPLETED:
          break;
        case AudioPlayerState.STOPPED:
          controller.stop();
          break;
        default:
          controller.stop();
          break;
      }
    });

    // Handle track position movement
    _changePositionSubscription =
        _musicPlayer.onAudioPositionChanged.listen((event) {
      if (event.inSeconds - 0.9 > _value.inSeconds) // Prevent waste updates
        setState(() {
          _value = event;
        });
      else if (event.inMilliseconds < 200) {
        setState(() {
          _value = event;
        });
      }
    });

    // Handle track switch
    _changeSongSubscription = _musicPlayer.onSongChange.listen((event) {
      setState(() {
        _value = Duration(seconds: 0);
        _duration = Duration(
            milliseconds: _musicPlayer.playlistControl.currentSong.duration);
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _playerStateChangeSubscription.cancel();
    _changePositionSubscription.cancel();
    _changeSongSubscription.cancel();
    super.dispose();
  }

  void _getPrefsInstance() async {
    prefs = await SharedPreferences.getInstance();
  }

  _setInitialCurrentPosition() async {
    var currentPosition = await _musicPlayer.currentPosition;
    setState(() {
      _value = currentPosition;
      _duration = Duration(
          milliseconds: _musicPlayer.playlistControl.currentSong.duration);
    });
  }

  @override
  Widget build(BuildContext context) {
    return !_musicPlayer.playlistControl.songsEmpty(PlaylistType.global)
        ? Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                child: GestureDetector(
              onTap: () async {
                // Push to player route
                Navigator.of(context).push(createPlayerRoute());
              },
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25)),
                child: Material(
                  color: Color(0xff070707),
                  // color: Colors.grey.shade900,
                  child: StreamBuilder(
                      stream: _musicPlayer.onPlayerStateChanged,
                      builder: (context, snapshot) {
                        return ListTile(
                          contentPadding: EdgeInsets.only(
                              top: 5.0, bottom: 5.0, left: 10.0, right: 10.0),
                          title: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _musicPlayer.playlistControl.currentSong.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 16),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Artist(
                                    artist: _musicPlayer
                                        .playlistControl.currentSong.artist),
                              ),
                            ],
                          ),
                          isThreeLine: false,
                          leading:
                              LayoutBuilder(builder: (context, constraints) {
                            const lineWidth = 3.0;
                            return CircularPercentIndicator(
                              percent: _value.inMilliseconds /
                                  _duration.inMilliseconds,
                              radius: constraints.maxHeight - lineWidth,
                              lineWidth: lineWidth,
                              circularStrokeCap: CircularStrokeCap.round,
                              progressColor: Colors.deepPurple,
                              // backgroundColor: Colors.white.withOpacity(0.05),
                              backgroundColor: Colors.transparent,
                              center: Transform.rotate(
                                angle: controller.value * 2 * math.pi,
                                child: Container(
                                  // padding: const EdgeInsets.all(5.0),
                                  child: AlbumArt(
                                    path: _musicPlayer.playlistControl
                                        .currentSong.albumArtUri,
                                    round: true,
                                  ),
                                ),
                              ),
                            );
                          }),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              //  IconButton(
                              //   icon: Icon(Icons.skip_previous),
                              //   iconSize: 32,
                              //   onPressed: _musicPlayer.clickPrev,
                              // ),
                              Container(
                                  width: 32, child: AnimatedPlayPauseButton()),
                              IconButton(
                                icon: Icon(Icons.skip_next),
                                iconSize: 32,
                                onPressed: _musicPlayer.clickNext,
                              ),
                            ],
                          ),
                          dense: true,
                        );
                      }),
                ),
              ),
            )),
          )
        : SizedBox.shrink();
  }
}
