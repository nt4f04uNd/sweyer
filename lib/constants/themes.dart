/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';

import 'colors.dart';

abstract class Theme {
  static const Color defaultPrimaryColor = AppColors.deepPurpleAccent;

  //************************************** WIDGET SPECIFIC COLORS ******************************************

  static final _ThemeContainer<Color> sliderInactiveColor = _ThemeContainer(
    light: Colors.black.withOpacity(0.2),
    dark: Colors.white.withOpacity(0.2),
  );

  static const _ThemeContainer<Color> appBarBorderColor = _ThemeContainer(
    light: AppColors.eee,
    dark: Color(0xff191b1a),
  );

  static const  _ThemeContainer<Color> menuItemColor = _ThemeContainer(
    light: Color(0xff3d3e42),
    dark: Colors.white,
  );

  /// Color that contrasts with the [ColorScheme.background].
  /// Black and white.
  static const _ThemeContainer<Color> contrast = _ThemeContainer(
    light: Colors.black,
    dark: Colors.white,
  );

  static const _lightThemeSplashColor = Color(0x40cccccc);

  /// Additional "glow" splash color aside of the one I put into the [ThemeData.splashColor],
  /// that is the primary splash of the application (see [app]).
  ///
  /// In light mode it's the same as the mentioned above primary splash color.
  ///
  /// This color can be used instead of the [ThemeData.splashColor]
  /// for creating splashes over sold colors (because otherwise splash will be indistinguishable from the color
  /// it's drawn over).
  ///
  /// For example, it can be used for better look of splashes over the primary color in dark mode.
  static final _ThemeContainer<Color> glowSplashColor = _ThemeContainer(
    light: _lightThemeSplashColor,
    dark: Colors.white.withOpacity(0.1),
  );

  /// A [glowSplashColor] to draw over [contrast].
  static final _ThemeContainer<Color> glowSplashColorOnContrast = _ThemeContainer(
    light: Colors.white.withOpacity(0.13),
    dark: const Color(0x80cccccc),
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
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        background: Colors.white,
        onBackground: AppColors.greyText,
        primary: defaultPrimaryColor,
        // This is not darker, though lighter version
        primaryVariant: Color(0xff936bff),
        onPrimary: Colors.white,
        secondary: AppColors.eee,
        secondaryVariant: Colors.white,
        // todo: temporarily used for text in [NFButtons], remove when it's removed
        onSecondary: defaultPrimaryColor,
        error: Color(0xffed3b3b),
        onError: Colors.white,
        /// For window headers (e.g. alert dialogs)
        surface: Colors.white,
        /// For dimmed text (e.g. in appbar)
        onSurface: _lightIconColor,
      ),

      //****************** Specific app elements *****************
      scaffoldBackgroundColor: Colors.white,
      splashColor: _lightThemeSplashColor,
      splashFactory: NFListTileInkRipple.splashFactory,
      highlightColor: Colors.transparent,

