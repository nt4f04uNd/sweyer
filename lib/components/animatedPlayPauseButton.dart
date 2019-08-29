import 'dart:async';
import 'package:app/musicPlayer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AnimatedPlayPauseButton extends StatefulWidget {
  AnimatedPlayPauseButton({Key key}) : super(key: key);

  AnimatedPlayPauseButtonState createState() => AnimatedPlayPauseButtonState();
}

class AnimatedPlayPauseButtonState extends State<AnimatedPlayPauseButton>
    with SingleTickerProviderStateMixin {
  final _musicPlayer = MusicPlayer.getInstance;
  AnimationController _animationController;
  StreamSubscription<AudioPlayerState> _playerChangeSubscription;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    // TODO: bad approach, change this to _animationController.value = 1 or 0q
    if (_musicPlayer.playState == AudioPlayerState.PLAYING) {
      _animationController.value = 1;
    } else {
      _animationController.value = 0;
    }

    _playerChangeSubscription =
        _musicPlayer.onPlayerStateChanged.listen((event) {
      setState(() {
        if (event == AudioPlayerState.PLAYING) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    });
  }

  void _handlePress() {
    _musicPlayer.clickTrackTile(_musicPlayer.playingIndexState);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: IconButton(
        padding: EdgeInsets.all(0),
        icon: Center(
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            size: 40,
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
    super.dispose();
    _playerChangeSubscription.cancel();
    _animationController.dispose();
  }
}
