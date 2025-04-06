// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_element, unnecessary_cast

part of 'system_ui_theme.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$SystemUiThemeTailorMixin on ThemeExtension<SystemUiTheme> {
  SystemUiOverlayStyle get grey;
  SystemUiOverlayStyle get black;
  SystemUiOverlayStyle get drawerScreen;
  SystemUiOverlayStyle get bottomSheet;
  SystemUiOverlayStyle get modal;
  Color get modalOverGreySystemNavigationBarColor;
  SystemUiOverlayStyle get modalOverGrey;

  @override
  SystemUiTheme copyWith({
    SystemUiOverlayStyle? grey,
    SystemUiOverlayStyle? black,
    SystemUiOverlayStyle? drawerScreen,
    SystemUiOverlayStyle? bottomSheet,
    SystemUiOverlayStyle? modal,
    Color? modalOverGreySystemNavigationBarColor,
    SystemUiOverlayStyle? modalOverGrey,
  }) {
    return SystemUiTheme(
      grey: grey ?? this.grey,
      black: black ?? this.black,
      drawerScreen: drawerScreen ?? this.drawerScreen,
      bottomSheet: bottomSheet ?? this.bottomSheet,
      modal: modal ?? this.modal,
      modalOverGreySystemNavigationBarColor:
          modalOverGreySystemNavigationBarColor ?? this.modalOverGreySystemNavigationBarColor,
    );
  }

  @override
  SystemUiTheme lerp(covariant ThemeExtension<SystemUiTheme>? other, double t) {
    if (other is! SystemUiTheme) return this as SystemUiTheme;
    return SystemUiTheme(
      grey: t < 0.5 ? grey : other.grey,
      black: t < 0.5 ? black : other.black,
      drawerScreen: t < 0.5 ? drawerScreen : other.drawerScreen,
      bottomSheet: t < 0.5 ? bottomSheet : other.bottomSheet,
      modal: t < 0.5 ? modal : other.modal,
      modalOverGreySystemNavigationBarColor:
          Color.lerp(modalOverGreySystemNavigationBarColor, other.modalOverGreySystemNavigationBarColor, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SystemUiTheme &&
            const DeepCollectionEquality().equals(grey, other.grey) &&
            const DeepCollectionEquality().equals(black, other.black) &&
            const DeepCollectionEquality().equals(drawerScreen, other.drawerScreen) &&
            const DeepCollectionEquality().equals(bottomSheet, other.bottomSheet) &&
            const DeepCollectionEquality().equals(modal, other.modal) &&
            const DeepCollectionEquality()
                .equals(modalOverGreySystemNavigationBarColor, other.modalOverGreySystemNavigationBarColor) &&
            const DeepCollectionEquality().equals(modalOverGrey, other.modalOverGrey));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(grey),
      const DeepCollectionEquality().hash(black),
      const DeepCollectionEquality().hash(drawerScreen),
      const DeepCollectionEquality().hash(bottomSheet),
      const DeepCollectionEquality().hash(modal),
      const DeepCollectionEquality().hash(modalOverGreySystemNavigationBarColor),
      const DeepCollectionEquality().hash(modalOverGrey),
    );
  }
}

extension SystemUiThemeBuildContextProps on BuildContext {
  SystemUiTheme get systemUiTheme => Theme.of(this).extension<SystemUiTheme>()!;

  /// Theme where nav bar is [grey] (with default dark theme).
  /// For light this means [eee].
  ///
  /// The opposite is [black].
  SystemUiOverlayStyle get grey => systemUiTheme.grey;

  /// Default theme for all screens.
  ///
  /// Theme where nav bar is [black] (with default dark theme).
  /// For light this means [white].
  ///
  /// The opposite is [grey].
  SystemUiOverlayStyle get black => systemUiTheme.black;

  /// Theme for the drawer screen.
  SystemUiOverlayStyle get drawerScreen => systemUiTheme.drawerScreen;

  /// Theme for the bottom sheet dialog.
  SystemUiOverlayStyle get bottomSheet => systemUiTheme.bottomSheet;

  /// Theme for the modal dialog.
  SystemUiOverlayStyle get modal => systemUiTheme.modal;
  Color get modalOverGreySystemNavigationBarColor => systemUiTheme.modalOverGreySystemNavigationBarColor;
  SystemUiOverlayStyle get modalOverGrey => systemUiTheme.modalOverGrey;
}
