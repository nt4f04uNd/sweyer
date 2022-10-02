// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_element

part of 'player_route_theme.dart';

// **************************************************************************
// ThemeTailorGenerator
// **************************************************************************

class PlayerRouteTheme extends ThemeExtension<PlayerRouteTheme> {
  const PlayerRouteTheme({
    required this.wow,
  });

  final dynamic wow;

  static final PlayerRouteTheme light = PlayerRouteTheme(
    wow: _$PlayerRouteTheme.wow[0],
  );

  static final PlayerRouteTheme dark = PlayerRouteTheme(
    wow: _$PlayerRouteTheme.wow[1],
  );

  static final themes = [
    light,
    dark,
  ];

  @override
  PlayerRouteTheme copyWith({
    dynamic wow,
  }) {
    return PlayerRouteTheme(
      wow: wow ?? this.wow,
    );
  }

  @override
  PlayerRouteTheme lerp(ThemeExtension<PlayerRouteTheme>? other, double t) {
    if (other is! PlayerRouteTheme) return this;
    return PlayerRouteTheme(
      wow: t < 0.5 ? wow : other.wow,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlayerRouteTheme &&
            const DeepCollectionEquality().equals(wow, other.wow));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, const DeepCollectionEquality().hash(wow));
  }
}

extension PlayerRouteThemeBuildContextProps on BuildContext {
  PlayerRouteTheme get _playerRouteTheme =>
      Theme.of(this).extension<PlayerRouteTheme>()!;
  dynamic get wow => _playerRouteTheme.wow;
}
