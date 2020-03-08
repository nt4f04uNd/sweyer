/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

// This is a workaround to rename show functions
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart' hide showDialog;
import 'package:fluttertoast/fluttertoast.dart';

const flutterShowDialog = material.showDialog;

/// Class that contains composed 'show' functions, like [showDialog] and others
abstract class ShowFunctions {
  /// Shows toast from [Fluttertoast] with already set [backgroundColor] to `Color.fromRGBO(18, 18, 18, 1)`
  static Future<bool> showToast({
    @required String msg,
    Toast toastLength,
    int timeInSecForIos = 1,
    double fontSize = 14.0,
    ToastGravity gravity,
    Color textColor,
    Color backgroundColor,
  }) async {
    backgroundColor ??= Color.fromRGBO(18, 18, 18, 1);

    return Fluttertoast.showToast(
      msg: msg,
      toastLength: toastLength,
      timeInSecForIos: timeInSecForIos,
      fontSize: fontSize,
      gravity: gravity,
      textColor: textColor,
      backgroundColor: backgroundColor,
    );
  }

  /// Function that calls [showCustomSearch] and opens [SongsSearchDelegate] to search songs
  static Future<void> showSongsSearch(BuildContext context) async {
    await showCustomSearch(
      context: context,
      delegate: SongsSearchDelegate(),
    );
  }

  /// Function that handles click in bottom modal and sorts tracks
  static void _handleSortClick(BuildContext context, SortFeature feature) {
    PlaylistControl.sortSongs(feature: feature);
    Navigator.pop(context);
  }

  /// Function that calls [showModalBottomSheet] and allows user to sort songs
  static void showSongsSortModal(BuildContext context) {
    var sortFeature = PlaylistControl.sortFeature;
    showModalBottomSheet<void>(
        context: context,
        backgroundColor: Constants.AppTheme.main.auto(context),
        builder: (BuildContext context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 15, left: 12),
                child: Text(
                  "Сортировать — ${sortFeature == SortFeature.title ? "по названию" : "по дате"}",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.caption.color,
                  ),
                ),
              ),
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

  /// Calls [showDialog] function from flutter material library to show a message to user (only accept button)
  static Future<dynamic> showAlert(
    BuildContext context, {
    Widget title: const Text("Предупреждение"),
    Widget content: const Text("Контент"),
    DialogFlatButton acceptButton,
  }) async {
    acceptButton ??= DialogFlatButton(
      child: Text('Принять'),
      textColor: Constants.AppTheme.acceptButton.auto(context),
      onPressed: () => Navigator.of(context).pop(),
    );
    return await flutterShowDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: title,
        content: content,
        contentPadding:
            const EdgeInsets.only(top: 7.0, left: 27.0, right: 27.0),
        contentTextStyle: Theme.of(context).textTheme.subtitle1.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        actions: <Widget>[
          ButtonBar(
            children: <Widget>[
              acceptButton,
            ],
          ),
        ],
      ),
    );
  }

  /// Calls [showDialog] function from flutter material library to show a dialog to user (accept and decline buttons)
  static Future<dynamic> showDialog(
    BuildContext context, {
    Widget title: const Text("Диалог"),
    Widget content: const Text("Контент"),
    DialogFlatButton acceptButton,
    DialogFlatButton declineButton,
  }) async {
    acceptButton ??= DialogFlatButton(
      child: Text('Принять'),
      textColor: Constants.AppTheme.acceptButton.auto(context),
      onPressed: () => Navigator.of(context).pop(),
    );
    declineButton ??= DialogFlatButton(
      child: Text('Отмена'),
      textColor: Constants.AppTheme.declineButton.auto(context),
      onPressed: () => Navigator.of(context).pop(),
    );

    return await flutterShowDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: title,
        content: content,
        contentPadding:
            const EdgeInsets.only(top: 7.0, left: 27.0, right: 27.0),
        contentTextStyle: Theme.of(context).textTheme.subtitle1.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
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
      ),
    );
  }
}
