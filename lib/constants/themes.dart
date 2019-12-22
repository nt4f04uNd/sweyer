/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';

abstract class AppTheme {
  static final ThemeContainer<Color> albumArtLarge =
      ThemeContainer(light: Color(0xFFe8e8e8), dark: Color(0xFF333333));

  static final ThemeContainer<Color> albumArtSmall =
      ThemeContainer(light: Color(0xfff1f2f4), dark: Color(0xFF313131));

  static final ThemeContainer<Color> albumArtSmallRound =
      ThemeContainer(light: Colors.white, dark: Color(0xFF353535));

  static final ThemeContainer<Color> bottomTrackPanel =
      ThemeContainer(light: AppColors.whiteDarkened, dark: AppColors.greyLight);

  static final ThemeContainer<Color> searchFakeInput = ThemeContainer(
      // light: Colors.black.withOpacity(0.05),
      light: AppColors.whiteDarkened,
      dark: Colors.white.withOpacity(0.05));

  static final ThemeContainer<Color> popupMenu =
      ThemeContainer(light: Color(0xFFeeeeee), dark: Color(0xFF333333));

  static final ThemeContainer<Color> declineButton =
      ThemeContainer(light: Color(0xFF606060), dark: null);

  static final ThemeContainer<Color> redFlatButton =
      ThemeContainer(light: Colors.red.shade300, dark: Colors.red.shade200);

  static final ThemeContainer<Color> splash =
      ThemeContainer(light: Color(0x90bbbbbb), dark: Color(0x44c8c8c8));

  static final ThemeContainer<Color> disabledIcon =
      ThemeContainer(light: Colors.grey.shade400, dark: Colors.grey.shade800);

  static final ThemeContainer<Color> playPauseIcon =
      ThemeContainer(light: Color(0xff555659), dark: Color(0xfff1f2f4));

  static final ThemeContainer<Color> prevNextBorder = ThemeContainer(
      light: Colors.black.withOpacity(0.1),
      dark: Colors.white.withOpacity(0.1));

  static final ThemeContainer<Color> playPauseBorder = ThemeContainer(
      light: Colors.black.withOpacity(0.15),
      dark: Colors.white.withOpacity(0.15));

  static final ThemeContainer<Color> sliderInactive = ThemeContainer(
      light: Colors.black.withOpacity(0.2),
      dark: Colors.white.withOpacity(0.2));

  /// Main colors - `whiteDarkened` and `greyLight`
  static final ThemeContainer<Color> main =
      ThemeContainer(light: AppColors.whiteDarkened, dark: AppColors.greyLight);

  static final ThemeContainer<Color> drawer =
      ThemeContainer(light: Colors.white, dark: AppColors.grey);

  static final ThemeContainer<Color> menuItem =
      ThemeContainer(light: Color(0xff3d3e42), dark: Color(0xffe7e8ec));
  static final ThemeContainer<Color> menuItemIcon =
      ThemeContainer(light: Color(0xff616266), dark: Color(0xfff1f2f4));

  static final ThemeContainer<Color> refreshIndicatorArrow =
      ThemeContainer(light: Color(0xFFe7e7e7), dark: Colors.white);

