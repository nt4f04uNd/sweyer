enum Routes { main, settings,extendedSettings, player, exif, search }

extension RouteExtension on Routes {
  /// Returns string route path, like `'/settings'`
  String get value {
    switch (this) {
      case Routes.main:
        return "/";
      case Routes.settings:
        return "/settings";
      case Routes.extendedSettings:
        return "/extendedSettings";
      case Routes.player:
        return "/player";
      case Routes.exif:
        return "/exif";
      case Routes.search:
        return "/search";
      default:
        return null;
    }
  }
}