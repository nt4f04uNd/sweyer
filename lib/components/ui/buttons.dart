/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Creates [Raised] with border radius, by default colored into main app color
class PrimaryRaisedButton extends StatelessWidget {
  const PrimaryRaisedButton({
    Key key,
    @required this.text,
    @required this.onPressed,
    this.loading = false,
    this.textStyle,
    this.materialTapTargetSize = MaterialTapTargetSize.shrinkWrap,
    this.color,
    this.borderRadius = 15.0,
    this.padding,
  });

  /// Text to show inside button
  final String text;
  final Function onPressed;

  /// Loading shows loading inside button
  final bool loading;

  /// Style applied to text
  final TextStyle textStyle;

  /// Specifies whether the button will have margins or not
  final MaterialTapTargetSize materialTapTargetSize;
  final Color color;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: ListTileInkRipple.splashFactory,
      ),
      child: RaisedButton(
        key: key,
        splashColor: Colors.black.withOpacity(0.18),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: loading
              ? SizedBox(
                  width: 25.0,
                  height: 25.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: textStyle ??
                      TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
        ),
        color: color ?? Theme.of(context).colorScheme.primary,
        onPressed: loading ? null : onPressed,
        materialTapTargetSize: materialTapTargetSize,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
      ),
    );
  }
}

class DialogRaisedButton extends StatelessWidget {
  const DialogRaisedButton({
    Key key,
    this.text = "Закрыть",
    this.textStyle,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 15.0),
    this.borderRadius = 15.0,
    this.onPressed,
  }) : super(key: key);

  /// Text to show inside button
  final String text;
  final TextStyle textStyle;
  final Color color;
  final EdgeInsets padding;
  final double borderRadius;

  /// The returned value will be passed to [Navigator.maybePop()] method call
  final Function onPressed;

  /// Constructs an accept button.
  ///
  /// `true` will be always passed to [Navigator.maybePop()] call.
  factory DialogRaisedButton.accept(
      {String text = "Принять", Function onPressed}) {
    return DialogRaisedButton(
      text: text,
      onPressed: () {
        if (onPressed != null) {
          onPressed();
        }
        return true;
      },
    );
  }

  /// Constructs a decline button.
  ///
  /// `false` will be always passed to [Navigator.maybePop()] call.
  factory DialogRaisedButton.decline(
      {String text = "Отмена", Function onPressed}) {
    return DialogRaisedButton(
      text: text,
      color: Constants.AppColors.whiteDarkened,
      textStyle: TextStyle(color: Colors.black),
      onPressed: () {
        if (onPressed != null) {
          onPressed();
        }
        return false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: ListTileInkRipple.splashFactory,
      ),
      child: RaisedButton(
        splashColor: Colors.black.withOpacity(0.18),
        child: Text(
          text,
          style: textStyle ??
              TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        color: color ?? Theme.of(context).colorScheme.primary,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        onPressed: () async {
          var res;
          if (onPressed != null) {
            res = await onPressed();
          }
          App.navigatorKey.currentState.maybePop(res);
        },
      ),
    );
  }
}

/// Creates [FlatButton] with border radius, perfect for [showDialog]s accept and decline buttons
class DialogFlatButton extends StatelessWidget {
  DialogFlatButton({
    Key key,
    @required this.child,
    @required this.onPressed,
    this.textColor,
    this.borderRadius = 5.0,
  });

  final Widget child;
  final Function onPressed;
  final Color textColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return FlatButton(
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
}

/// Button to go back from page
class SMMBackButton extends StatelessWidget {
  const SMMBackButton({
    Key key,
    this.icon,
    this.size = kSMMIconButtonSize,
    this.onPressed,
  }) : super(key: key);

  /// A custom icon for back button
  final IconData icon;

  /// Custom button size
  final double size;

  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return SMMIconButton(
      icon: Icon(
        icon ?? Icons.arrow_back,
        color: Theme.of(context).iconTheme.color,
      ),
      size: size,
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }
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
          icon: Icon(Icons.loop),
          size: 40.0,
          color: snapshot.data
              ? Constants.AppTheme.mainContrast.auto(context)
              : Constants.AppTheme.disabledIcon.auto(context),
          onPressed: MusicPlayer.switchLoopMode,
        );
      },
    );
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
      icon: Icon(Icons.shuffle),
      color: ContentControl.state.currentPlaylistType == PlaylistType.shuffled
          ? Constants.AppTheme.mainContrast.auto(context)
          : Constants.AppTheme.disabledIcon.auto(context),
      onPressed: () {
        setState(() {
          if (ContentControl.state.currentPlaylistType == PlaylistType.shuffled)
            ContentControl.backFromShuffledPlaylist();
          else
            ContentControl.setShuffledPlaylist();
        });
      },
    );
  }
}

class CopyButton extends StatelessWidget {
  const CopyButton({
    Key key,
    this.size = 44.0,
    @required this.text,
  }) : super(key: key);

  final double size;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SMMIconButton(
      icon: const Icon(Icons.content_copy),
      size: size,
      onPressed: text == null
          ? null
          : () {
              Clipboard.setData(
                ClipboardData(text: text),
              );
              SnackBarControl.showSnackBar(
                SMMSnackbarSettings(
                  child: SMMSnackBar(
                    message: "Скопировано",
                    messagePadding: const EdgeInsets.only(left: 8.0),
                    leading: Icon(Icons.content_copy,
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
              );
            },
    );
  }
}

/// An information button.
/// On click creates an alert with information
class InfoButton extends StatelessWidget {
  const InfoButton({
    Key key,
    this.size = 44.0,
    @required this.info,
    this.infoAlertTitle = "Что это значит?",
  }) : super(key: key);

  final double size;
  final String info;

  /// Text displayed as a title of an info window
  final String infoAlertTitle;

  @override
  Widget build(BuildContext context) {
    return SMMIconButton(
      icon: const Icon(Icons.info_outline),
      size: size,
      onPressed: info == null
          ? null
          : () {
              ShowFunctions.showAlert(
                context,
                title: Text(infoAlertTitle),
                content: Text(this.info),
              );
            },
    );
  }
}
