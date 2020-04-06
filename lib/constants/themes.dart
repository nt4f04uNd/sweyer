/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';

import 'colors.dart';

abstract class AppTheme {
  //******************************************** GENERIC COLORS ********************************************
  /// Main colors - [whiteDarkened] and [greyLight]
  static final _ThemeContainer<Color> main = _ThemeContainer(
      light: AppColors.whiteDarkened, dark: AppColors.greyLight);

  /// Colors that are in contrast with [main], so they can be use for text and icons
  ///
  /// Alternatively `main.autoInverse` can be used
  static final _ThemeContainer<Color> mainContrast =
      _ThemeContainer(light: Color(0xff616266), dark: Color(0xfff1f2f4));

  //************************************** WIDGET SPECIFIC COLORS ******************************************

  static final _ThemeContainer<Color> albumArt =
      _ThemeContainer(light: Color(0xfff1f2f4), dark: AppColors.greyLighter);

  static final _ThemeContainer<Color> albumArtSmallRound =
      _ThemeContainer(light: Colors.white, dark: Color(0xFF353535));

      

  static final _ThemeContainer<Color> searchFakeInput = _ThemeContainer(
      // light: Colors.black.withOpacity(0.05),
      light: AppColors.whiteDarkened,
      dark: Colors.white.withOpacity(0.05));

  static final _ThemeContainer<Color> popupMenu =
      _ThemeContainer(light: Color(0xFFeeeeee), dark: Color(0xFF333333));

  static final _ThemeContainer<Color> disabledIcon =
      _ThemeContainer(light: Colors.grey.shade400, dark: Colors.grey.shade800);

  static final _ThemeContainer<Color> playPauseIcon =
      _ThemeContainer(light: Color(0xff555659), dark: Color(0xfff1f2f4));

  static final _ThemeContainer<Color> prevNextBorder = _ThemeContainer(
      light: Colors.black.withOpacity(0.1),
      dark: Colors.white.withOpacity(0.1));

  static final _ThemeContainer<Color> playPauseBorder = _ThemeContainer(
      light: Colors.black.withOpacity(0.15),
      dark: Colors.white.withOpacity(0.15));

  static final _ThemeContainer<Color> sliderInactive = _ThemeContainer(
      light: Colors.black.withOpacity(0.2),
      dark: Colors.white.withOpacity(0.2));

  static final _ThemeContainer<Color> drawer =
      _ThemeContainer(light: Colors.white, dark: AppColors.grey);

  static final _ThemeContainer<Color> menuItem =
      _ThemeContainer(light: Color(0xff3d3e42), dark: Color(0xffe7e8ec));

  static final _ThemeContainer<Color> refreshIndicatorArrow =
      _ThemeContainer(light: Color(0xFFe7e7e7), dark: Colors.white);

  static final _ThemeContainer<ThemeData> materialApp = _ThemeContainer(
    light: ThemeData(
      //******** General ********
      fontFamily: 'Manrope',
      brightness: Brightness.light,
      //****************** Colors **********************
      accentColor: Colors.grey,
      backgroundColor: Colors.white,
      primaryColor: Colors.deepPurpleAccent,

      //****************** Color scheme (preferable to colors) *********************
      colorScheme: ColorScheme(
        background: Colors.white,
        brightness: Brightness.light,
        error: const Color(0xffed3b3b),
        onBackground: Colors.black,
        onError: Colors.white,
        onPrimary: Colors.white,
        onSecondary: AppColors.greyLight,
        onSurface: Colors.black,
        primary: Colors.deepPurpleAccent,
        primaryVariant: Colors.deepPurple,
        secondary: AppColors.whiteDarkened,
        secondaryVariant: Colors.white,
        surface: Colors.white,
      ),

      //****************** Specific app elements *****************
      scaffoldBackgroundColor: Colors.white,
      textSelectionColor: Colors.deepPurpleAccent,
      textSelectionHandleColor: Colors.deepPurpleAccent,
      cursorColor: Colors.deepPurpleAccent,
      splashColor: Color(0x90bbbbbb),
    
      highlightColor:Colors.transparent,
      // highlightColor: Colors.deepPurpleAccent.shade100,

      //****************** Themes *********************
     
      textTheme: const TextTheme(
        /// See https://material.io/design/typography/the-type-system.html#type-scale
        button: TextStyle(fontWeight: FontWeight.w600),
        headline1:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        headline2:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        headline3:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        headline4:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        headline5: TextStyle(fontWeight: FontWeight.w600),
        headline6:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        subtitle1:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        subtitle2:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        bodyText1: TextStyle(fontWeight: FontWeight.w600),
        bodyText2: TextStyle(fontWeight: FontWeight.w600),
        overline: TextStyle(fontWeight: FontWeight.w600),
        caption: TextStyle(fontWeight: FontWeight.w600),
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
        color: Colors.white,
        elevation: 0.0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        backgroundColor: AppColors.whiteDarkened,
      ),
    ),
    dark: ThemeData(
      //******** General ********
      fontFamily: 'Manrope',
      brightness: Brightness.dark,
      //****************** Colors **********************
      accentColor: const Color(0xff131313),
      backgroundColor: AppColors.grey,
      primaryColor: Colors.deepPurpleAccent,
      //****************** Color scheme (preferable to colors) *********************
      colorScheme: ColorScheme(
        background: AppColors.grey,
        brightness: Brightness.dark,
        error: const Color(0xffed3b3b),
        onBackground: AppColors.whiteDarkened,
        onError: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        primary: Colors.deepPurpleAccent,
        primaryVariant: Colors.deepPurple,
        secondary: AppColors.greyLight,
        secondaryVariant: AppColors.grey,
        surface: AppColors.greyLighter,
      ),
      //****************** Specific app elements *****************
      scaffoldBackgroundColor: AppColors.grey,
      textSelectionColor: Colors.deepPurpleAccent,
      textSelectionHandleColor: Colors.deepPurpleAccent,
      cursorColor: Colors.deepPurpleAccent,
      splashColor: Colors.deepPurpleAccent,
      highlightColor: Colors.transparent,

      //****************** Themes *********************
      textTheme: const TextTheme(
        /// See https://material.io/design/typography/the-type-system.html#type-scale
        button: TextStyle(fontWeight: FontWeight.w600),
        headline1: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        headline2: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        headline3: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        headline4: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        headline5: TextStyle(fontWeight: FontWeight.w600),
        headline6: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        subtitle1: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        subtitle2: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        bodyText1: TextStyle(fontWeight: FontWeight.w600),
        bodyText2: TextStyle(fontWeight: FontWeight.w600),
        overline: TextStyle(fontWeight: FontWeight.w600),
        caption: TextStyle(fontWeight: FontWeight.w600),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder()
        },
      ),
      appBarTheme: AppBarTheme(
        // brightness: Brightness.dark,
        color: AppColors.grey,
        elevation: 0,
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
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
    dark: SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.grey,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  /// Theme for the main screen
  static final _ThemeContainer<SystemUiOverlayStyle> mainScreen =
      _ThemeContainer(
    light: allScreens.light
        .copyWith(systemNavigationBarColor: AppColors.whiteDarkened),
    dark:
        allScreens.dark.copyWith(systemNavigationBarColor: AppColors.greyLight),
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
  static final _ThemeContainer<SystemUiOverlayStyle> dialogScreen =
      _ThemeContainer(
    light:
        allScreens.light.copyWith(systemNavigationBarColor: Color(0xffaaaaaa)),
    dark: allScreens.dark.copyWith(systemNavigationBarColor: Color(0xff111111)),
  );
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
