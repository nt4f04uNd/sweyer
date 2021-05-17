/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Button to switch loop mode
class LoopButton extends StatelessWidget {
  const LoopButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final player = MusicPlayer.instance;
    return StreamBuilder<bool>(
      stream: player.loopingStream,
      initialData: player.looping,
      builder: (context, snapshot) {
        return AnimatedIconButton(
          icon: const Icon(Icons.loop_rounded),
          size: 40.0,
          iconSize: textScaleFactor * NFConstants.iconSize,
          active: snapshot.data!,
          onPressed: player.switchLooping,
        );
      },
    );
  }
}

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return StreamBuilder(
      stream: ContentControl.state.onContentChange,
      builder: (context, snap) => AnimatedIconButton(
        icon: const Icon(Icons.shuffle_rounded),
        color: ThemeControl.theme.colorScheme.onSurface,
        size: 40.0,
        iconSize: textScaleFactor * NFConstants.iconSize,
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
  const SettingsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NFIconButton(
      icon: const Icon(Icons.settings_rounded),
      onPressed: () => AppRouter.instance.goto(AppRoutes.settings),
    );
  }
}


/// A button with text and icon, used to start queue playback.
/// 
/// Used in:
///  * [PlayQueueButton]
///  * [ShuffleQueueButton]
class _QueuePlayButton extends StatelessWidget {
  const _QueuePlayButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.color,
    this.textColor,
    this.splashColor,
  }) : super(key: key);

  final String text;
  final Icon icon;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final Color? splashColor;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeControl.theme.copyWith(
        splashFactory: NFListTileInkRipple.splashFactory,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: const ElevatedButton(child: null, onPressed: null).defaultStyleOf(context).copyWith(
          backgroundColor: MaterialStateProperty.all(color),
          foregroundColor: MaterialStateProperty.all(textColor),
          overlayColor: MaterialStateProperty.resolveWith((_) => splashColor ?? Constants.Theme.glowSplashColor.auto),
          splashFactory: NFListTileInkRipple.splashFactory,
          shadowColor: MaterialStateProperty.all(Colors.transparent),
          textStyle: MaterialStateProperty.resolveWith((_) => TextStyle(
            fontFamily: ThemeControl.theme.textTheme.headline1!.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15.0,
          )),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 6.0),
            Padding(
              padding: const EdgeInsets.only(bottom: 1.0),
              child: Text(text),
            ),
            const SizedBox(width: 8.0),
          ],
        ),
      ),
    );
  }
}

/// Used start queue playback.
class PlayQueueButton extends StatelessWidget {
  const PlayQueueButton({Key? key, required this.onPressed}) : super(key: key);

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return _QueuePlayButton(
      text: l10n.playContentList,
      icon: const Icon(Icons.play_arrow_rounded, size: 28.0),
      onPressed: onPressed,
    );
  }
}

/// Used start shuffled queue playback.
class ShuffleQueueButton extends StatelessWidget {
  const ShuffleQueueButton({Key? key, required this.onPressed}) : super(key: key);

    final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return _QueuePlayButton(
      text: l10n.shuffleContentList,
      icon: const Icon(Icons.shuffle_rounded, size: 22.0),
      color: Constants.Theme.contrast.auto,
      textColor: ThemeControl.theme.colorScheme.background,
      splashColor: Constants.Theme.glowSplashColorOnContrast.auto,
      onPressed: onPressed,
    );
  }
}