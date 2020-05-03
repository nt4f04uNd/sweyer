/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';

import 'colors.dart';

abstract class AppTheme {
  //************************************** WIDGET SPECIFIC COLORS ******************************************

  static final _ThemeContainer<Color> albumArt = _ThemeContainer(
    light: const Color(0xfff1f2f4),
    dark: AppColors.grey,
  );

  static final _ThemeContainer<Color> albumArtSmallRound = _ThemeContainer(
    // light: AppColors.whiteDarkened,
    light: albumArt.light,
    dark: const Color(0xFF353535),
  );

  static final _ThemeContainer<Color> searchFakeInput = _ThemeContainer(
    // light: Colors.black.withOpacity(0.05),
    // light: AppColors.whiteDarkened,
    light: Colors.white,
    dark: Colors.white.withOpacity(0.05),
  );

  static final _ThemeContainer<Color> popupMenu = _ThemeContainer(
    light: const Color(0xFFeeeeee),
    dark: const Color(0xFF333333),
  );

  static final _ThemeContainer<Color> disabledIcon = _ThemeContainer(
    light: Colors.grey.shade400,
    dark: Colors.grey.shade800,
  );

  static final _ThemeContainer<Color> playPauseIcon = _ThemeContainer(
    light: const Color(0xff555659),
    dark: const Color(0xfff1f2f4),
  );

  static final _ThemeContainer<Color> prevNextBorder = _ThemeContainer(
    light: Colors.black.withOpacity(0.1),
    dark: AppColors.almostWhite.withOpacity(0.1),
  );

  static final _ThemeContainer<Color> playPauseBorder = _ThemeContainer(
    light: Colors.black.withOpacity(0.15),
    dark: Colors.white.withOpacity(0.15),
  );

  static final _ThemeContainer<Color> sliderInactive = _ThemeContainer(
    light: Colors.black.withOpacity(0.2),
    dark: Colors.white.withOpacity(0.2),
  );

  static final _ThemeContainer<Color> drawer = _ThemeContainer(
    light: Colors.white,
    dark: AppColors.grey,
  );

  static final _ThemeContainer<Color> menuItem = _ThemeContainer(
    light: const Color(0xff3d3e42),
    dark: AppColors.almostWhite,
  );

  static final _ThemeContainer<Color> refreshIndicatorArrow = _ThemeContainer(
    light: const Color(0xFFe7e7e7),
    dark: Colors.white,
  );

