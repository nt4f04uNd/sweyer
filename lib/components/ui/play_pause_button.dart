/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

const double _kIconSize = 32;
const double _kButtonSize = 66;

class AnimatedPlayPauseButton extends StatefulWidget {
  AnimatedPlayPauseButton({Key key, this.iconSize, this.size, this.iconColor})
      : super(key: key);

  final double iconSize;
  final double size;
  final Color iconColor;

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
        AnimationController(vsync: this, duration:const Duration(milliseconds: 300));

    if (MusicPlayer.playerState == AudioPlayerState.PLAYING) {
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


  @override
  void dispose() {
    _animationController.dispose();
    _playerChangeSubscription.cancel();
    super.dispose();
  }

  void _handlePress() async {
    await MusicPlayer.playPause();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SMMIconButton(
        size: widget.size ?? _kButtonSize,
        iconSize: widget.iconSize ?? _kIconSize,
        onPressed: _handlePress,
        icon: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          color: widget.iconColor?? Constants.AppTheme.playPauseIcon.auto(context),
          progress: _animationController,
        ),
      ),
    );
  }
}
