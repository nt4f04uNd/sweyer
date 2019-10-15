import 'dart:async';
import 'package:app/player/player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AnimatedPlayPauseButton extends StatefulWidget {
  AnimatedPlayPauseButton({Key key}) : super(key: key);

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
    await MusicPlayer.clickPausePlay();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: IconButton(
        padding: const EdgeInsets.all(0.0),
        icon: Center(
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            size: 32,
            color: Colors.white,
            progress: _animationController,
          ),
        ),
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
