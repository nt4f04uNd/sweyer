/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/


export 'home_route/home_route.dart';
export 'settings_route/settings_route.dart';
export 'dev_route.dart';

import 'package:flutter/material.dart' hide LicensePage, SearchDelegate;
import 'package:equatable/equatable.dart';
import 'package:sweyer/routes/settings_route/theme_settings.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';

import 'home_route/home_route.dart';
import 'settings_route/settings_route.dart';
import 'settings_route/licenses_route.dart';
import 'dev_route.dart';

final RouteObserver<Route> routeObserver = RouteObserver();
final RouteObserver<Route> homeRouteObserver = RouteObserver();

abstract class _Routes<T extends Object> extends Equatable {
  const _Routes(this.location, [this.arguments]);

  final String location;
  final T arguments;

  /// Value key to pass in to the [Page].
  ValueKey<String> get key => ValueKey(location);

  @override
  List<Object> get props => [location];
}

class AppRoutes<T extends Object> extends _Routes<T> {
  const AppRoutes._(String location, [T arguments]) : super(location, arguments);

  static const initial = AppRoutes<void>._('/');
  static const settings = AppRoutes<void>._('/settings');
  static const themeSettings = AppRoutes<void>._('/settings/theme');
  static const licenses = AppRoutes<void>._('/settings/licenses');
  static const dev = AppRoutes<void>._('/dev');
}

class HomeRoutes<T extends Object> extends _Routes<T> {
  const HomeRoutes._(String location, [T arguments]) : super(location, arguments);

  static const tabs = HomeRoutes<void>._('/tabs');
  static const album = HomeRoutes<Album>._('/album');
  static const search = HomeRoutes<SearchArguments>._('/search');

  /// Returns a factory to create routes with arguments.
  static const factory = _HomeRoutesFactory();
}

class _HomeRoutesFactory {
  const _HomeRoutesFactory();

  HomeRoutes<Album> album(Album album) => HomeRoutes._('/album', album);
  HomeRoutes<SearchArguments> search(SearchArguments arguments) => HomeRoutes._('/search', arguments);
}

class SearchArguments {
  const SearchArguments({
    this.query = '',
    this.openKeyboard = true
  });

  final String query;
  final bool openKeyboard;
}


class AppRouteInformationParser extends RouteInformationParser<AppRoutes> {
  @override
  Future<AppRoutes> parseRouteInformation(RouteInformation routeInformation) async {
    return AppRoutes._(routeInformation.location);
  }

  @override
  RouteInformation restoreRouteInformation(AppRoutes configuration) {
    return RouteInformation(location: configuration.location);
  }
}

class HomeRouteInformationParser extends RouteInformationParser<HomeRoutes> {
  @override
  Future<HomeRoutes> parseRouteInformation(RouteInformation routeInformation) async {
    return HomeRoutes._(routeInformation.location);
  }

  @override
  RouteInformation restoreRouteInformation(HomeRoutes configuration) {
    return RouteInformation(location: configuration.location);
  }
}

mixin _DelegateMixin<T extends _Routes> on RouterDelegate<T>, ChangeNotifier {
  List<T> get _routes;
  List<T> get routes => List.unmodifiable(_routes);

  /// Goes to some route.
  ///
  /// If route already in the stack, removes all routes on top of it.
  void goto(T route) {
    final index = _routes.indexOf(route);
    if (index > 0) {
      for (int i = index + 1; i < _routes.length; i++) {
        _routes.remove(_routes[i]);
      }
    } else {
      _routes.add(route);
    }
    notifyListeners();
  }

  bool _handlePopPage(Route<dynamic> route, dynamic result) {
    final bool success = route.didPop(result);
    if (success) {
      if (_routes.length <= 1) {
        assert(false, "Can't pop inital route");
      } else {
        _routes.removeLast();
      }
      notifyListeners();
    }
    return success;
  }
}

class _TransitionSettings {
  _TransitionSettings({
    @required this.grey,
    @required this.greyDismissible,
    @required this.dismissible,
    @required this.initial,
    @required this.theme,
  });
  
