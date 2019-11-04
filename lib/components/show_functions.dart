// This is a workaround to rename show functions
import 'package:app/constants/themes.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart' hide showDialog;

const flutterShowDialog = material.showDialog;

/// Class that contains 'show' functions, like `showDialog` and others
abstract class ShowFunctions {
  static void showDialog(
    BuildContext context, {
    Widget title: const Text("Диалог"),
    Widget content: const Text("Контент"),
    DialogFlatButton acceptButton,
    DialogFlatButton declineButton,
  }) {
    acceptButton ??= DialogFlatButton(
      child: Text('Принять'),
      textColor: AppTheme.redFlatButton.auto(context),
      onPressed: () => Navigator.of(context).pop(),
    );
    declineButton ??= DialogFlatButton(
      child: Text('Отмена'),
      textColor: AppTheme.declineButton.auto(context),
      onPressed: () => Navigator.of(context).pop(),
    );

    flutterShowDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: title,
              content:
                  // AnnotatedRegion<
                  // SystemUiOverlayStyle>(
                  // value: AppSystemUIThemes.dialogScreen.auto(context),
                  // child:
                  content,
              // ),
              contentPadding:
                  EdgeInsets.only(top: 24.0, left: 27.0, right: 27.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              actions: <Widget>[
                ButtonBar(
                  children: <Widget>[
                    acceptButton,
                    declineButton,
                  ],
                ),
              ],
            ));
  }
}

/// Creates `FlatButton` with border radius
class DialogFlatButton extends FlatButton {
  DialogFlatButton(
      {@required Widget child,
      @required Function onPressed,
      Color textColor,
      double borderRadius: 5})
      : super(
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
