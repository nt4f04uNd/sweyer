import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:sweyer/sweyer.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:sweyer/constants.dart' as constants;

const double _kIconSize = 22.0;
const double _kButtonSize = 66.0;

class AnimatedPlayPauseButton extends StatefulWidget {
  const AnimatedPlayPauseButton({
    Key? key,
    this.player,
    this.iconSize,
    this.size,
    this.iconColor,
  }) : super(key: key);

  final AudioPlayer? player;
  final double? iconSize;
  final double? size;
  final Color? iconColor;

  @override
  AnimatedPlayPauseButtonState createState() => AnimatedPlayPauseButtonState();
}

class AnimatedPlayPauseButtonState extends State<AnimatedPlayPauseButton> with TickerProviderStateMixin {
  late AnimationController controller;
  StreamSubscription<bool>? _playingSubscription;
  AudioPlayer get player => widget.player ?? MusicPlayer.instance;

  late String _animation;
  set animation(String value) {
    setState(() {
      _animation = value;
    });
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _update();
  }

  void _update() {
    if (player.playing) {
      _animation = 'pause';
    } else {
      controller.value = 1.0;
      _animation = 'play';
    }
    _playingSubscription?.cancel();
    _playingSubscription = player.playingStream.listen((playing) {
      /// Do not handle [PlayerState.PLAYING] as it's not the state the player will remain for long time.
      /// It will start playing next song immediately.
      if (playing) {
        _pause();
      } else {
        _play();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedPlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      _update();
    }
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    controller.dispose();
    super.dispose();
  }

  /// Animates to state where it shows "play" button.
  void _play() {
    if (_animation != 'pause_play' && _animation != 'play') {
      controller.forward();
      animation = 'pause_play';
    }
  }

  /// Animates to state where it shows "pause" button.
  void _pause() {
    if (_animation != 'play_pause' && _animation != 'pause') {
      controller.reverse();
      animation = 'play_pause';
    }
  }

  void _handlePress() {
    if (player.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final slideAnimation = Tween(
      begin: Offset.zero,
      end: const Offset(0.05, 0.0),
    ).animate(baseAnimation);
    final scaleAnimation = Tween(begin: 1.05, end: 0.89).animate(baseAnimation);
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final color = widget.iconColor ?? ThemeControl.instance.theme.iconTheme.color!;
    return NFIconButton(
      size: textScaleFactor * (widget.size ?? _kButtonSize),
      iconSize: textScaleFactor * (widget.iconSize ?? _kIconSize),
      onPressed: _handlePress,
      icon: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          // Needed because for some reason the color is not updated on theme change.
          key: ValueKey(color),
          child: RepaintBoundary(
            child: FlareActor(
              constants.Assets.assetAnimationPlayPause,
              animation: _animation,
              callback: (value) {
                if (value == 'pause_play' && _animation != 'play_pause') {
                  animation = 'play';
                } else if (value == 'play_pause' && _animation != 'pause_play') {
                  animation = 'pause';
                }
              },
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
