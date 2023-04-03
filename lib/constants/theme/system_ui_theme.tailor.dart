// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_element

part of 'system_ui_theme.dart';

// **************************************************************************
// ThemeTailorGenerator
// **************************************************************************

class SystemUiTheme extends ThemeExtension<SystemUiTheme> {
  const SystemUiTheme({
    required this.black,
    required this.bottomSheet,
    required this.drawerScreen,
    required this.grey,
    required this.modal,
    required this.modalOverGrey,
  });

  /// Default theme for all screens.
  ///
  /// Theme where nav bar is [black] (with default dark theme).
  /// For light this means [white].
  ///
  /// The opposite is [grey].
  final SystemUiOverlayStyle black;

  /// Theme for the bottom sheet dialog.
  final SystemUiOverlayStyle bottomSheet;

  /// Theme for the drawer screen.
  final SystemUiOverlayStyle drawerScreen;

  /// Theme where nav bar is [grey] (with default dark theme).
  /// For light this means [eee].
  ///
  /// The opposite is [black].
  final SystemUiOverlayStyle grey;

  /// Theme for the modal dialog.
  final SystemUiOverlayStyle modal;

  /// Theme for the modal dialog that is displayed over [grey].
  final SystemUiOverlayStyle modalOverGrey;

  static final SystemUiTheme light = SystemUiTheme(
    black: _$SystemUiTheme.black[0],
    bottomSheet: _$SystemUiTheme.bottomSheet[0],
    drawerScreen: _$SystemUiTheme.drawerScreen[0],
    grey: _$SystemUiTheme.grey[0],
    modal: _$SystemUiTheme.modal[0],
    modalOverGrey: _$SystemUiTheme.modalOverGrey[0],
  );

  static final SystemUiTheme dark = SystemUiTheme(
    black: _$SystemUiTheme.black[1],
    bottomSheet: _$SystemUiTheme.bottomSheet[1],
    drawerScreen: _$SystemUiTheme.drawerScreen[1],
    grey: _$SystemUiTheme.grey[1],
    modal: _$SystemUiTheme.modal[1],
    modalOverGrey: _$SystemUiTheme.modalOverGrey[1],
  );

  static final themes = [
    light,
    dark,
  ];

  @override
  SystemUiTheme copyWith({
    SystemUiOverlayStyle? black,
    SystemUiOverlayStyle? bottomSheet,
    SystemUiOverlayStyle? drawerScreen,
    SystemUiOverlayStyle? grey,
    SystemUiOverlayStyle? modal,
    SystemUiOverlayStyle? modalOverGrey,
  }) {
    return SystemUiTheme(
      black: black ?? this.black,
      bottomSheet: bottomSheet ?? this.bottomSheet,
      drawerScreen: drawerScreen ?? this.drawerScreen,
      grey: grey ?? this.grey,
      modal: modal ?? this.modal,
      modalOverGrey: modalOverGrey ?? this.modalOverGrey,
    );
  }

  @override
  SystemUiTheme lerp(ThemeExtension<SystemUiTheme>? other, double t) {
    if (other is! SystemUiTheme) return this;
    return SystemUiTheme(
      black: t < 0.5 ? black : other.black,
      bottomSheet: t < 0.5 ? bottomSheet : other.bottomSheet,
      drawerScreen: t < 0.5 ? drawerScreen : other.drawerScreen,
      grey: t < 0.5 ? grey : other.grey,
      modal: t < 0.5 ? modal : other.modal,
      modalOverGrey: t < 0.5 ? modalOverGrey : other.modalOverGrey,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SystemUiTheme &&
            const DeepCollectionEquality().equals(black, other.black) &&
            const DeepCollectionEquality().equals(bottomSheet, other.bottomSheet) &&
            const DeepCollectionEquality().equals(drawerScreen, other.drawerScreen) &&
            const DeepCollectionEquality().equals(grey, other.grey) &&
            const DeepCollectionEquality().equals(modal, other.modal) &&
            const DeepCollectionEquality().equals(modalOverGrey, other.modalOverGrey));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(black),
        const DeepCollectionEquality().hash(bottomSheet),
        const DeepCollectionEquality().hash(drawerScreen),
        const DeepCollectionEquality().hash(grey),
        const DeepCollectionEquality().hash(modal),
        const DeepCollectionEquality().hash(modalOverGrey));
  }
}

extension SystemUiThemeBuildContextProps on BuildContext {
  SystemUiTheme get _systemUiTheme => Theme.of(this).extension<SystemUiTheme>()!;

  /// Default theme for all screens.
  ///
  /// Theme where nav bar is [black] (with default dark theme).
  /// For light this means [white].
  ///
  /// The opposite is [grey].
  SystemUiOverlayStyle get black => _systemUiTheme.black;

  /// Theme for the bottom sheet dialog.
  SystemUiOverlayStyle get bottomSheet => _systemUiTheme.bottomSheet;

  /// Theme for the drawer screen.
  SystemUiOverlayStyle get drawerScreen => _systemUiTheme.drawerScreen;

  /// Theme where nav bar is [grey] (with default dark theme).
  /// For light this means [eee].
  ///
  /// The opposite is [black].
  SystemUiOverlayStyle get grey => _systemUiTheme.grey;

  /// Theme for the modal dialog.
  SystemUiOverlayStyle get modal => _systemUiTheme.modal;

  /// Theme for the modal dialog that is displayed over [grey].
  SystemUiOverlayStyle get modalOverGrey => _systemUiTheme.modalOverGrey;
}
