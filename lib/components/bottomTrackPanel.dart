import 'package:app/components/custom_icon_button.dart';
import 'package:app/player/player_widgets.dart';
import 'package:app/constants/constants.dart';
import 'package:app/player/playlist.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:app/player/player.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'albumArt.dart';
import 'animatedPlayPauseButton.dart';
import 'dart:async';
import 'dart:math' as math;

/// Renders current playing track
class BottomTrackPanel extends StatefulWidget {
  /// A value from 0.0 to 1.0 to set initial album art rotation
  final double initAlbumArtRotation;
  BottomTrackPanel({Key key, this.initAlbumArtRotation: 0.0})
      : assert(initAlbumArtRotation >= 0 && initAlbumArtRotation <= 1.0),
        super(key: key);

  @override
  BottomTrackPanelState createState() => BottomTrackPanelState();
}

/// FIXME: art rotating on main and search routes are distinct
class BottomTrackPanelState extends State<BottomTrackPanel>
    with SingleTickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();

    _setInitialCurrentPosition();

    controller =
        AnimationController(duration: const Duration(seconds: 15), vsync: this);
    controller.value = widget.initAlbumArtRotation;

    controller
      ..addListener(() {
        setState(() {
          // The state that has changed here is the animation object’s value.
        });
      });

    // Spawn animation settings
    if (MusicPlayer.playState == AudioPlayerState.PLAYING)
      controller.repeat();
    else if (MusicPlayer.playState == AudioPlayerState.PAUSED)
      controller.stop();
    else if (MusicPlayer.playState == AudioPlayerState.STOPPED)
      controller.stop();

    _playerStateChangeSubscription =
        MusicPlayer.onPlayerStateChanged.listen((event) {
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
        default: // Can be null so don't throw, just stop animation
          controller.stop();
          break;
      }
    });

    // Handle track position movement
    _changePositionSubscription =
        MusicPlayer.onAudioPositionChanged.listen((event) {
      if (event.inSeconds != _value.inSeconds) {
        // Prevent waste updates
        setState(() {
          _value = event;
        });
      }
    });

    // Handle song change
    _changeSongSubscription =
        PlaylistControl.onSongChange.listen((event) async {
      _value = await MusicPlayer.currentPosition;
      setState(() {
        _duration =
            Duration(milliseconds: PlaylistControl.currentSong?.duration);
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

  _setInitialCurrentPosition() async {
    var currentPosition = await MusicPlayer.currentPosition;
    setState(() {
      _value = currentPosition;
      _duration = Duration(milliseconds: PlaylistControl.currentSong?.duration);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!PlaylistControl.songsEmpty(PlaylistType.global)) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          // padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              // bottomLeft: Radius.circular(26),
              // bottomRight: Radius.circular(26),
            ),
            child: StreamBuilder(
                stream: MusicPlayer.onPlayerStateChanged,
                builder: (context, snapshot) {
                  return Material(
                    // color: Color(0xff090909),
                    color: AppTheme.bottomTrackPanel.auto(context),
                    child: GestureDetector(
                      onTap: () async {
                        // Push to player route
                        // Navigator.of(context).push(createPlayerRoute());
                        Navigator.of(context).pushNamed(Routes.player.value);
                      },
                      child: ListTile(
                        contentPadding: EdgeInsets.only(
                            top: 5.0, bottom: 5.0, left: 10.0, right: 10.0),
                        title: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              PlaylistControl.currentSong?.title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Artist(
                                  artist: PlaylistControl.currentSong?.artist),
                            ),
                          ],
                        ),
                        isThreeLine: false,
                        leading: LayoutBuilder(builder: (context, constraints) {
                          const lineWidth = 3.0;
                          return CircularPercentIndicator(
                            percent: _value.inMilliseconds /
                                _duration.inMilliseconds,
                            radius: constraints.maxHeight - lineWidth,
                            lineWidth: lineWidth,
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: Colors.deepPurple,
                            backgroundColor: Colors.transparent,
                            center: Transform.rotate(
                              angle: controller.value * 2 * math.pi,
                              child: Container(
                                child: AlbumArt(
                                  path:
                                      PlaylistControl.currentSong?.albumArtUri,
                                  round: true,
                                ),
                              ),
                            ),
                          );
                        }),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Transform.translate(
                              offset: Offset(10, 0),
                              child: AnimatedPlayPauseButton(
                                isLarge: true,
                              ),
                            ),
                            CustomIconButton(
                              iconSize: 32,
                              splashColor: AppTheme.splash.auto(context),
                              size: 56,
                              icon: Icon(Icons.skip_next),
                              color: AppTheme.playPauseIcon.auto(context),
                              onPressed: MusicPlayer.playNext,
                            ),
                          ],
                        ),
                        dense: true,
                      ),
                    ),
                  );
                }),
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}
