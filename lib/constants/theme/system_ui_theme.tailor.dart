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
    required this.grey,
    required this.drawerScreen,
    required this.bottomSheet,
    required this.modal,
    required this.modalOverGrey,
  });

  final SystemUiOverlayStyle black;
  final SystemUiOverlayStyle grey;
  final SystemUiOverlayStyle drawerScreen;
  final SystemUiOverlayStyle bottomSheet;
  final SystemUiOverlayStyle modal;
  final SystemUiOverlayStyle modalOverGrey;

  static final SystemUiTheme light = SystemUiTheme(
    black: _$SystemUiTheme.black[0],
    grey: _$SystemUiTheme.grey[0],
    drawerScreen: _$SystemUiTheme.drawerScreen[0],
    bottomSheet: _$SystemUiTheme.bottomSheet[0],
    modal: _$SystemUiTheme.modal[0],
    modalOverGrey: _$SystemUiTheme.modalOverGrey[0],
  );

  static final SystemUiTheme dark = SystemUiTheme(
    black: _$SystemUiTheme.black[1],
    grey: _$SystemUiTheme.grey[1],
    drawerScreen: _$SystemUiTheme.drawerScreen[1],
    bottomSheet: _$SystemUiTheme.bottomSheet[1],
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
    SystemUiOverlayStyle? grey,
    SystemUiOverlayStyle? drawerScreen,
    SystemUiOverlayStyle? bottomSheet,
    SystemUiOverlayStyle? modal,
    SystemUiOverlayStyle? modalOverGrey,
  }) {
    return SystemUiTheme(
      black: black ?? this.black,
      grey: grey ?? this.grey,
      drawerScreen: drawerScreen ?? this.drawerScreen,
      bottomSheet: bottomSheet ?? this.bottomSheet,
      modal: modal ?? this.modal,
      modalOverGrey: modalOverGrey ?? this.modalOverGrey,
    );
  }

  @override
  SystemUiTheme lerp(ThemeExtension<SystemUiTheme>? other, double t) {
    if (other is! SystemUiTheme) return this;
    return SystemUiTheme(
      black: t < 0.5 ? black : other.black,
      grey: t < 0.5 ? grey : other.grey,
      drawerScreen: t < 0.5 ? drawerScreen : other.drawerScreen,
      bottomSheet: t < 0.5 ? bottomSheet : other.bottomSheet,
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
            const DeepCollectionEquality().equals(grey, other.grey) &&
            const DeepCollectionEquality()
                .equals(drawerScreen, other.drawerScreen) &&
            const DeepCollectionEquality()
                .equals(bottomSheet, other.bottomSheet) &&
            const DeepCollectionEquality().equals(modal, other.modal) &&
            const DeepCollectionEquality()
                .equals(modalOverGrey, other.modalOverGrey));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(black),
        const DeepCollectionEquality().hash(grey),
        const DeepCollectionEquality().hash(drawerScreen),
        const DeepCollectionEquality().hash(bottomSheet),
        const DeepCollectionEquality().hash(modal),
        const DeepCollectionEquality().hash(modalOverGrey));
  }
}

extension SystemUiThemeBuildContextProps on BuildContext {
  SystemUiTheme get _systemUiTheme =>
      Theme.of(this).extension<SystemUiTheme>()!;
  SystemUiOverlayStyle get black => _systemUiTheme.black;
  SystemUiOverlayStyle get grey => _systemUiTheme.grey;
  SystemUiOverlayStyle get drawerScreen => _systemUiTheme.drawerScreen;
  SystemUiOverlayStyle get bottomSheet => _systemUiTheme.bottomSheet;
  SystemUiOverlayStyle get modal => _systemUiTheme.modal;
  SystemUiOverlayStyle get modalOverGrey => _systemUiTheme.modalOverGrey;
}
