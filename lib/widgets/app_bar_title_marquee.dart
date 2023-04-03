import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class AppBarTitleMarquee extends StatelessWidget {
  const AppBarTitleMarquee({
    Key? key,
    required this.text,
    this.fontSize,
  }) : super(key: key);

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
