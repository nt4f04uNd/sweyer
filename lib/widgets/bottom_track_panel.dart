import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sweyer/sweyer.dart';

const double progressLineHeight = 3.0;

/// Renders current playing track
class TrackPanel extends StatelessWidget {
  TrackPanel({
    Key? key,
    this.onTap,
  }) : super(key: key);

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (ContentControl.state.allSongs.isEmpty) {
      return const SizedBox.shrink();
    }

    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
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
          child: RepaintBoundary(
            child: AnimationStrategyBuilder<bool>(
              strategy: const IgnoringStrategy(
                forward: true,
                completed: true,
              ),
              animation: playerRouteController,
              builder: (context, value, child) => IgnorePointer(
                ignoring: value,
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
                                  key: ValueKey(ContentControl.state.currentSong.id),
                                  fontWeight: FontWeight.w700,
                                  text: ContentControl.state.currentSong.title,
                                  fontSize: 16,
                                  velocity: 26.0,
                                  blankSpace: 40.0,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: ArtistWidget(
                                    artist: ContentControl.state.currentSong.artist,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: textScaleFactor * 50.0),
                            child: const AnimatedPlayPauseButton(
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
          ),
        );
      },
    );
  }
}

class RotatingAlbumArtWithProgress extends StatefulWidget {
  const RotatingAlbumArtWithProgress({Key? key}) : super(key: key);

  @override
  _RotatingAlbumArtWithProgressState createState() => _RotatingAlbumArtWithProgressState();
}

class _RotatingAlbumArtWithProgressState extends State<RotatingAlbumArtWithProgress> {
  static const min = 0.001;

  double initRotation = math.Random(DateTime.now().second).nextDouble();

  /// Actual track position value
  Duration _value = Duration.zero;
  // Duration of playing track
  Duration _duration = Duration.zero;

  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<Song> _songChangeSubscription;
  late StreamSubscription<bool> _playingSubscription;

  final _rotatingArtGlobalKey = GlobalKey<AlbumArtRotatingState>();

  @override
  void initState() {
    super.initState();
    _value = MusicPlayer.instance.position;
    _duration = MusicPlayer.instance.duration;
    _playingSubscription = MusicPlayer.instance.playingStream.listen((playing) {
      if (playing) {
        _rotatingArtGlobalKey.currentState!.rotate();
      } else {
        _rotatingArtGlobalKey.currentState!.stopRotating();
      }
    });
    _positionSubscription = MusicPlayer.instance.positionStream.listen((position) {
      setState(() {
        _value = position;
      });
    });
    _songChangeSubscription = ContentControl.state.onSongChange.listen((event) async {
      _value = MusicPlayer.instance.position;
      setState(() {
        _duration = Duration(milliseconds: event.duration);
      });
    });
  }

  @override
  void dispose() {
    _playingSubscription.cancel();
    _positionSubscription.cancel();
    _songChangeSubscription.cancel();
    super.dispose();
  }

  double get _progress {
    return (_value.inMilliseconds / _duration.inMilliseconds).clamp(min, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final song = ContentControl.state.currentSong;
    return CircularPercentIndicator(
      percent: _progress,
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
        source: ContentArtSource.song(song),
        initRotation: initRotation,
        initRotating: MusicPlayer.instance.playing,
      ),
    );
  }
}
