/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Class that contains composed 'show' functions, like [showDialog] and others
///
/// TODO: add code to prevent stacking alert dialogs
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
    ContentControl.sortSongs(feature: feature);
    Navigator.pop(context);
  }

  /// Function that calls [showModalBottomSheet] and allows user to sort songs
  static void showSongsSortModal(BuildContext context) {
    final sortFeature = ContentControl.state.currentSortFeature;
    showModalBottomSheet<void>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.secondary,
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

  /// Calls [showGeneralDialog] function from flutter material library to show a message to user (only accept button)
  static Future<dynamic> showAlert(
    BuildContext context, {
    Widget title: const Text("Предупреждение"),
    Widget content: const Text("Контент"),
    EdgeInsets titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
    EdgeInsets contentPadding:
        const EdgeInsets.only(top: 6.0, left: 24.0, right: 24.0),
    Widget acceptButton,
    List<Widget> additionalActions,
  }) async {
    acceptButton ??= DialogRaisedButton.accept(text: "Закрыть");

    return showDialog(
      context,
      title: title,
      content: content,
      titlePadding: titlePadding,
      contentPadding: contentPadding,
      acceptButton: acceptButton,
      additionalActions: additionalActions,
      hideDeclineButton: true,
    );
  }

  /// Calls [showGeneralDialog] function from flutter material library to show a dialog to user (accept and decline buttons)
  static Future<dynamic> showDialog(
    BuildContext context, {
    Widget title: const Text("Диалог"),
    Widget content: const Text("Контент"),
    EdgeInsets titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
    EdgeInsets contentPadding:
        const EdgeInsets.only(top: 6.0, left: 24.0, right: 24.0),
    DialogRaisedButton acceptButton,
    DialogRaisedButton declineButton,
    bool hideDeclineButton = false,
    List<Widget> additionalActions,
  }) async {
    acceptButton ??= DialogRaisedButton.accept();
    if (!hideDeclineButton) {
      declineButton ??= DialogRaisedButton.decline();
    }

    return showGeneralDialog(
      barrierColor: Colors.black54,
      transitionDuration: kSMMRouteTransitionDuration,
      barrierDismissible: true,
      barrierLabel: 'SMMAlertDialog',
      context: context,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
            parent: animation,
          ),
        );

        final fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
            parent: animation,
          ),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: AlertDialog(
            title: title,
            titlePadding: titlePadding,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                //  widget(child: content),
                Flexible(
                  child: Padding(
                    padding: contentPadding,
                    child: SMMScrollbar(
                      thickness: 5.0,
                      child: SingleChildScrollView(
                        child: content,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Row(
                    mainAxisAlignment: additionalActions == null
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      if (additionalActions != null)
                        ButtonBar(
                          alignment: MainAxisAlignment.start,
                          children: <Widget>[
                            ...?additionalActions,
                          ],
                        ),
                      ButtonBar(
                        mainAxisSize: MainAxisSize.min,
                        alignment: MainAxisAlignment.end,
                        children: <Widget>[
                          acceptButton,
                          if (!hideDeclineButton) declineButton
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.all(0.0),
            contentTextStyle: Theme.of(context).textTheme.subtitle1.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 15.0,
                ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }
}
