/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sweyer/sweyer.dart';

const double progressLineHeight = 3.0;

/// Renders current playing track
class TrackPanel extends StatelessWidget {
  TrackPanel({
    Key key,
    this.onTap,
  }) : super(key: key);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (ContentControl.state.queues.all.isEmpty) {
      return const SizedBox.shrink();
    }

    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final playerRouteController = getPlayerRouteControllerProvider(context).controller;
    final fadeAnimation = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        curve: const Interval(0.0, 0.5),
        parent: playerRouteController,
      ),
    );
    return StreamBuilder(
      stream: ContentControl.state.onSongChange,
      builder: (context, snapshot) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: AnimatedBuilder(
            animation: playerRouteController,
            builder: (context, child) => IgnorePointer(
              ignoring: const IgnoringStrategy(
                forward: true,
                completed: true,
              ).evaluate(playerRouteController),
              child: child,
            ),
            child: GestureDetector(
              onTap: onTap,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: kSongTileHeight * math.max(0.95, textScaleFactor),
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 4.0,
                    bottom: 4.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Transform.scale(
                          scale: math.min(1.1, textScaleFactor),
                          child: const RotatingAlbumArtWithProgress(),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              NFMarquee(
                                key: ValueKey(
                                    ContentControl.state.currentSongId),
                                fontWeight: FontWeight.w700,
                                text: ContentControl.state.currentSong.title,
                                fontSize: 16,
                                velocity: 26.0,
                                blankSpace: 40.0,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: ArtistWidget(
                                  artist:
                                      ContentControl.state.currentSong.artist,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).textScaleFactor *
                                  50.0),
                          child: AnimatedPlayPauseButton(
                            size: 40.0,
                            iconSize: 19.0,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class RotatingAlbumArtWithProgress extends StatefulWidget {
  const RotatingAlbumArtWithProgress({Key key}) : super(key: key);

  @override
  _RotatingAlbumArtWithProgressState createState() => _RotatingAlbumArtWithProgressState();
}

class _RotatingAlbumArtWithProgressState
    extends State<RotatingAlbumArtWithProgress> {
  /// Actual track position value
  Duration _value = const Duration(seconds: 0);
  // Duration of playing track
  Duration _duration = const Duration(seconds: 0);

  StreamSubscription<Duration> _positionSubscription;
  StreamSubscription<Song> _songChangeSubscription;
  StreamSubscription<MusicPlayerState> _playerStateSubscription;
  StreamSubscription<void> _songListChangeSubscription;

  GlobalKey<AlbumArtRotatingState> _rotatingArtGlobalKey = GlobalKey<AlbumArtRotatingState>();

  @override
  void initState() {
    super.initState();

    _setInitialCurrentPosition();

    _playerStateSubscription = MusicPlayer.onStateChange.listen((event) {
      switch (event) {
        case MusicPlayerState.PLAYING:
          _rotatingArtGlobalKey.currentState.rotate();
          break;
        case MusicPlayerState.PAUSED:
        case MusicPlayerState.COMPLETED:
        default: // Can be null so don't throw, just stop animation
          _rotatingArtGlobalKey.currentState.stopRotating();
          break;
      }
    });

    // Handle track position movement
    _positionSubscription = MusicPlayer.onPosition.listen((event) {
      if (event.inSeconds != _value.inSeconds) {
        // Prevent waste updates
        setState(() {
          _value = event;
        });
      }
    });

    // Handle song change
    _songChangeSubscription = ContentControl.state.onSongChange.listen((event) async {
      _value = await MusicPlayer.position;
      if (mounted)
        setState(() {
          _duration = Duration(milliseconds: event.duration);
        });
    });

    _songListChangeSubscription = ContentControl.state.onSongListChange.listen((event) async {
      setState(() {
        /// This needed to keep sync with album arts, because they are fetched with [ContentControl.refetchAlbums], which runs without `await` in [ContentControl.init]
        /// So sometimes even though current song is being restored, its album art might still be fetching.
      });
    });
  }

  @override
  void dispose() {
    _playerStateSubscription.cancel();
    _positionSubscription.cancel();
    _songChangeSubscription.cancel();
    _songListChangeSubscription.cancel();
    super.dispose();
  }

  _setInitialCurrentPosition() async {
    var position = await MusicPlayer.position;
    setState(() {
      _value = position;
      _duration =
          Duration(milliseconds: ContentControl.state.currentSong?.duration);
    });
  }

  double _calcProgress() {
    if (_value.inMilliseconds == 0.0 || _duration.inMilliseconds == 0.0) {
      return 0.001;
    }
    // Additional safety checks
    var result = _value.inMilliseconds / _duration.inMilliseconds;
    if (result < 0) {
      result = 0;
    } else if (result > 1) {
      result = 0;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CircularPercentIndicator(
        percent: _calcProgress(),
        animation: true,
        animationDuration: 200,
        curve: Curves.easeOutCubic,
        animateFromLastPercent: true,
        radius: kSongTileArtSize - progressLineHeight,
        lineWidth: progressLineHeight,
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: ThemeControl.theme.colorScheme.primary,
        backgroundColor: Colors.transparent,
        center: AlbumArtRotating(
          key: _rotatingArtGlobalKey,
          path: ContentControl.state.currentSong?.albumArt,
          initRotation: math.Random(DateTime.now().second).nextDouble(),
          initRotating: MusicPlayer.playerState == MusicPlayerState.PLAYING,
        ),
      ),
    );
  }
}
