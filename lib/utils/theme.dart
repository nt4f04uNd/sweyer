import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as constants;
import 'package:sweyer/sweyer.dart';

ThemeData get staticTheme => ThemeControl.instance.theme;

extension ThemeX on ThemeData {
  constants.AppTheme get appThemeExtension => extension<constants.AppTheme>()!;
  constants.SystemUiTheme get systemUiThemeExtension => extension<constants.SystemUiTheme>()!;
}
