/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

enum Routes { main, settings, extendedSettings, player, exif, search, debug, unknown }

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
      case Routes.debug:
        return "/debug";
      case Routes.unknown:
        return "/unknown";
      default:
        return null;
    }
  }
}
