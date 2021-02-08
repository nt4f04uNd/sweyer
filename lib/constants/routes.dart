/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

enum Routes { home, settings, dev, unknown }

extension RouteExtension on Routes {
  /// Returns string route path, like `'/settings'`
  String get value {
    switch (this) {
      case Routes.home:
        return '/';
      case Routes.settings:
        return '/settings';
      case Routes.dev:
        return '/dev';
      case Routes.unknown:
        return '/unknown';
      default:
        assert(false);
        return null;
    }
  }
}

enum HomeRoutes { tabs, search, album }

extension HomeRouteExtension on HomeRoutes {
  /// Returns string route path, like `'/settings'`
  String get value {
    switch (this) {
      case HomeRoutes.tabs:
        return '/tabs';
      case HomeRoutes.search:
        return '/search';
      case HomeRoutes.album:
        return '/album';
      default:
        assert(false);
        return null;
    }
  }
}
