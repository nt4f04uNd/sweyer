import 'package:flutter/material.dart';

/// Returns app style used for app bar title.
TextStyle appBarTitleTextStyle(BuildContext context) {
  final theme = Theme.of(context);
  return TextStyle(
    fontWeight: FontWeight.w700,
    color: theme.textTheme.titleLarge!.color,
    fontSize: 22.0,
    fontFamily: 'Roboto',
  );
}
