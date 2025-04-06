import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

import '../colors.dart';

part 'system_ui_theme.tailor.dart';

@TailorMixin()
class SystemUiTheme extends ThemeExtension<SystemUiTheme> with _$SystemUiThemeTailorMixin {
  const SystemUiTheme({
    required this.black,
    required this.grey,
    required this.drawerScreen,
    required this.bottomSheet,
    required this.modal,
    required this.modalOverGreySystemNavigationBarColor,
  });

  /// Theme where nav bar is [grey] (with default dark theme).
  /// For light this means [eee].
  ///
  /// The opposite is [black].
  @override
  final SystemUiOverlayStyle grey;

  /// Default theme for all screens.
  ///
  /// Theme where nav bar is [black] (with default dark theme).
  /// For light this means [white].
  ///
  /// The opposite is [grey].
  @override
  final SystemUiOverlayStyle black;

  /// Theme for the drawer screen.
  @override
  final SystemUiOverlayStyle drawerScreen;

  /// Theme for the bottom sheet dialog.
  @override
  final SystemUiOverlayStyle bottomSheet;

  /// Theme for the modal dialog.
  @override
  final SystemUiOverlayStyle modal;

  @override
  final Color modalOverGreySystemNavigationBarColor;

  /// Theme for the modal dialog that is displayed over [grey].
  @override
  SystemUiOverlayStyle get modalOverGrey => modal.copyWith(
        systemNavigationBarColor: modalOverGreySystemNavigationBarColor,
      );

  static final SystemUiOverlayStyle _lightBaseStyle = SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarColor: Colors.white.withOpacity(0.0),
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.dark,
  );

  static final SystemUiOverlayStyle _darkBaseStyle = SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: AppColors.grey.withOpacity(0.0),
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
  );

  static final SystemUiTheme light = SystemUiTheme(
    black: _lightBaseStyle,
    grey: _lightBaseStyle.copyWith(systemNavigationBarColor: AppColors.eee),
    drawerScreen: _lightBaseStyle.copyWith(
      statusBarColor: Colors.white,
      systemNavigationBarColor: Colors.white,
    ),
    bottomSheet: _lightBaseStyle.copyWith(
      systemNavigationBarColor: Colors.white,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    modal: _lightBaseStyle.copyWith(
      systemNavigationBarColor: const Color(0xff757575),
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    modalOverGreySystemNavigationBarColor: const Color(0xff6d6d6d),
  );

  static final SystemUiTheme dark = SystemUiTheme(
    black: _darkBaseStyle,
    grey: _darkBaseStyle.copyWith(systemNavigationBarColor: AppColors.grey),
    drawerScreen: _darkBaseStyle.copyWith(
      statusBarColor: AppColors.grey,
      systemNavigationBarColor: AppColors.grey,
    ),
    bottomSheet: _darkBaseStyle.copyWith(
      systemNavigationBarColor: Colors.black,
    ),
    modal: _darkBaseStyle,
    modalOverGreySystemNavigationBarColor: const Color(0xff0d0d0d),
  );
}
