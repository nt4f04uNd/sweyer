import 'package:flutter/widgets.dart';

/// Calculate the height of one line of text rendered with the [style] and [textScaler].
double calculateLineHeight(TextStyle? style, TextScaler textScaler) {
  return TextPainter(
    text: TextSpan(text: '', style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  ).preferredLineHeight;
}
