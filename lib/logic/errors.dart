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
    final errorDetails = '''${report.error.toString()}
                      
${report.stackTrace.toString()}''';

    ShowFunctions.showError(context, errorDetails: errorDetails);

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
    try {
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
