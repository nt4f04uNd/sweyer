/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';

import 'colors.dart';

// todo: nt4f04unds_widgets

abstract class AppTheme {
  static const Color defaultPrimaryColor = AppColors.deepPurpleAccent;

  //************************************** WIDGET SPECIFIC COLORS ******************************************

  static final _ThemeContainer<Color> sliderInactive = _ThemeContainer(
    light: Colors.black.withOpacity(0.2),
    dark: Colors.white.withOpacity(0.2),
  );

  static final _ThemeContainer<Color> menuItem = _ThemeContainer(
    light: const Color(0xff3d3e42),
    dark: AppColors.almostWhite,
  );

  static final _ThemeContainer<Color> dialogButtonSplash = _ThemeContainer(
    light: const Color(0x40cccccc),
    dark: Colors.white.withOpacity(0.16),
  );

  static const Color _lightIconColor = Color(0xff616266);

  static _ThemeContainer<ThemeData> app = _ThemeContainer(
    light: ThemeData(
      //******** General ********
      fontFamily: 'Manrope',
      brightness: Brightness.light,
      //****************** Colors **********************
      accentColor: Colors.white,
      backgroundColor: Colors.white,
      primaryColor: defaultPrimaryColor,
      disabledColor: Colors.grey.shade400,
      unselectedWidgetColor: Colors.grey.shade400,

      //****************** Color scheme (preferable to colors) *********************
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        background: Colors.white,
        onBackground: AppColors.greyText,
        primary: defaultPrimaryColor,
        // This is not darker, though lighter version
        primaryVariant: Color(0xff936bff),
        onPrimary: Colors.white,
        secondary: AppColors.eee,
        secondaryVariant: Colors.white,
        // todo: Temporarily used for text in [NFButtons]
        onSecondary: defaultPrimaryColor,
        error: const Color(0xffed3b3b),
        onError: Colors.white,

        /// For window headers (e.g. alert dialogs)
        surface: Colors.white,

        /// For dimmed text (e.g. in appbar)
        onSurface: _lightIconColor,
      ),

      //****************** Specific app elements *****************
      scaffoldBackgroundColor: Colors.white,
      splashColor: const Color(0x40cccccc),
      splashFactory: NFListTileInkRipple.splashFactory,
      highlightColor: Colors.transparent,

      //****************** Themes *********************
      iconTheme: const IconThemeData(color: _lightIconColor),
      tooltipTheme: const TooltipThemeData(
        verticalOffset: 20.0,
        textStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        decoration: BoxDecoration(
          color: defaultPrimaryColor,
          borderRadius: BorderRadius.all(
            Radius.circular(100.0),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: defaultPrimaryColor,
        selectionColor: defaultPrimaryColor,
        selectionHandleColor: defaultPrimaryColor,
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(
            const TextStyle(
              color: defaultPrimaryColor,
            ),
          ),
        ),
      ),
      buttonTheme: ButtonThemeData(
        textTheme: ButtonTextTheme.primary,
      ),
      textTheme: const TextTheme(
        /// See https://material.io/design/typography/the-type-system.html#type-scale
        button: const TextStyle(fontWeight: FontWeight.w600),
        headline1:
            const TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
        headline2:
            const TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
        headline3:
            const TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
        // For the app title
        headline4:
            const TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),

        headline5:
            const TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
        // Title in song tiles
        headline6: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.greyText,
          fontSize: 15.0,
        ),
        subtitle1: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.grey,
        ),
        // Artist widget
        subtitle2: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black54,
          fontSize: 13.5,
          height: 0.9,
        ),
        bodyText1: const TextStyle(fontWeight: FontWeight.w700),
        bodyText2: const TextStyle(fontWeight: FontWeight.w600),
        overline: const TextStyle(fontWeight: FontWeight.w600),
        caption: const TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        brightness: Brightness.light,
        elevation: 0.0,
        color: AppColors.eee,
        textTheme: TextTheme(
          headline6: const TextStyle(
            color: AppColors.greyText,
            fontWeight: FontWeight.w600,
            fontSize: 20.0,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        backgroundColor: Colors.white,
      ),
    ),
    dark: ThemeData(
      //******** General ********
      fontFamily: 'Manrope',
      brightness: Brightness.dark,
      //****************** Colors **********************
      accentColor: AppColors.grey,
      backgroundColor: Colors.black,
      primaryColor: defaultPrimaryColor,
      disabledColor: Colors.grey.shade800,
      unselectedWidgetColor: Colors.grey.shade800,

      //****************** Color scheme (preferable to colors) *********************
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        background: Colors.black,
        onBackground: AppColors.almostWhite,
        primary: defaultPrimaryColor,
        // This is not darker, though lighter version
        primaryVariant: Color(0xff936bff),
        onPrimary: AppColors.almostWhite,
        secondary: AppColors.grey,
        secondaryVariant: Colors.black,
        // todo: Temporarily used for [NFButtons]
        onSecondary: AppColors.almostWhite,
        error: const Color(0xffed3b3b),
        onError: AppColors.almostWhite,

        /// For window headers (e.g. alert dialogs)
        surface: AppColors.grey,

        /// For dimmed text (e.g. in appbar)
        onSurface: AppColors.whiteDarkened,
      ),
      //****************** Specific app elements *****************
      // scaffoldBackgroundColor: AppColors.grey,
      scaffoldBackgroundColor: Colors.black,
      splashColor: defaultPrimaryColor,
      highlightColor: Colors.transparent,

      //****************** Themes *********************
      iconTheme: const IconThemeData(color: AppColors.whiteDarkened),
      tooltipTheme: const TooltipThemeData(
        verticalOffset: 20.0,
        textStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        decoration: BoxDecoration(
          color: defaultPrimaryColor,
          borderRadius: BorderRadius.all(
            Radius.circular(100.0),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: defaultPrimaryColor,
        selectionColor: defaultPrimaryColor,
        selectionHandleColor: defaultPrimaryColor,
      ),
      textTheme: const TextTheme(
        /// See https://material.io/design/typography/the-type-system.html#type-scale
        button: const TextStyle(fontWeight: FontWeight.w600),
        headline1: const TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.almostWhite),
        headline2: const TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.almostWhite),
        headline3: const TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.almostWhite),
        headline4: const TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.almostWhite),
        headline5: const TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.almostWhite),
        headline6: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.almostWhite,
          fontSize: 15.0,
        ),
        // Title in song tiles
        subtitle1: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.almostWhite,
        ),
        // Artist widget
        subtitle2: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white70,
          fontSize: 13.5,
          height: 0.9,
        ),
        bodyText1: const TextStyle(fontWeight: FontWeight.w700),
        bodyText2: const TextStyle(fontWeight: FontWeight.w600),
        overline: const TextStyle(fontWeight: FontWeight.w600),
        caption: const TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        brightness: Brightness.dark,
        color: AppColors.grey,
        elevation: 0.0,
        textTheme: TextTheme(
          headline6: const TextStyle(
            color: AppColors.almostWhite,
            fontWeight: FontWeight.w600,
            fontSize: 20.0,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        backgroundColor: Color(0xff070707),
      ),
    ),
  );
}

