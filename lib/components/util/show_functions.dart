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
        backgroundColor: Theme.of(context).colorScheme.background,
        builder: (BuildContext context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.only(top: 15, bottom: 15, left: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  "Сортировать — ${sortFeature == SortFeature.title ? "по названию" : "по дате"}",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.caption.color,
                  ),
                ),
              ),
              SMMListTile(
                title: Text("По названию"),
                onTap: () => _handleSortClick(context, SortFeature.title),
              ),
              SMMListTile(
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
    @required Widget content,
    EdgeInsets titlePadding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 6.0),
    EdgeInsets contentPadding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 10.0),
    Widget acceptButton,
    List<Widget> additionalActions,
  }) async {
    assert(title != null);
    assert(content != null);

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
    @required Widget title,
    @required Widget content,
    EdgeInsets titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
    EdgeInsets contentPadding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 10.0),
    DialogRaisedButton acceptButton,
    DialogRaisedButton declineButton,
    bool hideDeclineButton = false,
    List<Widget> additionalActions,
  }) async {
    assert(title != null);
    assert(content != null);

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
        final scaleAnimation = Tween(begin: 0.98, end: 1.0).animate(
          CurvedAnimation(
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
            parent: animation,
          ),
        );

        final fadeAnimation = CurvedAnimation(
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
          parent: animation,
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
            title: Container(
              padding: titlePadding,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: title,
            ),
            titlePadding: EdgeInsets.zero,
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
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5.0, vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: additionalActions == null
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        if (additionalActions != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: ButtonBar(
                              buttonPadding: EdgeInsets.zero,
                              alignment: MainAxisAlignment.start,
                              children: additionalActions,
                            ),
                          ),
                        ButtonBar(
                          buttonPadding: EdgeInsets.zero,
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
                ),
              ],
            ),
            contentPadding: EdgeInsets.zero,
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

  /// Will show up a snack bar notification that something's went wrong
  ///
  /// From that snack bar will be possible to proceed to special alert to see the error details with the ability to copy them.
  /// [errorDetails] string to show in the alert
  static void showError(BuildContext context, {@required String errorDetails}) {
    GlobalKey<SMMSnackBarWrapperState> globalKey = GlobalKey();

    SnackBarControl.showSnackBar(
      SMMSnackbarSettings(
        globalKey: globalKey,
        child: SMMSnackBar(
          message: "😮 Упс! Произошла ошибка",
          color: Theme.of(context).colorScheme.error,
          action: PrimaryRaisedButton(
            text: "Детали",
            color: Colors.white,
            textStyle: const TextStyle(color: Colors.black),
            onPressed: () {
              globalKey.currentState.close();

              ShowFunctions.showAlert(
                context,
                title: Text(
                  "Информация об ошибке",
                  textAlign: TextAlign.center,
                ),
                titlePadding:
                    const EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0, bottom: 6.0),
                contentPadding: const EdgeInsets.only(
                    top: 7.0, left: 2.0, right: 2.0, bottom: 10.0),
                content: SelectableText(
                  errorDetails,
                  style: const TextStyle(fontSize: 11.0),
                ),
                additionalActions: [
                  CopyButton(text: errorDetails),
                  InfoButton(
                    info:
                        "Потому что я криворукий черт, в приложении произошла ошибка. Ее тип и стактрейс отображаются в предыдущем окне. Эти данные будут автоматически отправлены на сервер Google, и я их увижу. Чтобы я мог лучше разобраться в проблеме, пожалуйста, сообщите мне о том, при каких условиях это случилось, какие действия вы совершали перед этим, или просто ваше предположение о том, что могло вызвать ее.",
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
