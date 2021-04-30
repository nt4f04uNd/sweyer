/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/


export 'home_route/home_route.dart';
export 'settings_route/settings_route.dart';
export 'dev_route.dart';

import 'dart:async';

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

abstract class _Routes<T> extends Equatable {
const _Routes(this.location, [this.arguments]);

  final String location;
  final T? arguments;

  /// Value key to pass in to the [Page].
  ValueKey<String?> get key => ValueKey(location);

  @override
  List<Object> get props => [location];
}

class AppRoutes<T> extends _Routes<T> {
  const AppRoutes._(String location, [T? arguments]) : super(location, arguments);

  static const initial = AppRoutes<void>._('/');
  static const settings = AppRoutes<void>._('/settings');
  static const themeSettings = AppRoutes<void>._('/settings/theme');
  static const licenses = AppRoutes<void>._('/settings/licenses');
  static const dev = AppRoutes<void>._('/dev');
}

class HomeRoutes<T> extends _Routes<T> {
  const HomeRoutes._(String location, [T? arguments]) : super(location, arguments);

  static const tabs = HomeRoutes<void>._('/tabs');
  static const album = HomeRoutes<Album>._('/album');
  static const playlist = HomeRoutes<Playlist>._('/playlist');
  static const artist = HomeRoutes<Artist>._('/artist');
  static const search = HomeRoutes<SearchArguments>._('/search');

  /// Returns a factory to create routes with arguments.
  static const factory = _HomeRoutesFactory();
}

class _HomeRoutesFactory {
  const _HomeRoutesFactory();

  HomeRoutes<T> content<T extends Content>(T content) {
    return contentPick<T, ValueGetter<dynamic>>(
      song: () => throw ArgumentError(),
      album: () => HomeRoutes<Album>._(HomeRoutes.album.location, content as Album),
      playlist: () => HomeRoutes<Playlist>._(HomeRoutes.playlist.location, content as Playlist),
      artist: () => HomeRoutes<Artist>._(HomeRoutes.artist.location, content as Artist),
    )();
  }

  HomeRoutes<Content> persistentQueue<T extends PersistentQueue>(T persistentQueue) {
    if (persistentQueue is Album || persistentQueue is Playlist) {
      return content<T>(persistentQueue);
    } else {
      throw ArgumentError();
    }
  }

  HomeRoutes<SearchArguments> search(SearchArguments arguments) {
    return HomeRoutes._(HomeRoutes.search.location, arguments);
  }
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
    return AppRoutes._(routeInformation.location!);
  }

  @override
  RouteInformation restoreRouteInformation(AppRoutes configuration) {
    return RouteInformation(location: configuration.location);
  }
}

class HomeRouteInformationParser extends RouteInformationParser<HomeRoutes> {
  @override
  Future<HomeRoutes> parseRouteInformation(RouteInformation routeInformation) async {
    return HomeRoutes._(routeInformation.location!);
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
  /// By default, if route already in the stack, removes all routes on top of it.
  ///
  /// However, if [allowStackSimilar] is `true`, then if similar route is on top,
  /// for example [HomeRoutes.album], and other one is pushed, it will be stacked on top.
  void goto(T route, [bool allowStackSimilar = false]) {
    final index = !allowStackSimilar
      ? _routes.indexOf(route)
      : _routes.lastIndexOf(route);
    if (!allowStackSimilar
          ? index > 0
          : index > 0 && index != _routes.length - 1) {
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
    required this.grey,
    required this.greyDismissible,
    required this.dismissible,
    required this.initial,
    required this.theme,
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

  final List<AppRoutes> __routes = [AppRoutes.initial as AppRoutes<Object>];
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

  VoidCallback? setState;
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
      setState?.call();
      transitionSettings.theme.dismissible = false;
      Future.delayed(dilate(const Duration(milliseconds: 300)), () {
        setState?.call();
        transitionSettings.theme.dismissible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, setState) {
        this.setState = () => setState(() { });
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
      },
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
    // _quickActionsSub = ContentControl.quickAction.listen((action) {
    //   if (action == QuickAction.search) {
    //     ShowFunctions.instance.showSongsSearch();
    //   }
    // });
  }

  static HomeRouter? _instance;
  static HomeRouter get instance => _instance!;

  @override
  void dispose() {
    _instance = null;
    AppRouter.instance.mainScreenShown = false;
    _quickActionsSub.cancel();
    super.dispose();
  }

  late StreamSubscription<QuickAction> _quickActionsSub;

  final List<HomeRoutes> __routes = [HomeRoutes.tabs as HomeRoutes<Object>];
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
  SearchDelegate? _searchDelegate;

  /// Whether the drawer can be opened.
  bool get drawerCanBeOpened {
    final selectionController = ContentControl.state.selectionNotifier.value;
    return playerRouteController.closed &&
      (selectionController?.notInSelection ?? true) &&
      routes.last != HomeRoutes.album &&
      ((tabsRouteKey.currentState?.tabController.animation?.value ?? -1) == 0.0 || routes.length > 1) &&
      !(tabsRouteKey.currentState?.tabBarDragged ?? false);
  }

  /// Callback that must be called before any pop.
  /// 
  /// For example we want that player route would be closed first.
  bool handleNecessaryPop() {
    final selectionController = ContentControl.state.selectionNotifier.value;
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
    }
    return false;
  }

  /// The [allowStackSimilar] parameter in this override is ignored and set automatically.
  @override
  void goto(HomeRoutes route, [bool allowStackSimilar = false]) {
    super.goto(route, false);
    if (route == HomeRoutes.album) {
      playerRouteController.close();
    } else if (route == HomeRoutes.search) {
      _searchDelegate ??= SearchDelegate();
      final arguments = (route as HomeRoutes<SearchArguments>).arguments!;
      _searchDelegate!.query = arguments.query;
      _searchDelegate!.autoKeyboard = arguments.openKeyboard;
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
    final pages = <Page<void>>[];

    for (int i = 0; i < _routes.length; i++) {
      /// TODO: when i'll be adding artists and other contents, i should stack them together (including albums)
      /// 
      /// I can use this
      /// 
      /// ```dart
      /// ValueKey('${HomeRoutes.album.location}/${(route.arguments as Album).id}_$i')
      /// ```
      /// 
      /// Currently i don't enable it, since there's on reason for that, as the only possible way
      /// to stack album routes is through selection action to go to album - but this is disabled
      /// in albums

      final route = _routes[i];
      if (route == HomeRoutes.tabs) {
        pages.add(StackFadePage(
          key: HomeRoutes.tabs.key,
          child: TabsRoute(key: tabsRouteKey),
          transitionSettings: transitionSettings.grey,
        ));
      } else if (route == HomeRoutes.album) {
        pages.add(StackFadePage(
          key: HomeRoutes.album.key,
          transitionSettings: transitionSettings.greyDismissible,
          child: AlbumRoute(album: (route as HomeRoutes<Album>).arguments!),
        ));
      } else if (route == HomeRoutes.search) {
        pages.add(SearchPage(
          key: HomeRoutes.search.key,
          delegate: _searchDelegate!,
          transitionSettings: transitionSettings.grey,
        ));
      } else {
        throw UnimplementedError();
      }
    }
    return Navigator(
      key: navigatorKey,
      observers: [homeRouteObserver],
      onPopPage: _handlePopPage,
      pages: pages,
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
