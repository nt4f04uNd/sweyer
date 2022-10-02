import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:sweyer/sweyer.dart';
import 'package:lottie/lottie.dart';
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

class AnimatedPlayPauseButtonState extends State<AnimatedPlayPauseButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  StreamSubscription<bool>? _playingSubscription;
  AudioPlayer get player => widget.player ?? MusicPlayer.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  void _update() {
    if (!player.playing) {
      _controller.value = 1.0;
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
    _controller.dispose();
    super.dispose();
  }

  /// Animates to state where it shows "play" button.
  void _play() {
    _controller.forward();
  }

  /// Animates to state where it shows "pause" button.
  void _pause() {
    _controller.reverse();
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
      final theme = Theme.of(context);
    final baseAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final slideAnimation = Tween(
      begin: Offset.zero,
      end: const Offset(0.05, 0.0),
    ).animate(baseAnimation);
    final scaleAnimation = Tween(begin: 1.05, end: 0.89).animate(baseAnimation);
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final color = widget.iconColor ?? theme.iconTheme.color!;
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
            child: Lottie.asset(
              constants.Assets.assetAnimationPlayPause,
              controller: _controller,
              onLoaded: (composition) {
                _controller.duration = composition.duration;
                _update();
              },
              delegates: LottieDelegates(
                values: [
                  ValueDelegate.color(const ['Left Shape Layer', 'Left Shape', 'Left Shape Fill'], value: color),
                  ValueDelegate.color(const ['Right Shape Layer', 'Right Shape', 'Right Shape Fill'], value: color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
