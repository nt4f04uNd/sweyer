/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Button to switch loop mode
class LoopButton extends StatelessWidget {
  const LoopButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return StreamBuilder<bool>(
      stream: MusicPlayer.onLoopSwitch,
      initialData: MusicPlayer.looping,
      builder: (context, snapshot) {
        return AnimatedIconButton(
          icon: Icon(Icons.loop_rounded),
          size: 40.0,
          iconSize: textScaleFactor * Constants.iconSize,
          active: snapshot.data,
          onPressed: MusicPlayer.switchLooping,
        );
      },
    );
  }
}

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return StreamBuilder(
      stream: ContentControl.state.onSongListChange,
      builder: (context, snap) => AnimatedIconButton(
        icon: Icon(Icons.shuffle_rounded),
        color: ThemeControl.theme.colorScheme.onSurface,
        size: 40.0,
        iconSize: textScaleFactor * Constants.iconSize,
        active: ContentControl.state.queues.shuffled,
        onPressed: () {
          ContentControl.setQueue(
            shuffled: !ContentControl.state.queues.shuffled,
          );
        },
      ),
    );
  }
}

/// Icon button that opens settings page.
class SettingsButton extends StatelessWidget {
  const SettingsButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NFIconButton(
      icon: Icon(Icons.settings_rounded),
      onPressed: () => AppRouter.instance.goto(AppRoutes.settings),
    );
  }
}
