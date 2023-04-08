import 'package:flutter/widgets.dart';

/// Calculate the height of one line of text rendered with the [style] and [textScaleFactor].
double calculateLineHeight(TextStyle? style, double textScaleFactor) {
  return TextPainter(
    text: TextSpan(text: '', style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
    textScaleFactor: textScaleFactor,
  ).preferredLineHeight;
}