  static final _ThemeContainer<ThemeData> materialApp = _ThemeContainer(
    light: ThemeData(
      //******** General ********
      fontFamily: 'Manrope',
      brightness: Brightness.light,
      //****************** Colors **********************
      accentColor: Colors.white,
      backgroundColor: Colors.white,
      primaryColor: Colors.deepPurpleAccent,

      //****************** Color scheme (preferable to colors) *********************
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        background: Colors.white,
        onBackground: AppColors.greyText,
        primary: Colors.deepPurpleAccent,
        // This is not darker, though lighter version
        primaryVariant: Color(0xff936bff),
        onPrimary: Colors.white,
        // secondary: AppColors.whiteDarkened,
        secondary: Colors.white,
        secondaryVariant: Colors.white,
        onSecondary: AppColors.grey,
        error: const Color(0xffed3b3b),
        onError: Colors.white,

        /// For window headers (e.g. alert dialogs)
        // surface: Colors.white,
        surface: AppColors.whiteDarkened,

        /// For dimmed text (e.g. in appbar)
        onSurface: const Color(0xff616266),
      ),

      //****************** Specific app elements *****************
      scaffoldBackgroundColor: AppColors.almostWhite,
      textSelectionColor: Colors.deepPurpleAccent,
      textSelectionHandleColor: Colors.deepPurpleAccent,
      cursorColor: Colors.deepPurpleAccent,
      splashColor: const Color(0x40cccccc),
      // splashColor: Color(0x90bbbbbb),

      highlightColor: Colors.transparent,
      // highlightColor: Colors.deepPurpleAccent.shade100,

      //****************** Themes *********************

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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder()
        },
      ),
      appBarTheme: const AppBarTheme(
        brightness: Brightness.light,
        elevation: 0.0,
        color: Colors.white,
        iconTheme: const IconThemeData(color: Colors.red),
        textTheme: TextTheme(
          headline6: const TextStyle(
            color: AppColors.greyText,
             fontWeight: FontWeight.w600,
              fontSize:20.0,
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
        // backgroundColor: AppColors.whiteDarkened,
      ),
    ),
    dark: ThemeData(
      //******** General ********
      fontFamily: 'Manrope',
      brightness: Brightness.dark,
      //****************** Colors **********************
      accentColor: AppColors.grey,
      // backgroundColor: AppColors.grey,
      backgroundColor: Colors.black,
      primaryColor: Colors.deepPurpleAccent,

      //****************** Color scheme (preferable to colors) *********************
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        // background: AppColors.grey,
        background: Colors.black,
        onBackground: AppColors.almostWhite,
        primary: Colors.deepPurpleAccent,
        // This is not darker, though lighter version
        primaryVariant: Color(0xff936bff),
        onPrimary: AppColors.almostWhite,
        secondary: AppColors.grey,
        secondaryVariant: AppColors.grey,
        onSecondary: AppColors.almostWhite,
        error: const Color(0xffed3b3b),
        onError: AppColors.almostWhite,

        /// For window headers (e.g. alert dialogs)
        surface: AppColors.grey,

        /// For dimmed text (e.g. in appbar)
        onSurface: const Color(0xfff1f2f4),
      ),
      //****************** Specific app elements *****************
      // scaffoldBackgroundColor: AppColors.grey,
      scaffoldBackgroundColor: Colors.black,
      textSelectionColor: Colors.deepPurpleAccent,
      textSelectionHandleColor: Colors.deepPurpleAccent,
      cursorColor: Colors.deepPurpleAccent,
      splashColor: Colors.deepPurpleAccent,
      highlightColor: Colors.transparent,

      //****************** Themes *********************
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder()
        },
      ),
      appBarTheme: AppBarTheme(
        brightness: Brightness.dark,
        color: AppColors.grey,
        elevation: 0.0,
        textTheme: TextTheme(
          headline6: const TextStyle(
            color: AppColors.almostWhite,
             fontWeight: FontWeight.w600,
              fontSize:20.0,
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

abstract class AppSystemUIThemes {
  /// Generic theme for all screens
  static final _ThemeContainer<SystemUiOverlayStyle> allScreens =
      _ThemeContainer(
    light: const SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.almostWhite,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
    dark: SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  /// Theme for the drawer screen
  static final _ThemeContainer<SystemUiOverlayStyle> drawerScreen =
      _ThemeContainer(
    light: allScreens.light.copyWith(statusBarColor: Colors.white),
    dark: allScreens.dark.copyWith(statusBarColor: AppColors.grey),
  );

  /// Theme for dialog screen
  ///
  /// TODO: implement this with dialogs
  // static final _ThemeContainer<SystemUiOverlayStyle> dialogScreen =
  //     _ThemeContainer(
  //   light:
  //       allScreens.light.copyWith(systemNavigationBarColor: Color(0xffaaaaaa)),
  //   dark: allScreens.dark.copyWith(systemNavigationBarColor: Color(0xff111111)),
  // );
}

/// Class to wrap some values, so they will have [light] and [dark] variants
class _ThemeContainer<T> {
  final T light;
  final T dark;
  _ThemeContainer({@required this.light, @required this.dark});

  /// Checks theme and automatically returns corresponding ui style
  ///
  /// Requires [BuildContext]
  ///
  /// @return [light] or [dark], depending on current brightness
  T auto(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// Checks theme and automatically returns corresponding ui style
  ///
  /// Unlike [auto] doesn't require context
  T get autoWithoutContext => ThemeControl.isDark ? dark : light;

  /// Inverses brightness
  T autoInverse(BuildContext context) =>
      Theme.of(context).brightness != Brightness.dark ? dark : light;

  /// Copy [auto], but accepts brightness instead of context
  ///
  /// Also checks theme and automatically returns corresponding ui style
  ///
  /// Requires [Brightness]
  ///
  /// @return [light] or [dark], depending on current brightness
  T autoBr(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Inverses brightness
  T autoBrInverse(Brightness brightness) =>
      brightness == Brightness.light ? dark : light;
}
