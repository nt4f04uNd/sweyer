/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';

abstract class AppTheme {
  static final ThemeContainer<Color> albumArtLarge =
      ThemeContainer(light: Color(0xFFe7e7e7), dark: Color(0xFF333333));

  static final ThemeContainer<Color> albumArtSmall =
      ThemeContainer(light: Color(0xFFf0f0f0), dark: Color(0xFF313131));

  static final ThemeContainer<Color> albumArtSmallRound =
      ThemeContainer(light: Colors.white, dark: Color(0xFF353535));

  static final ThemeContainer<Color> bottomTrackPanel =
      ThemeContainer(light: AppColors.whiteDarkened, dark: AppColors.greyLight);

  static final ThemeContainer<Color> searchFakeInput = ThemeContainer(
      light: Colors.black.withOpacity(0.05),
      dark: Colors.white.withOpacity(0.05));

  static final ThemeContainer<Color> popupMenu =
      ThemeContainer(light: Color(0xFFeeeeee), dark: Color(0xFF333333));

  static final ThemeContainer<Color> declineButton =
      ThemeContainer(light: Color(0xFF606060), dark: null);

  static final ThemeContainer<Color> redFlatButton =
      ThemeContainer(light: Colors.red.shade300, dark: Colors.red.shade200);

  static final ThemeContainer<Color> splash =
      ThemeContainer(light: Color(0x90bbbbbb), dark: Color(0x44c8c8c8));

  static final ThemeContainer<Color> activeIcon =
      ThemeContainer(light: Colors.grey.shade900, dark: null);

  static final ThemeContainer<Color> disabledIcon =
      ThemeContainer(light: Colors.grey.shade500, dark: Colors.grey.shade800);

  static final ThemeContainer<Color> prevNextIcons = ThemeContainer(
      light: Colors.grey.shade800.withOpacity(0.9),
      dark: Colors.white.withOpacity(0.9));

  static final ThemeContainer<Color> prevNextBorder = ThemeContainer(
      light: Colors.black.withOpacity(0.1),
      dark: Colors.white.withOpacity(0.1));

  static final ThemeContainer<Color> playPauseIcon =
      ThemeContainer(light: Colors.grey.shade800, dark: Colors.white);

  static final ThemeContainer<Color> playPauseBorder = ThemeContainer(
      light: Colors.black.withOpacity(0.15),
      dark: Colors.white.withOpacity(0.15));

  static final ThemeContainer<Color> sliderInactive = ThemeContainer(
      light: Colors.black.withOpacity(0.2),
      dark: Colors.white.withOpacity(0.2));

  static final ThemeContainer<Color> modal =
      ThemeContainer(light: AppColors.whiteDarkened, dark: AppColors.greyLight);

  static final ThemeContainer<Color> drawer =
      ThemeContainer(light: Colors.white, dark: AppColors.grey);

  static final ThemeContainer<Color> drawerListItem = ThemeContainer(
      light: Colors.deepPurple.shade500, dark: Colors.deepPurple.shade300);

  static final ThemeContainer<Color> refreshIndicatorArrow =
      ThemeContainer(light: Color(0xFFe7e7e7), dark: Colors.white);
  static final ThemeContainer<Color> refreshIndicatorBackground =
      ThemeContainer(light: Colors.deepPurple, dark: AppColors.greyLight);

  static final ThemeContainer<ThemeData> materialApp = ThemeContainer(
    light: ThemeData(
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
    dark:
        allScreens.dark.copyWith(systemNavigationBarColor: AppColors.greyLight),
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

  /// Copy `auto`, but accepts brightness instead of context
  ///
  /// Also checks theme and automatically returns corresponding ui style
  ///
  /// Requires `Brightness`
  ///
  /// @return `light` or `dark`, depending on current brightness
  T autoBr(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
