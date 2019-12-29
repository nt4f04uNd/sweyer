/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:sweyer/sweyer.dart';

const double progressLineHeight = 3.0;

/// FIXME: art rotating on main and search routes are distinct

/// Renders current playing track
class BottomTrackPanel extends StatelessWidget {
  BottomTrackPanel({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlaylistControl.getPlaylist(PlaylistType.global).isEmpty)
      return SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: StreamBuilder(
              stream: MusicPlayer.onPlayerStateChanged,
              builder: (context, snapshot) {
                return Material(
                  color: Constants.AppTheme.bottomTrackPanel.auto(context),
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.of(context)
                          .pushNamed(Constants.Routes.player.value);
                    },
                    child: ListTile(
                      dense: true,
                      isThreeLine: false,
                      contentPadding: EdgeInsets.only(
                          top: 5.0, bottom: 5.0, left: 12.0, right: 10.0),
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            PlaylistControl.currentSong?.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16.5),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Artist(
                              artist: PlaylistControl.currentSong?.artist,
                              // textStyle: TextStyle(fontWeight: ThemeControl.isDark ? FontWeight.w400 : FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      leading: RotatingAlbumArtWithProgress(),
                      trailing: Transform.translate(
                        offset: Offset(0, 0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 50.0),
                          child: Stack(
                            children: <Widget>[
                              Transform.translate(
                                // offset: Offset(-16, 0),
                                offset: Offset(0, 0),
                                child: AnimatedPlayPauseButton(
                                  size: 40.0,
                                  iconSize: 28.0,
                                  iconColor: Constants.AppTheme.mainContrast
                                      .auto(context),
                                ),
                              ),
                              // Transform.translate(
                              //   offset: Offset(18, 0),
                              //   child: SMMIconButton(
                              //     icon: Icon(Icons.skip_next),
                              //     onPressed: MusicPlayer.playNext,
                              //     size: 40.0,
                              //     iconSize: 28.0,
                              //     splashColor:
                              //         Constants.AppTheme.splash.auto(context),
                              //     // color: Constants.AppTheme.playPauseIcon
                              //     //     .auto(context),
                              //     color: Constants.AppTheme.mainContrast
                              //         .auto(context),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
        ),
      ),
    );
  }
}

class RotatingAlbumArtWithProgress extends StatefulWidget {
  RotatingAlbumArtWithProgress({Key key}) : super(key: key);

  @override
  _RotatingAlbumArtWithProgressState createState() =>
      _RotatingAlbumArtWithProgressState();
}

class _RotatingAlbumArtWithProgressState
    extends State<RotatingAlbumArtWithProgress> {
  /// Actual track position value
  Duration _value = Duration(seconds: 0);
  // Duration of playing track
  Duration _duration = Duration(seconds: 0);

  StreamSubscription<Duration> _positionSubscription;
  StreamSubscription<Duration> _durationSubscription;
  StreamSubscription<AudioPlayerState> _playerStateChangeSubscription;

  GlobalKey<RotatingAlbumArtState> _rotatingArtGlobalKey =
      GlobalKey<RotatingAlbumArtState>();

  @override
  void initState() {
    super.initState();

    _setInitialCurrentPosition();

    _playerStateChangeSubscription =
        MusicPlayer.onPlayerStateChanged.listen((event) {
      switch (event) {
        case AudioPlayerState.PLAYING:
          _rotatingArtGlobalKey.currentState.rotate();
          break;
        case AudioPlayerState.PAUSED:
        case AudioPlayerState.COMPLETED:
        case AudioPlayerState.STOPPED:
        default: // Can be null so don't throw, just stop animation
          _rotatingArtGlobalKey.currentState.stopRotating();
          break;
      }
    });

    // Handle track position movement
    _positionSubscription = MusicPlayer.onAudioPositionChanged.listen((event) {
      if (event.inSeconds != _value.inSeconds) {
        // Prevent waste updates
        setState(() {
          _value = event;
        });
      }
    });

    // Handle song change
    _durationSubscription = MusicPlayer.onDurationChanged.listen((event) async {
      _value = await MusicPlayer.currentPosition;
      setState(() {
        _duration = event;
        // Update art
        _rotatingArtGlobalKey.currentState.reloadArt(PlaylistControl.currentSong?.albumArtUri);
      });
    });
  }

  @override
  void dispose() {
    _playerStateChangeSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    super.dispose();
  }

  _setInitialCurrentPosition() async {
    var currentPosition = await MusicPlayer.currentPosition;
    setState(() {
      _value = currentPosition;
      _duration = Duration(milliseconds: PlaylistControl.currentSong?.duration);
    });
  }

  double _calcProgress() {
    if (_value.inMilliseconds == 0.0 || _duration.inMilliseconds == 0.0)
      return 0.001;
    // Additional safety checkS
    var result = _value.inMilliseconds / _duration.inMilliseconds;
    if (result < 0)
      result = 0;
    else if (result > 1) result = 0;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CircularPercentIndicator(
        percent: _calcProgress(),
        radius: 48.0 -
            progressLineHeight, // 48.0 is `constraints.maxHeight` if we see it in `LayoutBuilder`
        lineWidth: progressLineHeight,
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: Colors.deepPurple,
        backgroundColor: Colors.transparent,
        center: RotatingAlbumArt(
          key: _rotatingArtGlobalKey,
          path: PlaylistControl.currentSong?.albumArtUri,
          initRotation: math.Random(DateTime.now().second).nextDouble(),
          initIsRotating: MusicPlayer.playerState == AudioPlayerState.PLAYING,
        ),
      ),
    );
  }
}
