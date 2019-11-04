import 'package:flutter/material.dart';

/// Creates `Raised` with border radius, by default colored into main app color - `Colors.deepPurple`
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
                    valueColor: AlwaysStoppedAnimation(Colors.white),
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

/// Creates `FlatButton` with border radius, perfect for `showDialog`s accept and decline buttons
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