  static ThemeContainer<ThemeData> materialApp = ThemeContainer(
    light: ThemeData(
      fontFamily: 'Manrope',
      textTheme: TextTheme(
        title:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        subtitle:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        body2: TextStyle(fontWeight: FontWeight.w600),
        button: TextStyle(fontWeight: FontWeight.w600),
        display1:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        display2:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        display3:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        display4:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
        headline: TextStyle(fontWeight: FontWeight.w600),
        overline: TextStyle(fontWeight: FontWeight.w600),
        body1: TextStyle(fontWeight: FontWeight.w600),
        caption: TextStyle(fontWeight: FontWeight.w600),
        subhead:
            TextStyle(fontWeight: FontWeight.w600, color: AppColors.greyLight),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder()
        },
      ),
      appBarTheme: AppBarTheme(
        brightness: Brightness.light,
        color: Colors.white,
        elevation: 0,
      ),
      // iconTheme: ,
      scaffoldBackgroundColor: Colors.white,
      brightness: Brightness.light,
      accentColor: Colors.white,
      backgroundColor: Colors.white,
      primaryColor: Colors.deepPurple,
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        backgroundColor: AppColors.whiteDarkened,
      ),
      textSelectionColor: Colors.deepPurple,
      textSelectionHandleColor: Colors.deepPurple,
      cursorColor: Colors.deepPurple,
    ),
    dark: ThemeData(
      fontFamily: 'Manrope',
      textTheme: TextTheme(
        title: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        subtitle: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        body2: TextStyle(fontWeight: FontWeight.w600),
        button: TextStyle(fontWeight: FontWeight.w600),
        display1: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        display2: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        display3: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        display4: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
        headline: TextStyle(fontWeight: FontWeight.w600),
        overline: TextStyle(fontWeight: FontWeight.w600),
        body1: TextStyle(fontWeight: FontWeight.w600),
        caption: TextStyle(fontWeight: FontWeight.w600),
        subhead: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.whiteDarkened),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
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
      scaffoldBackgroundColor: AppColors.grey,
      brightness: Brightness.dark,
      accentColor: AppColors.grey,
      backgroundColor: AppColors.grey,
      primaryColor: Colors.deepPurple,
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        backgroundColor: Color(0xff070707),
      ),
      textSelectionColor: Colors.deepPurple,
      textSelectionHandleColor: Colors.deepPurple,
      cursorColor: Colors.deepPurple,
    ),
  );
}

abstract class AppSystemUIThemes {
  /// Generic theme for all screens
  static final ThemeContainer<SystemUiOverlayStyle> allScreens = ThemeContainer(
    light: SystemUiOverlayStyle(
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
  static final ThemeContainer<SystemUiOverlayStyle> mainScreen = ThemeContainer(
    light: allScreens.light
        .copyWith(systemNavigationBarColor: AppColors.whiteDarkened),
    // light: allScreens.light
    //     .copyWith(systemNavigationBarColor: AppColors.whiteDarkened, statusBarColor: AppColors.whiteDarkened),
    dark:
        allScreens.dark.copyWith(systemNavigationBarColor: AppColors.greyLight),
  );

  /// Theme for the drawer screen
  static final ThemeContainer<SystemUiOverlayStyle> drawerScreen =
      ThemeContainer(
    light: allScreens.light.copyWith(statusBarColor: AppColors.whiteDarkened),
    dark: allScreens.dark.copyWith(statusBarColor: AppColors.grey),
  );

  /// Theme for dialog screen
  ///
  /// TODO: implement this with dialogs
  static final ThemeContainer<SystemUiOverlayStyle> dialogScreen =
      ThemeContainer(
    light:
        allScreens.light.copyWith(systemNavigationBarColor: Color(0xffaaaaaa)),
    dark: allScreens.dark.copyWith(systemNavigationBarColor: Color(0xff111111)),
  );
}

/// Class to wrap some values, so they will have `light` and `dark` variants
class ThemeContainer<T> {
  final T light;
  final T dark;
  ThemeContainer({@required this.light, @required this.dark});

  /// Checks theme and automatically returns corresponding ui style
  ///
  /// Requires `BuildContext`
  ///
  /// @return `light` or `dark`, depending on current brightness
  T auto(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// Inverses brightness
  T autoInverse(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? dark : light;

  /// Copy `auto`, but accepts brightness instead of context
  ///
  /// Also checks theme and automatically returns corresponding ui style
  ///
  /// Requires `Brightness`
  ///
  /// @return `light` or `dark`, depending on current brightness
  T autoBr(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Inverses brightness
  T autoBrInverse(Brightness brightness) =>
      brightness == Brightness.light ? dark : light;
}
