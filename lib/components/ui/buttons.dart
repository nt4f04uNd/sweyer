/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Button to go back from page
class SMMBackButton extends StatelessWidget {
  /// A custom icon for back button
  final IconData icon;

  /// Custom button size
  final double size;
  const SMMBackButton({Key key, this.icon, this.size = kSMMIconButtonSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SMMIconButton(
      icon: Icon(
        icon ?? Icons.arrow_back,
        color: Theme.of(context).iconTheme.color,
      ),
      size: size,
      splashColor: Constants.AppTheme.splash.auto(context),
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

/// Creates [Raised] with border radius, by default colored into main app color - `Colors.deepPurple`
class PrimaryRaisedButton extends RaisedButton {
  PrimaryRaisedButton(
      {Key key,
      @required Function onPressed,

      /// Text to show inside button
      @required String text,

      /// Loading shows loading inside button
      bool loading = false,

      /// Style applied to text
      TextStyle textStyle = const TextStyle(color: Colors.white),
      Color color = Colors.deepPurple,
      double borderRadius = 15.0})
      : super(
          key: key,
          child: loading
              ? SizedBox(
                  width: 25.0,
                  height: 25.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:const AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(text, style: textStyle),
          color: color,
          onPressed: onPressed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
}

/// Creates [FlatButton] with border radius, perfect for [showDialog]s accept and decline buttons
class DialogFlatButton extends FlatButton {
  DialogFlatButton(
      {Key key,
      @required Widget child,
      @required Function onPressed,
      Color textColor,
      double borderRadius = 5.0})
      : super(
          key: key,
          child: child,
          onPressed: onPressed,
          textColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(borderRadius),
            ),
          ),
        );
}

/// Button to switch loop mode
class LoopButton extends StatelessWidget {
  const LoopButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: MusicPlayer.onLoopSwitch,
        initialData: MusicPlayer.loopMode,
        builder: (context, snapshot) {
          return SMMIconButton(
            splashColor: Constants.AppTheme.splash.auto(context),
            icon: Icon(Icons.loop),
            size: 40.0,
            color: snapshot.data
                ? Constants.AppTheme.mainContrast.auto(context)
                : Constants.AppTheme.disabledIcon.auto(context),
            onPressed: MusicPlayer.switchLoopMode,
          );
        });
  }
}

class ShuffleButton extends StatefulWidget {
  ShuffleButton({Key key}) : super(key: key);

  @override
  _ShuffleButtonState createState() => _ShuffleButtonState();
}

class _ShuffleButtonState extends State<ShuffleButton> {
  @override
  Widget build(BuildContext context) {
    return SMMIconButton(
      splashColor: Constants.AppTheme.splash.auto(context),
      icon: Icon(Icons.shuffle),
      color: PlaylistControl.playlistType == PlaylistType.shuffled
          ? Constants.AppTheme.mainContrast.auto(context)
          : Constants.AppTheme.disabledIcon.auto(context),
      onPressed: () {
        setState(() {
          if (PlaylistControl.playlistType == PlaylistType.shuffled)
            PlaylistControl.returnFromShuffledPlaylist();
          else
            PlaylistControl.setShuffledPlaylist();
        });
      },
    );
  }
}
