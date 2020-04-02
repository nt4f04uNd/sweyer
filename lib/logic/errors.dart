/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:catcher/catcher_plugin.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';
import 'package:catcher/mode/dialog_report_mode.dart';
import 'package:catcher/model/report.dart';
import 'package:flutter/material.dart';

/// My implementation of [DialogReportMode].
/// Though it doesn't show any dialog,
/// it shows snackbar instead, and automatically accepts the report
class SnackBarReportMode extends DialogReportMode {
  @override
  void requestAction(Report report, BuildContext context) {
    GlobalKey<SMMSnackBarWrapperState> globalKey = GlobalKey();

// TODO: refactor this!!!
    SnackBarControl.showSnackBar(
      context,
      settings: SMMSnackbarSettings(
        globalKey: globalKey,
        duration: const Duration(seconds: 4),
        child: SMMSnackBar(
          title: Text("😮 Упс! Произошла ошибка"),
          action: PrimaryRaisedButton(
            text: "Детали",
            color: Theme.of(context).colorScheme.error,
            onPressed: () {
              globalKey.currentState.close();

              final errorInfo = '''${report.error.toString()}
                      
${report.stackTrace.toString()}''';

              ShowFunctions.showAlert(
                context,
                title: Text(
                  "Информация об ошибке",
                  textAlign: TextAlign.center,
                ),
                titlePadding:
                    const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0),
                contentPadding:
                    const EdgeInsets.only(top: 7.0, left: 2.0, right: 2.0),
                content: SingleChildScrollView(
                  child: SelectableText(
                    errorInfo,
                    style: const TextStyle(fontSize: 11.0),
                  ),
                ),
                acceptButton: DialogFlatButton(
                  child: Text("Закрыть"),
                  onPressed: () => App.navigatorKey.currentState.pop(),
                ),
                additionalActions: [
                  SMMIconButton(
                    icon: Icon(Icons.content_copy),
                    size: 44.0,
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: errorInfo),
                      );
                      SnackBarControl.showSnackBar(
                        context,
                        settings: SMMSnackbarSettings(
                          globalKey: globalKey,
                          duration: const Duration(seconds: 4),
                          child: SMMSnackBar(
                            title: Text("Скопировано"),
                            leading: Icon(Icons.content_copy),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    _acceptReport(context, report);
  }

  _acceptReport(BuildContext context, Report report) {
    super.onActionConfirmed(report);
  }

  _cancelReport(BuildContext context, Report report) {
    super.onActionRejected(report);
  }
}

class FirebaseReportHandler extends ReportHandler {
  @override
  Future<bool> handle(Report error) async {
    bool res = true;
    try { // TODO: uncomment this
      Crashlytics.instance.recordFlutterError(
        FlutterErrorDetails(
          exception: error.error,
          stack: error.stackTrace,
        ),
      );
    } catch (e) {
      res = false;
      print("ERROR IN FIREBASE REPORT HANDLER: " + e);
    }
    return res;
  }
}
