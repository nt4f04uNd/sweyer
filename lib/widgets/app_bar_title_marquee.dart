import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class AppBarTitleMarquee extends StatelessWidget {
  const AppBarTitleMarquee({
    super.key,
    required this.text,
    this.fontSize,
  });

  final String text;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final style = appBarTitleTextStyle(context);
    return NFMarquee(
      text: text,
      fontSize: fontSize ?? style.fontSize!,
      textStyle: style,
    );
  }
}
