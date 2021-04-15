/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart'
    hide showBottomSheet, showGeneralDialog, showModalBottomSheet;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Class that contains composed 'show' functions, like [showDialog] and others
class ShowFunctions extends NFShowFunctions {
  /// Empty constructor will allow enheritance.
  ShowFunctions();
  ShowFunctions._();
  static final instance = ShowFunctions._();

  /// Shows toast from [Fluttertoast] with already set [backgroundColor] to `Color.fromRGBO(18, 18, 18, 1)`
  Future<bool> showToast({
    @required String msg,
    Toast toastLength,
    double fontSize = 14.0,
    ToastGravity gravity,
    Color textColor,
    Color backgroundColor,
  }) async {
    backgroundColor ??= ThemeControl.theme.colorScheme.primary;

    return Fluttertoast.showToast(
      msg: msg,
      toastLength: toastLength,
      fontSize: fontSize,
      gravity: gravity,
      textColor: textColor,
      backgroundColor: backgroundColor,
      timeInSecForIosWeb: 20000,
    );
  }

  /// Opens songs search
  void showSongsSearch({
    String query = '',
    bool openKeyboard = true,
  }) {
    HomeRouter.instance.goto(HomeRoutes.factory.search(SearchArguments(
      query: query,
      openKeyboard: openKeyboard,
    )));
  }

  /// Will show up a snack bar notification that something's went wrong
  ///
  /// From that snack bar will be possible to proceed to special alert to see the error details with the ability to copy them.
  /// [errorDetails] string to show in the alert
  void showError({ @required String errorDetails }) {
    final context = AppRouter.instance.navigatorKey.currentContext;
    assert(context != null);
    final l10n = getl10n(context);
    final theme = ThemeControl.theme;
    final globalKey = GlobalKey<NFSnackbarEntryState>();
    NFSnackbarController.showSnackbar(
      NFSnackbarEntry(
        globalKey: globalKey,
        child: NFSnackbar(
          title: Text(
            '😮 ' + l10n.errorMessage,
            style: TextStyle(
              fontSize: 15.0,
              color: theme.colorScheme.onError,
            ),
          ),
          color: theme.colorScheme.error,
          trailing: NFButton(
            variant: NFButtonVariant.raised,
            text: l10n.details,
            color: Colors.white,
            textStyle: const TextStyle(color: Colors.black),
            onPressed: () {
              globalKey.currentState.close();
              showAlert(
                context,
                title: Text(
                  l10n.errorDetails,
                  textAlign: TextAlign.center,
                ),
                titlePadding: defaultAlertTitlePadding.copyWith(
                  left: 12.0,
                  right: 12.0,
                ),
                contentPadding: const EdgeInsets.only(
                  top: 16.0,
                  left: 2.0,
                  right: 2.0,
                  bottom: 10.0,
                ),
                content: SelectableText(
                  errorDetails,
                  // FIXME: temporarily do not apply AlwaysScrollableScrollPhysics, because of this issue https://github.com/flutter/flutter/issues/71342
                  // scrollPhysics: AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                  style: const TextStyle(fontSize: 11.0),
                ),
                additionalActions: [
                  NFCopyButton(text: errorDetails),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
