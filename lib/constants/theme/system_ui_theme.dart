import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

import '../colors.dart';

part 'system_ui_theme.tailor.dart';

@tailor
class _$SystemUiTheme {
  /// Default theme for all screens.
  ///
  /// Theme where nav bar is [black] (with default dark theme).
  /// For light this means [white].
  ///
  /// The opposite is [grey].
  static final black = [
    /// [withOpacity] needed for smooth transition to [drawerScreen].
    SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.white.withOpacity(0.0),
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
    SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: AppColors.grey.withOpacity(0.0),
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
  ];

  /// Theme where nav bar is [grey] (with default dark theme).
  /// For light this means [eee].
  ///
  /// The opposite is [black].
  static final grey = [
    black[0].copyWith(systemNavigationBarColor: AppColors.eee),
    black[1].copyWith(systemNavigationBarColor: AppColors.grey),
  ];

  /// Theme for the drawer screen.
  static final drawerScreen = [
    black[0].copyWith(
      statusBarColor: Colors.white,
      systemNavigationBarColor: Colors.white,
    ),
    black[1].copyWith(
      statusBarColor: AppColors.grey,
      systemNavigationBarColor: AppColors.grey,
    ),
  ];

  /// Theme for the bottom sheet dialog.
  static final bottomSheet = [
    black[0].copyWith(
      systemNavigationBarColor: Colors.white,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    black[1].copyWith(
      systemNavigationBarColor: Colors.black,
    ),
  ];

  /// Theme for the modal dialog.
  static final modal = [
    black[0].copyWith(
      systemNavigationBarColor: const Color(0xff757575),
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    black[1],
  ];

  /// Theme for the modal dialog that is displayed over [grey].
  static final modalOverGrey = [
    modal[0].copyWith(
      systemNavigationBarColor: const Color(0xff6d6d6d),
    ),
    modal[1].copyWith(
      systemNavigationBarColor: const Color(0xff0d0d0d),
    ),
  ];
}