      //****************** Themes *********************
      iconTheme: const IconThemeData(color: _lightIconColor),
      tooltipTheme: const TooltipThemeData(
        verticalOffset: 20.0,
        textStyle: TextStyle(
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
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: defaultPrimaryColor,
        selectionColor: defaultPrimaryColor,
        selectionHandleColor: defaultPrimaryColor,
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(
            const TextStyle(
              color: defaultPrimaryColor,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        textTheme: ButtonTextTheme.primary,
      ),
      textTheme: const TextTheme(
        /// See https://material.io/design/typography/the-type-system.html#type-scale
        button: TextStyle(fontWeight: FontWeight.w600),
        headline1: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
        headline2: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
        headline3: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
        headline4: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
        headline5: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
        // Title in song tiles
        headline6: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.greyText,
          fontSize: 15.0,
        ),
        subtitle1: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.grey,
        ),
        // Artist widget
        subtitle2: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black54,
          fontSize: 13.5,
          height: 0.9,
        ),
        bodyText1: TextStyle(fontWeight: FontWeight.w700),
        bodyText2: TextStyle(fontWeight: FontWeight.w600),
        overline: TextStyle(fontWeight: FontWeight.w600),
        caption: TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        brightness: Brightness.light,
        elevation: 2.0,
        titleSpacing: 0.0,
        toolbarHeight: NFConstants.toolbarHeight,
        color: AppColors.eee,
        backwardsCompatibility: false,
        titleTextStyle: TextStyle(
          color: AppColors.greyText,
          fontWeight: FontWeight.w600,
          fontSize: 21.0,
          fontFamily: 'Roboto',
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
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
      // accentColor: AppColors.grey,
      accentColor: Colors.red,
      backgroundColor: Colors.black,
      primaryColor: defaultPrimaryColor,
      disabledColor: Colors.grey.shade800,
      unselectedWidgetColor: Colors.grey.shade800,

      //****************** Color scheme (preferable to colors) *********************
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        background: Colors.black,
        onBackground: Colors.white,
        primary: defaultPrimaryColor,
        // This is not darker, though lighter version
        primaryVariant: Color(0xff936bff),
        onPrimary: Colors.white,
        secondary: AppColors.grey,
        secondaryVariant: Colors.black,
        // todo: temporarily used for text in [NFButtons], remove when it's removed
        onSecondary: Colors.white,
        error: Color(0xffed3b3b),
        onError: Colors.white,
        /// For window headers (e.g. alert dialogs)
        surface: AppColors.grey,
        /// For dimmed text (e.g. in appbar)
        onSurface: AppColors.whiteDarkened,
      ),
      //****************** Specific app elements *****************
      scaffoldBackgroundColor: Colors.black,
      splashColor: defaultPrimaryColor,
      highlightColor: Colors.transparent,

      //****************** Themes *********************
      iconTheme: const IconThemeData(color: AppColors.whiteDarkened),
      tooltipTheme: const TooltipThemeData(
        verticalOffset: 20.0,
        textStyle: TextStyle(
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
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: defaultPrimaryColor,
        selectionColor: defaultPrimaryColor,
        selectionHandleColor: defaultPrimaryColor,
      ),
      textTheme: const TextTheme(
        /// See https://material.io/design/typography/the-type-system.html#type-scale
        button: TextStyle(fontWeight: FontWeight.w600),
        headline1: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        headline2: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        headline3: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        headline4: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        headline5: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        headline6: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 15.0,
        ),
        // Title in song tiles
        subtitle1: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        // Artist widget
        subtitle2: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white70,
          fontSize: 13.5,
          height: 0.9,
        ),
        bodyText1: TextStyle(fontWeight: FontWeight.w700),
        bodyText2: TextStyle(fontWeight: FontWeight.w600),
        overline: TextStyle(fontWeight: FontWeight.w600),
        caption: TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        brightness: Brightness.dark,
        color: AppColors.grey,
        elevation: 0.0,
        titleSpacing: 0.0,
        toolbarHeight: NFConstants.toolbarHeight,
        backwardsCompatibility: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 21.0,
          fontFamily: 'Roboto',
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
  const _ThemeContainer({required this.light, required this.dark});
  final T light;
  final T dark;

  /// Checks theme and automatically picks [light] or [dark] depending on current brightness.
  T get auto => ThemeControl.isDark ? dark : light;

  /// Checks theme and automatically picks opposite value from the current brightness.
  T get autoReverse => ThemeControl.isDark ? light : dark;

  _ThemeContainer<T> copyWith({T? light, T? dark}) {
    return _ThemeContainer(
      light: light ?? this.light,
      dark: dark ?? this.dark,
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
// import 'package:sweyer/sweyer.dart';

// import 'colors.dart';

// abstract class Theme {
//   static const Color defaultPrimaryColor = AppColors.deepPurpleAccent;

//   //************************************** WIDGET SPECIFIC COLORS ******************************************

//   static final _ThemeContainer<Color> sliderInactiveColor = _ThemeContainer(
//     light: Colors.black.withOpacity(0.2),
//     dark: Colors.white.withOpacity(0.2),
//   );

//   static const _ThemeContainer<Color> appBarBorderColor = _ThemeContainer(
//     light: AppColors.eee,
//     dark: Color(0xff191b1a),
//   );

//   static const  _ThemeContainer<Color> menuItemColor = _ThemeContainer(
//     light: Color(0xff3d3e42),
//     dark: Colors.white,
//   );

//   /// Color that contrasts with the [ColorScheme.background].
//   /// Black and white.
//   static const _ThemeContainer<Color> contrast = _ThemeContainer(
//     light: Colors.black,
//     dark: Colors.white,
//   );

//   static const _lightThemeSplashColor = Color(0x40cccccc);

//   /// Additional "glow" splash color aside of the one I put into the [ThemeData.splashColor],
//   /// that is the primary splash of the application (see [app]).
//   ///
//   /// In light mode it's the same as the mentioned above primary splash color.
//   ///
//   /// This color can be used instead of the [ThemeData.splashColor]
//   /// for creating splashes over sold colors (because otherwise splash will be indistinguishable from the color
//   /// it's drawn over).
//   ///
//   /// For example, it can be used for better look of splashes over the primary color in dark mode.
//   static final _ThemeContainer<Color> glowSplashColor = _ThemeContainer(
//     light: _lightThemeSplashColor,
//     dark: Colors.white.withOpacity(0.1),
//   );

//   /// A [glowSplashColor] to draw over [contrast].
//   static final _ThemeContainer<Color> glowSplashColorOnContrast = _ThemeContainer(
//     light: Colors.white.withOpacity(0.13),
//     dark: const Color(0x80cccccc),
//   );

//   static const Color _lightIconColor = Color(0xff616266);

//   static _ThemeContainer<ThemeData> app = _ThemeContainer(
//     light: ThemeData(
//       //******** General ********
//       fontFamily: 'Manrope',
//       brightness: Brightness.light,
//       //****************** Colors **********************
//       accentColor: Colors.white,
//       backgroundColor: Colors.white,
//       primaryColor: defaultPrimaryColor,
//       disabledColor: Colors.grey.shade400,
//       unselectedWidgetColor: Colors.grey.shade400,

//       //****************** Color scheme (preferable to colors) *********************
//       colorScheme: const ColorScheme(
//         brightness: Brightness.light,
//         background: Colors.white,
//         onBackground: AppColors.greyText,
//         primary: defaultPrimaryColor,
//         // This is not darker, though lighter version
//         primaryVariant: Color(0xff936bff),
//         onPrimary: Colors.white,
//         secondary: AppColors.eee,
//         secondaryVariant: Colors.white,
//         // todo: temporarily used for text in [NFButtons], remove when it's removed
//         onSecondary: defaultPrimaryColor,
//         error: Color(0xffed3b3b),
//         onError: Colors.white,
//         /// For window headers (e.g. alert dialogs)
//         surface: Colors.white,
//         /// For dimmed text (e.g. in appbar)
//         onSurface: _lightIconColor,
//       ),

//       //****************** Specific app elements *****************
//       scaffoldBackgroundColor: Colors.white,
//       splashColor: _lightThemeSplashColor,
//       splashFactory: NFListTileInkRipple.splashFactory,
//       highlightColor: Colors.transparent,

//       //****************** Themes *********************
//       iconTheme: const IconThemeData(color: _lightIconColor),
//       tooltipTheme: const TooltipThemeData(
//         verticalOffset: 20.0,
//         textStyle: TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w600,
//         ),
//         decoration: BoxDecoration(
//           color: defaultPrimaryColor,
//           borderRadius: BorderRadius.all(
//             Radius.circular(100.0),
//           ),
//         ),
//       ),
//       textSelectionTheme: const TextSelectionThemeData(
//         cursorColor: defaultPrimaryColor,
//         selectionColor: defaultPrimaryColor,
//         selectionHandleColor: defaultPrimaryColor,
//       ),
//       textButtonTheme: TextButtonThemeData(
//         style: ButtonStyle(
//           textStyle: MaterialStateProperty.all(
//             const TextStyle(
//               color: defaultPrimaryColor,
//               fontFamily: 'Manrope',
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ),
//       ),
//       buttonTheme: const ButtonThemeData(
//         textTheme: ButtonTextTheme.primary,
//       ),
//       textTheme: const TextTheme(
//         /// See https://material.io/design/typography/the-type-system.html#type-scale
//         button: TextStyle(fontWeight: FontWeight.w600),
//         headline1: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
//         headline2: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
//         headline3: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
//         headline4: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
//         headline5: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey),
//         // Title in song tiles
//         headline6: TextStyle(
//           fontWeight: FontWeight.w700,
//           color: AppColors.greyText,
//           fontSize: 15.0,
//         ),
//         subtitle1: TextStyle(
//           fontWeight: FontWeight.w600,
//           color: AppColors.grey,
//         ),
//         // Artist widget
//         subtitle2: TextStyle(
//           fontWeight: FontWeight.w600,
//           color: Colors.black54,
//           fontSize: 13.5,
//           height: 0.9,
//         ),
//         bodyText1: TextStyle(fontWeight: FontWeight.w700),
//         bodyText2: TextStyle(fontWeight: FontWeight.w600),
//         overline: TextStyle(fontWeight: FontWeight.w600),
//         caption: TextStyle(fontWeight: FontWeight.w600),
//       ),
//       appBarTheme: const AppBarTheme(
//         brightness: Brightness.light,
//         elevation: 0.0,
//         color: AppColors.eee,
//         textTheme: TextTheme(
//           headline6: TextStyle(
//             color: AppColors.greyText,
//             fontWeight: FontWeight.w600,
//             fontSize: 20.0,
//           ),
//         ),
//       ),
//       bottomSheetTheme: const BottomSheetThemeData(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(10),
//             topRight: Radius.circular(10),
//           ),
//         ),
//         backgroundColor: Colors.white,
//       ),
//     ),
//     dark: ThemeData(
//       //******** General ********
//       fontFamily: 'Manrope',
//       brightness: Brightness.dark,
//       //****************** Colors **********************
//       // accentColor: AppColors.grey,
//       accentColor: Colors.red,
//       backgroundColor: Colors.black,
//       primaryColor: defaultPrimaryColor,
//       disabledColor: Colors.grey.shade800,
//       unselectedWidgetColor: Colors.grey.shade800,

//       //****************** Color scheme (preferable to colors) *********************
//       colorScheme: const ColorScheme(
//         brightness: Brightness.dark,
//         background: Colors.black,
//         onBackground: Colors.white,
//         primary: defaultPrimaryColor,
//         // This is not darker, though lighter version
//         primaryVariant: Color(0xff936bff),
//         onPrimary: Colors.white,
//         secondary: AppColors.grey,
//         secondaryVariant: Colors.black,
//         // todo: temporarily used for text in [NFButtons], remove when it's removed
//         onSecondary: Colors.white,
//         error: Color(0xffed3b3b),
//         onError: Colors.white,
//         /// For window headers (e.g. alert dialogs)
//         surface: AppColors.grey,
//         /// For dimmed text (e.g. in appbar)
//         onSurface: AppColors.whiteDarkened,
//       ),
//       //****************** Specific app elements *****************
//       scaffoldBackgroundColor: Colors.black,
//       splashColor: defaultPrimaryColor,
//       highlightColor: Colors.transparent,

//       //****************** Themes *********************
//       iconTheme: const IconThemeData(color: AppColors.whiteDarkened),
//       tooltipTheme: const TooltipThemeData(
//         verticalOffset: 20.0,
//         textStyle: TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w600,
//         ),
//         decoration: BoxDecoration(
//           color: defaultPrimaryColor,
//           borderRadius: BorderRadius.all(
//             Radius.circular(100.0),
//           ),
//         ),
//       ),
//       textSelectionTheme: const TextSelectionThemeData(
//         cursorColor: defaultPrimaryColor,
//         selectionColor: defaultPrimaryColor,
//         selectionHandleColor: defaultPrimaryColor,
//       ),
//       textTheme: const TextTheme(
//         /// See https://material.io/design/typography/the-type-system.html#type-scale
//         button: TextStyle(fontWeight: FontWeight.w600),
//         headline1: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
//         headline2: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
//         headline3: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
//         headline4: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
//         headline5: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
//         headline6: TextStyle(
//           fontWeight: FontWeight.w700,
//           color: Colors.white,
//           fontSize: 15.0,
//         ),
//         // Title in song tiles
//         subtitle1: TextStyle(
//           fontWeight: FontWeight.w600,
//           color: Colors.white,
//         ),
//         // Artist widget
//         subtitle2: TextStyle(
//           fontWeight: FontWeight.w600,
//           color: Colors.white70,
//           fontSize: 13.5,
//           height: 0.9,
//         ),
//         bodyText1: TextStyle(fontWeight: FontWeight.w700),
//         bodyText2: TextStyle(fontWeight: FontWeight.w600),
//         overline: TextStyle(fontWeight: FontWeight.w600),
//         caption: TextStyle(fontWeight: FontWeight.w600),
//       ),
//       appBarTheme: const AppBarTheme(
//         brightness: Brightness.dark,
//         color: AppColors.grey,
//         elevation: 0.0,
//         textTheme: TextTheme(
//           headline6: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: 20.0,
//           ),
//         ),
//       ),
//       bottomSheetTheme: const BottomSheetThemeData(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(10),
//             topRight: Radius.circular(10),
//           ),
//         ),
//         backgroundColor: Color(0xff070707),
//       ),
//     ),
//   );
// }

// abstract class UiTheme {
//   /// Default theme for all screens.
//   ///
//   /// Theme where nav bar is [black] (with default dark theme).
//   /// For light this means [white].
//   ///
//   /// The opposite is [grey].
//   static final _ThemeContainer<SystemUiOverlayStyle> black = _ThemeContainer(
//     /// [withOpacity] needed for smooth transtion to [drawerScreen].
//     light: SystemUiOverlayStyle(
//       systemNavigationBarColor: Colors.white,
//       systemNavigationBarDividerColor: Colors.transparent,
//       systemNavigationBarIconBrightness: Brightness.dark,
//       statusBarColor: Colors.white.withOpacity(0.0),
//       statusBarBrightness: Brightness.dark,
//       statusBarIconBrightness: Brightness.dark,
//     ),
//     dark: SystemUiOverlayStyle(
//       systemNavigationBarColor: Colors.black,
//       systemNavigationBarDividerColor: Colors.transparent,
//       systemNavigationBarIconBrightness: Brightness.light,
//       statusBarColor: AppColors.grey.withOpacity(0.0),
//       statusBarBrightness: Brightness.light,
//       statusBarIconBrightness: Brightness.light,
//     ),
//   );

//   /// Theme where nav bar is [grey] (with default dark theme).
//   /// For light this means [eee].
//   ///
//   /// The opposite is [black].
//   static final _ThemeContainer<SystemUiOverlayStyle> grey = _ThemeContainer(
//     light: black.light.copyWith(systemNavigationBarColor: AppColors.eee),
//     dark: black.dark.copyWith(systemNavigationBarColor: AppColors.grey),
//   );

//   /// Theme for the drawer screen.
//   static final _ThemeContainer<SystemUiOverlayStyle> drawerScreen =
//       _ThemeContainer(
//     light: black.light.copyWith(
//       statusBarColor: Colors.white,
//       systemNavigationBarColor: Colors.white,
//     ),
//     dark: black.dark.copyWith(
//       statusBarColor: AppColors.grey,
//       systemNavigationBarColor: AppColors.grey,
//     ),
//   );

//   /// Theme for the bottom sheet dialog.
//   static final _ThemeContainer<SystemUiOverlayStyle> bottomSheet =
//       _ThemeContainer(
//     light: black.light.copyWith(
//       systemNavigationBarColor: Colors.white,
//       statusBarBrightness: Brightness.light,
//       statusBarIconBrightness: Brightness.light,
//     ),
//     dark: black.dark.copyWith(
//       systemNavigationBarColor: Colors.black,
//     ),
//   );

//   /// Theme for the modal dialog.
//   static final _ThemeContainer<SystemUiOverlayStyle> modal = _ThemeContainer(
//     light: black.light.copyWith(
//       systemNavigationBarColor: const Color(0xff757575),
//       systemNavigationBarIconBrightness: Brightness.light,
//       statusBarBrightness: Brightness.light,
//       statusBarIconBrightness: Brightness.light,
//     ),
//     dark: black.dark.copyWith(
//       statusBarColor: Colors.black,
//     ),
//   );

//   /// Theme for the modal dialog that is displayed over [grey].
//   static final _ThemeContainer<SystemUiOverlayStyle> modalOverGrey =
//       _ThemeContainer(
//     light: modal.light.copyWith(
//       systemNavigationBarColor: const Color(0xff6d6d6d),
//     ),
//     dark: modal.dark.copyWith(
//       systemNavigationBarColor: const Color(0xff0d0d0d),
//     ),
//   );
// }

// /// Class to wrap some values, so they will have [light] and [dark] variants.
// class _ThemeContainer<T> {
//   const _ThemeContainer({@required this.light, @required this.dark});
//   final T light;
//   final T dark;

//   /// Checks theme and automatically picks [light] or [dark] depending on current brightness.
//   T get auto => ThemeControl.isDark ? dark : light;

//   /// Checks theme and automatically picks opposite value from the current brightness.
//   T get autoReverse => ThemeControl.isDark ? light : dark;

//   _ThemeContainer<T> copyWith({T light, T dark}) {
//     return _ThemeContainer(
//       light: light ?? this.light,
//       dark: dark ?? this.dark,
//     );
//   }
// }
