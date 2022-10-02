import 'package:flutter/material.dart';
import 'package:sweyer/constants/constants.dart';
import 'package:sweyer/sweyer.dart';

export 'app_theme.dart';
export 'system_ui_theme.dart';

abstract class Theme {
  static const Color defaultPrimaryColor = AppColors.deepPurpleAccent;

  static const lightThemeSplashColor = Color(0x40cccccc);
  static const Color _lightIconColor = Color(0xff616266);

  static ThemeContainer<ThemeData> app = ThemeContainer(
    light: ThemeData(
      extensions: [
        AppTheme.light,
        SystemUiTheme.light,
      ],
      //******** General ********
      fontFamily: 'Manrope',
      brightness: Brightness.light,
      //****************** Colors **********************
      backgroundColor: Colors.white,
      primaryColor: defaultPrimaryColor,
      disabledColor: Colors.grey.shade400,
      unselectedWidgetColor: Colors.grey.shade400,
      toggleableActiveColor: defaultPrimaryColor,

      //****************** Color scheme (preferable to colors) *********************
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        background: Colors.white,
        onBackground: AppColors.greyText,
        primary: defaultPrimaryColor,
        // This is not darker, though lighter version
        primaryContainer: Color(0xff936bff),
        onPrimary: Colors.white,
        secondary: AppColors.eee,
        secondaryContainer: Colors.white,
        // todo: temporarily used for text in [AppButton], remove when ThemeExtensions are in place
        onSecondary: defaultPrimaryColor,
        error: Color(0xffed3b3b),
        onError: Colors.white,
        // For window headers (e.g. alert dialogs)
        surface: Colors.white,
        // For dimmed text (e.g. in appbar)
        onSurface: _lightIconColor,
      ),

      //****************** Specific app elements *****************
      scaffoldBackgroundColor: Colors.white,
      splashColor: lightThemeSplashColor,
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
          height: 1,
        ),
        bodyText1: TextStyle(fontWeight: FontWeight.w700),
        bodyText2: TextStyle(fontWeight: FontWeight.w600),
        overline: TextStyle(fontWeight: FontWeight.w600),
        caption: TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 2.0,
        titleSpacing: 0.0,
        toolbarHeight: NFConstants.toolbarHeight,
        color: AppColors.eee,
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
      extensions: [
        AppTheme.dark,
        SystemUiTheme.dark,
      ],
      //******** General ********
      fontFamily: 'Manrope',
      brightness: Brightness.dark,
      //****************** Colors **********************
      backgroundColor: Colors.black,
      primaryColor: defaultPrimaryColor,
      disabledColor: Colors.grey.shade800,
      unselectedWidgetColor: Colors.grey.shade800,
      toggleableActiveColor: defaultPrimaryColor,

      //****************** Color scheme (preferable to colors) *********************
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        background: Colors.black,
        onBackground: Colors.white,
        primary: defaultPrimaryColor,
        // This is not darker, though lighter version
        primaryContainer: Color(0xff936bff),
        onPrimary: Colors.white,
        secondary: AppColors.grey,
        secondaryContainer: Colors.black,
        // todo: temporarily used for text in [AppButton], remove when ThemeExtensions are in place
        onSecondary: Colors.white,
        error: Color(0xffed3b3b),
        onError: Colors.white,
        // For window headers (e.g. alert dialogs)
        surface: AppColors.grey,
        // For dimmed text (e.g. in appbar)
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
          height: 1,
        ),
        bodyText1: TextStyle(fontWeight: FontWeight.w700),
        bodyText2: TextStyle(fontWeight: FontWeight.w600),
        overline: TextStyle(fontWeight: FontWeight.w600),
        caption: TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        color: AppColors.grey,
        elevation: 0.0,
        titleSpacing: 0.0,
        toolbarHeight: NFConstants.toolbarHeight,
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

/// Class to wrap some values, so they will have [light] and [dark] variants.
class ThemeContainer<T> {
  const ThemeContainer({required this.light, required this.dark});
  final T light;
  final T dark;

  /// Checks theme and automatically picks [light] or [dark] depending on current brightness.
  T get auto => ThemeControl.instance.isDark ? dark : light;

  /// Checks theme and automatically picks opposite value from the current brightness.
  T get autoReverse => ThemeControl.instance.isDark ? light : dark;

  ThemeContainer<T> copyWith({T? light, T? dark}) {
    return ThemeContainer(
      light: light ?? this.light,
      dark: dark ?? this.dark,
    );
  }
}