abstract class UiTheme {
  /// Default theme for all screens.
  ///
  /// Theme where nav bar is [black] (with default dark theme).
  /// For light this means [white].
  ///
  /// The opposite is [grey].
  static final _ThemeContainer<SystemUiOverlayStyle> black = _ThemeContainer(
    /// [withOpacity] needed for smooth transtion to [drawerScreen].
    light: SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.white.withOpacity(0.0),
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
    dark: SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: AppColors.grey.withOpacity(0.0),
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  /// Theme where nav bar is [grey] (with default dark theme).
  /// For light this means [eee].
  ///
  /// The opposite is [black].
  static final _ThemeContainer<SystemUiOverlayStyle> grey = _ThemeContainer(
    light: black.light.copyWith(systemNavigationBarColor: AppColors.eee),
    dark: black.dark.copyWith(systemNavigationBarColor: AppColors.grey),
  );

  /// Theme for the drawer screen.
  static final _ThemeContainer<SystemUiOverlayStyle> drawerScreen =
      _ThemeContainer(
    light: black.light.copyWith(
      statusBarColor: Colors.white,
      systemNavigationBarColor: Colors.white,
    ),
    dark: black.dark.copyWith(
      statusBarColor: AppColors.grey,
      systemNavigationBarColor: AppColors.grey,
    ),
  );

  /// Theme for the bottom sheet dialog.
  static final _ThemeContainer<SystemUiOverlayStyle> bottomSheet =
      _ThemeContainer(
    light: black.light.copyWith(
      systemNavigationBarColor: Colors.white,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    dark: black.dark.copyWith(
      systemNavigationBarColor: Colors.black,
    ),
  );

  /// Theme for the modal dialog.
  static final _ThemeContainer<SystemUiOverlayStyle> modal = _ThemeContainer(
    light: black.light.copyWith(
      systemNavigationBarColor: const Color(0xff757575),
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
    dark: black.dark.copyWith(
      statusBarColor: Colors.black,
    ),
  );

  /// Theme for the modal dialog that is displayed over [grey].
  static final _ThemeContainer<SystemUiOverlayStyle> modalOverGrey =
      _ThemeContainer(
    light: modal.light.copyWith(
      systemNavigationBarColor: const Color(0xff6d6d6d),
    ),
    dark: modal.dark.copyWith(
      systemNavigationBarColor: const Color(0xff0d0d0d),
    ),
  );
}

/// Class to wrap some values, so they will have [light] and [dark] variants.
class _ThemeContainer<T> {
  final T light;
  final T dark;
  const _ThemeContainer({@required this.light, @required this.dark});

  /// Checks theme and automatically [light] or [dark], depending on current brightness.
  T get auto => ThemeControl.isDark ? dark : light;

  _ThemeContainer<T> copyWith({T light, T dark}) {
    return _ThemeContainer(
      light: light ?? this.light,
      dark: dark ?? this.dark,
    );
  }
}
