import 'dart:async';
import 'package:app/components/custom_icon_button.dart';
import 'package:app/player/player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:app/constants/themes.dart';

class AnimatedPlayPauseButton extends StatefulWidget {
  AnimatedPlayPauseButton({Key key, this.isLarge = false}) : super(key: key);

  /// Creates button of big size
  final bool isLarge;

  AnimatedPlayPauseButtonState createState() => AnimatedPlayPauseButtonState();
}

class AnimatedPlayPauseButtonState extends State<AnimatedPlayPauseButton>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  StreamSubscription<AudioPlayerState> _playerChangeSubscription;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    // TODO: bad approach, change this to _animationController.value = 1 or 0q
    if (MusicPlayer.playState == AudioPlayerState.PLAYING) {
      _animationController.value = 1;
    } else {
      _animationController.value = 0;
    }

    _playerChangeSubscription =
        MusicPlayer.onPlayerStateChanged.listen((event) {
      setState(() {
        if (event == AudioPlayerState.PLAYING) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    });
  }

  void _handlePress() async {
    await MusicPlayer.playPause();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.isLarge
          ? IconButton(
              icon: AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                size: 32,
                color: AppTheme.playPauseIcon.auto(context),
                progress: _animationController,
              ),
              onPressed: _handlePress,
            )
          : CustomIconButton(
              icon: AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                color: AppTheme.playPauseIcon.auto(context),
                progress: _animationController,
              ),
              iconSize: 32,
              size: 48,
              onPressed: _handlePress,
            ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _playerChangeSubscription.cancel();
    super.dispose();
  }
}
