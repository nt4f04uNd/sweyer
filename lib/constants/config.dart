/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';

abstract class Config {
  static const String APPLICATION_TITLE = 'Sweyer';
  static const String GITHUB_REPO_URL = 'https://github.com/nt4f04uNd/sweyer';
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('ru', 'RU'),
  ];
  static const int SEARCH_HISTORY_LENGTH = 30;
}
