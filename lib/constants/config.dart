import 'package:flutter/material.dart';

abstract class Config {
  static const String APPLICATION_TITLE = 'Sweyer';
  static const String GITHUB_REPO_URL = 'https://github.com/nt4f04uNd/sweyer';
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('ru', 'RU'),
    Locale('de', 'DE'),
  ];
  static const int SEARCH_HISTORY_LENGTH = 30;

  /// The amount of time within a second back press will close the app after the first back press.
  static const BACK_PRESS_CLOSE_TIMEOUT = Duration(seconds: 2);
}
