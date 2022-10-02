import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as constants;
import 'package:sweyer/sweyer.dart';

ThemeData get staticTheme => Theme.of(staticContext);

extension ThemeX on ThemeData {
  constants.AppTheme get appThemeExtension => extension<constants.AppTheme>()!;
  constants.PlayerRouteTheme get playerRouteThemeExtension => extension<constants.PlayerRouteTheme>()!;
}
