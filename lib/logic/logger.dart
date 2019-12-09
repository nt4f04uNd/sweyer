/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter_mailer/flutter_mailer.dart';

/// Class to create and send log to me
abstract class Logger {
  /// A list to save separate log strings and then unite them into one final log
  static List<String> _stringList = [];

  /// Max length of string list (max count of strings in log)
  static int _maxStrings = 100;

  /// Adds string to `_stringList`
  ///
  /// @param prefix — log prefix
  ///
  /// @param message — log message body
  static void log(String prefix, String message) {
    final now = DateTime.now();
    var minutes = now.minute.toString();
    var seconds = now.second.toString();
    var milliseconds = now.millisecond.toString();
    if (minutes.length < 2) minutes = "0" + minutes;
    if (seconds.length < 2) seconds = "0" + seconds;
    if (milliseconds.length < 3) {
      if (milliseconds.length < 2)
        milliseconds = "00" + milliseconds;
      else
        milliseconds = "0" + milliseconds;
    }
    String str = prefix.padRight(40) +
        "${now.hour.toString()}:$minutes:$seconds:$milliseconds".padRight(35) +
        message;

    _stringList.add(str);

    if (_stringList.length > _maxStrings) _stringList.removeAt(0);
  }

  /// Sends email with log to me
  static Future<void> send() async {
    final MailOptions mailOptions = MailOptions(
      recipients: <String>["nt4f04und@gmail.com"],
      subject: "flutter_music_player log",
      body: _stringList.join("\n"),
      isHTML: false,
    );

    try {
      await FlutterMailer.send(mailOptions);
    } catch (err) {
      throw "Error occured sending log $err";
    }
  }
}
