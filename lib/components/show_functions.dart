import 'package:app/components/buttons.dart';
import 'package:app/components/custom_search.dart';
import 'package:app/components/search.dart';
import 'package:app/constants/themes.dart';
import 'package:app/logic/player/playlist.dart';
import 'package:app/logic/player/song.dart';
import 'package:fluttertoast/fluttertoast.dart';

// This is a workaround to rename show functions
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart' hide showDialog;
const flutterShowDialog = material.showDialog;

/// Class that contains 'show' functions, like `showDialog` and others
abstract class ShowFunctions {
  /// Shows toast from `Fluttertoast` with already set `backgroundColor` to `Color.fromRGBO(18, 18, 18, 1)`
  static Future<bool> showToast({
    @required String msg,
    Toast toastLength,
    int timeInSecForIos = 1,
    double fontSize = 16.0,
    ToastGravity gravity,
    Color textColor,
    Color backgroundColor,
  }) async {
    backgroundColor ??= Color.fromRGBO(18, 18, 18, 1);

    return await Fluttertoast.showToast(
        msg: msg,
        toastLength: toastLength,
        timeInSecForIos: timeInSecForIos,
        fontSize: fontSize,
        gravity: gravity,
        textColor: textColor,
        backgroundColor: backgroundColor);
  }

  /// Function that calls `showCustomSearch` and opens `SongsSearchDelegate` to search songs
  static Future<void> showSongsSearch(BuildContext context) async {
    await showCustomSearch<Song>(
      context: context,
      delegate: SongsSearchDelegate(),
    );
  }

  /// Function that handles click in bottom modal and sorts tracks
  static void _handleSortClick(BuildContext context, SortFeature feature) {
    PlaylistControl.sortSongs(feature);
    Navigator.pop(context);
  }

  /// Function that calls `showModalBottomSheet` and allows user to sort songs
  static void showSongsSortModal(BuildContext context) {
    // TODO: add indicator for a current sort feature
    showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppTheme.modal.auto(context),
        builder: (BuildContext context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 15, left: 12),
                  child: Text("Сортировать",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.caption.color,
                      ))),
              ListTile(
                title: Text("По названию"),
                onTap: () => _handleSortClick(context, SortFeature.title),
              ),
              ListTile(
                title: Text("По дате"),
                onTap: () => _handleSortClick(context, SortFeature.date),
              )
            ],
          );
        });
  }

  /// Calls `showDialog` function from flutter material library
  static Future<dynamic> showDialog(
    BuildContext context, {
    Widget title: const Text("Диалог"),
    Widget content: const Text("Контент"),
    DialogFlatButton acceptButton,
    DialogFlatButton declineButton,
  }) async {
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

    return await flutterShowDialog(
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
