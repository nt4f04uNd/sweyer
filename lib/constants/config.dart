import 'package:flutter/material.dart';

abstract class Config {
  static const String applicationTitle = 'Sweyer';
  static const String githubRepoUrl = 'https://github.com/nt4f04uNd/sweyer';
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('ru', 'RU'),
    Locale('de', 'DE'),
    Locale('tr', 'TR'),
  ];
  static const int searchHistoryLength = 30;

  /// The amount of time within a second back press will close the app after the first back press.
  static const backPressCloseTimeout = Duration(seconds: 2);
}