  /// Used on [HomeRouter] routes that cannot be dismissed.
  final StackFadeRouteTransitionSettings grey;
  /// Used on [HomeRouter] routes that can be dismissed.
  final StackFadeRouteTransitionSettings greyDismissible;
  /// Used by default on routes that can be dismissed.
  final StackFadeRouteTransitionSettings dismissible;
  /// Used on [InitialRoute] to switch its UI style.
  final StackFadeRouteTransitionSettings initial;
  /// Used on theme settings route to disable dimissing while theme is chaning.
  final StackFadeRouteTransitionSettings theme;
}

class AppRouter extends RouterDelegate<AppRoutes>
  with ChangeNotifier,
       _DelegateMixin,
       PopNavigatorRouterDelegateMixin {

  AppRouter._();
  static final instance = AppRouter._();

  final List<AppRoutes> __routes = [AppRoutes.initial];
  @override
  List<AppRoutes> get _routes => __routes;

  // for web applicatiom
  @override
  AppRoutes get currentConfiguration => _routes.last;

  @override
  Future<void> setNewRoutePath(AppRoutes configuration) async { }
         
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  
  final _TransitionSettings transitionSettings = _TransitionSettings(
    grey: StackFadeRouteTransitionSettings(uiStyle: Constants.UiTheme.grey.auto),
    greyDismissible: StackFadeRouteTransitionSettings(
      opaque: false,
      dismissible: true,
      dismissBarrier: _dismissBarrier,
      uiStyle: Constants.UiTheme.grey.auto,
    ),
    dismissible: StackFadeRouteTransitionSettings(
      opaque: false,
      dismissible: true,
      dismissBarrier: _dismissBarrier,
    ),
    initial: StackFadeRouteTransitionSettings(),
    theme: StackFadeRouteTransitionSettings(
      opaque: false,
      dismissible: true,
      dismissBarrier: _dismissBarrier,
    ),
  );
  
  static Widget get _dismissBarrier => Container(
    color: ThemeControl.isDark ? Colors.black54 : Colors.black26,
  );

  bool _mainScreenShown = false;
  /// Controls the ui style that will be applied to home screen.
  set mainScreenShown(bool value) {
    _mainScreenShown = value;
    updateTransitionSettings();
  }

  void updateTransitionSettings({bool themeChanged = false}) {
    final dismissBarrier = _dismissBarrier;
    transitionSettings.grey.uiStyle = Constants.UiTheme.grey.auto;
    transitionSettings.greyDismissible.uiStyle = Constants.UiTheme.grey.auto;
    transitionSettings.greyDismissible.dismissBarrier = dismissBarrier;
    transitionSettings.dismissible.dismissBarrier = dismissBarrier;
    transitionSettings.initial.uiStyle = _mainScreenShown
      ? Constants.UiTheme.grey.auto
      : Constants.UiTheme.black.auto;
    transitionSettings.theme.dismissBarrier = dismissBarrier;
    if (themeChanged) {
      transitionSettings.theme.dismissible = false;
      Future.delayed(dilate(const Duration(milliseconds: 300)), () {
        transitionSettings.theme.dismissible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      observers: [routeObserver],
      onPopPage: _handlePopPage,
      pages: <Page<void>>[
        StackFadePage(
          key: AppRoutes.initial.key,
          child: const InitialRoute(),
          transitionSettings: transitionSettings.initial,
        ),
        if (_routes.length > 1 && _routes[1] == AppRoutes.settings)
          StackFadePage(
            key: AppRoutes.settings.key,
            child: const SettingsRoute(),
            transitionSettings: transitionSettings.dismissible,
          ),
        if (_routes.length > 2 && _routes[2] == AppRoutes.themeSettings)
          StackFadePage(
            key: AppRoutes.themeSettings.key,
            child: const ThemeSettingsRoute(),
            transitionSettings: transitionSettings.theme,
          ),
        if (_routes.length > 2 && _routes[2] == AppRoutes.licenses)
          StackFadePage(
            key: AppRoutes.licenses.key,
            child: const LicensePage(),
            transitionSettings: transitionSettings.dismissible,
          ),
        if (_routes.length > 1 && _routes[1] == AppRoutes.dev)
          StackFadePage(
            key: AppRoutes.dev.key,
            child: const DevRoute(),
            transitionSettings: transitionSettings.dismissible,
          ),
      ],
    );
  }
}

class HomeRouter extends RouterDelegate<HomeRoutes>
  with ChangeNotifier,
       _DelegateMixin,
       PopNavigatorRouterDelegateMixin {

  HomeRouter() {
    AppRouter.instance.mainScreenShown = true;
    _instance = this;
  }

  static HomeRouter _instance;
  static HomeRouter get instance => _instance;

  @override
  void dispose() {
    _instance = null;
    AppRouter.instance.mainScreenShown = false;
    super.dispose();
  }

  final List<HomeRoutes> __routes = [HomeRoutes.tabs];
  @override
  List<HomeRoutes> get _routes => __routes;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  // for web applicatiom
  @override
  HomeRoutes get currentConfiguration => _routes.last;

  @override
  Future<void> setNewRoutePath(HomeRoutes configuration) async { }

  final tabsRouteKey = GlobalKey<TabsRouteState>();
  SearchDelegate _searchDelegate;

  /// Whether the drawer can be opened.
  bool get drawerCanBeOpened =>
      playerRouteController.closed &&
      ContentControl.state.selectionNotifier.value == null &&
      routes.last != HomeRoutes.album &&
      (tabsRouteKey.currentState.tabController.animation.value == 0.0 || routes.length > 1);

  /// Callback that must be called before any pop.
  /// 
  /// For example we want that player route would be closed first.
  bool handleNecessaryPop() {
    final selectionController = ContentControl.state.selectionNotifier?.value;
    if (playerRouteController.opened) {
      if (selectionController != null) {
        selectionController.close();
        return true;
      }
      playerRouteController.close();
      return true;
    } else if (drawerController.opened) {
      drawerController.close();
      return true;
    } else if (selectionController != null) {
      selectionController.close();
      return true;
    } else if (navigatorKey.currentState != null && navigatorKey.currentState.canPop()) {
      navigatorKey.currentState.pop();
      return true;
    }
    return false;
  }

  @override
  void goto(HomeRoutes route) {
    super.goto(route);
    if (route == HomeRoutes.album) {
      playerRouteController.close();
    } else if (route == HomeRoutes.search) {
      _searchDelegate ??= SearchDelegate();
      final SearchArguments arguments = route.arguments;
      _searchDelegate.query = arguments.query;
      _searchDelegate.autoKeyboard = arguments.openKeyboard;
    }
  }

  @override
  bool _handlePopPage(Route<dynamic> route, dynamic result) {
    if (_searchDelegate != null && _routes.contains(HomeRoutes.search)) {
      _searchDelegate = null;
    }
    return super._handlePopPage(route, result);
  }

  @override
  Widget build(BuildContext context) {
    final transitionSettings = AppRouter.instance.transitionSettings;
    return Navigator(
      key: navigatorKey,
      observers: [homeRouteObserver],
      onPopPage: _handlePopPage,
      pages: <Page<void>>[
        for (final route in _routes)
          if (route == HomeRoutes.tabs)
            StackFadePage(
              key: HomeRoutes.tabs.key,
              child: TabsRoute(key: tabsRouteKey),
              transitionSettings: transitionSettings.grey,
            )
          else if (route == HomeRoutes.album)
            StackFadePage(
              key: HomeRoutes.album.key,
              transitionSettings: transitionSettings.greyDismissible,
              child: AlbumRoute(album: route.arguments),
            )
          else if (route == HomeRoutes.search)
            SearchPage(
              key: HomeRoutes.search.key,
              delegate: _searchDelegate,
              transitionSettings: transitionSettings.grey,
            )
          else
            throw UnimplementedError()
      ],
    );
  }
}


class HomeRouteInformationProvider extends RouteInformationProvider with ChangeNotifier {
  @override
  RouteInformation value = RouteInformation(location: HomeRoutes.tabs.location);
}

class HomeRouteBackButtonDispatcher extends ChildBackButtonDispatcher {
  HomeRouteBackButtonDispatcher(BackButtonDispatcher parent) : super(parent);

  @override
  Future<bool> invokeCallback(Future<bool> defaultValue) async {
    final handled = HomeRouter.instance.handleNecessaryPop();
    if (handled)
      return true;
    return super.invokeCallback(defaultValue);
  }
}
