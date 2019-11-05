import 'package:app/components/buttons.dart';
import 'package:app/components/show_functions.dart';
import 'package:catcher/mode/dialog_report_mode.dart';
import 'package:catcher/model/report.dart';
import 'package:flutter/material.dart';

/// My implementation of `ReportMode`, acts like `DialogReportMode`,
/// but applies other dialog appearance
class CustomDialogReportMode extends DialogReportMode {
  @override
  void requestAction(Report report, BuildContext context) {
    _showDialog(report, context);
  }

  _showDialog(Report report, BuildContext context) async {
    await Future.delayed(Duration.zero);
    ShowFunctions.showDialog(
      context,
      title: Text("Упс 😮"),
      content: Text(
          "Кажется, в приложении произошла ошибка. Пожалуйста, сообщите нам об этом, отправив письмо на почту разработчику"),
      acceptButton: DialogFlatButton(
        child: Text("Принять"),
        onPressed: () => _acceptReport(context, report),
      ),
      declineButton: DialogFlatButton(
        child: Text("Отклонить"),
        onPressed: () => _cancelReport(context, report),
      ),
    );
  }

  _acceptReport(BuildContext context, Report report) {
    super.onActionConfirmed(report);
    Navigator.pop(context);
  }

  _cancelReport(BuildContext context, Report report) {
    super.onActionRejected(report);
    Navigator.pop(context);
  }
}