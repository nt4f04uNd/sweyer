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
  ValueKey<String> get key => ValueKey(location);

  @override
  List<Object?> get props => [location, arguments];

  /// Checks whether the [other] route has the same location.
  ///
  /// Routes compared with [==] will be the same only when both content and
  /// arguments are equal.
  bool hasSameLocation(_Routes other) {
    return location == other.location;
  }

  /// The oppsoite of [hasSameLocation].
  bool hasDifferentLocation(_Routes other) {
    return location != other.location;
  }
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
  static const artistContent = HomeRoutes<Artist>._('/artist/content');
  static const search = HomeRoutes<SearchArguments>._('/search');

  /// Returns a factory to create routes with arguments.
  static const factory = _HomeRoutesFactory();
}

class _HomeRoutesFactory {
  const _HomeRoutesFactory();

  HomeRoutes<T> content<T extends Content>(T content) {
    return contentPick<T, ValueGetter<dynamic>>(
      song: () => throw ArgumentError(),
      album: () => HomeRoutes._(HomeRoutes.album.location, content as Album),
      playlist: () => HomeRoutes._(HomeRoutes.playlist.location, content as Playlist),
      artist: () => HomeRoutes._(HomeRoutes.artist.location, content as Artist),
    )();
  }

  HomeRoutes<ArtistContentArguments<T>> artistContent<T extends Content>(Artist artist, List<T> list) {
    assert(T == Song || T == Album);
    return HomeRoutes._(HomeRoutes.artistContent.location, ArtistContentArguments<T>(
      artist: artist,
      list: list,
    ));
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

class ArtistContentArguments<T> {
  ArtistContentArguments({
    required this.artist,
    required this.list,
  });

  final Artist artist;
  final List<T> list;
}

class SearchArguments {
  SearchArguments({
    this.query = '',
    this.openKeyboard = true
  });

  final String query;
  final bool openKeyboard;

  final _delegate = SearchDelegate();
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
  /// Route stack.
  List<T> get routes => List.unmodifiable(_routes);
  List<T> get _routes;

  /// Returns the route laying on top of the stack.
  T get currentRoute => _routes.last;

  // For web application
  @override
  T get currentConfiguration => currentRoute;

  /// Goes to some route.
  ///
  /// If route already in the stack and lies just below the current route,
  /// removes current route to reveal it.
  ///
  /// Otherwise just adds the new route.
  void goto(T route) {
    final index = _routes.indexOf(route);
    if (index != _routes.length - 1) {
      if (index > 0 && index == _routes.length - 2) {
        _routes.remove(_routes.last);
      } else {
        _routes.add(route);
      }
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

  @override
  List<AppRoutes> get _routes => __routes;
  final List<AppRoutes> __routes = [AppRoutes.initial as AppRoutes<Object>];

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
            if (_routes.length > 1 && _routes[1].hasSameLocation(AppRoutes.settings))
              StackFadePage(
                key: AppRoutes.settings.key,
                child: const SettingsRoute(),
                transitionSettings: transitionSettings.dismissible,
              ),
            if (_routes.length > 2 && _routes[2].hasSameLocation(AppRoutes.themeSettings))
              StackFadePage(
                key: AppRoutes.themeSettings.key,
                child: const ThemeSettingsRoute(),
                transitionSettings: transitionSettings.theme,
              ),
            if (_routes.length > 2 && _routes[2].hasSameLocation(AppRoutes.licenses))
              StackFadePage(
                key: AppRoutes.licenses.key,
                child: const LicensePage(),
                transitionSettings: transitionSettings.dismissible,
              ),
            if (_routes.length > 1 && _routes[1].hasSameLocation(AppRoutes.dev))
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
    // _quickActionsSub.cancel();
    super.dispose();
  }

  // late StreamSubscription<QuickAction> _quickActionsSub;

  @override
  List<HomeRoutes> get _routes => __routes;
  final List<HomeRoutes> __routes = [HomeRoutes.tabs as HomeRoutes<Object>];

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  Future<void> setNewRoutePath(HomeRoutes configuration) async { }

  final tabsRouteKey = GlobalKey<TabsRouteState>();

  SearchDelegate? get _currentSearchDelegate => _routes.last.hasSameLocation(HomeRoutes.search) 
    ? (_routes.last as HomeRoutes<SearchArguments>).arguments!._delegate
    : null;

  /// Whether the drawer can be opened.
  bool get drawerCanBeOpened {
    final selectionController = ContentControl.state.selectionNotifier.value;
    return playerRouteController.closed &&
      (selectionController?.notInSelection ?? true) &&
      (routes.last.hasSameLocation(HomeRoutes.tabs) || routes.last.hasSameLocation(HomeRoutes.search)) &&
      ((tabsRouteKey.currentState?.tabController.animation?.value ?? -1) == 0.0 || routes.length > 1) &&
      !(tabsRouteKey.currentState?.tabBarDragged ?? false) &&
      !(_currentSearchDelegate?.chipsBarDragged ?? false);
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
  void goto(HomeRoutes route) {
    playerRouteController.close();
    if (route.hasSameLocation(HomeRoutes.search) &&
       _routes.last.hasSameLocation(HomeRoutes.search)) {
      final lastRoute = _routes.last as HomeRoutes<SearchArguments>;
      final newArguments = (route as HomeRoutes<SearchArguments>).arguments!;
      lastRoute.arguments!._delegate.query = newArguments.query;
      lastRoute.arguments!._delegate.autoKeyboard = newArguments.openKeyboard;
    }
    super.goto(route);
  }

  @override
  Widget build(BuildContext context) {
    final transitionSettings = AppRouter.instance.transitionSettings;
    final pages = <Page<void>>[];

    for (int i = 0; i < _routes.length; i++) {
      LocalKey _buildContentKey<T extends Content>(HomeRoutes route) {
        final content = HomeRoutes.factory.content<T>(route.arguments!);
        return contentPick<T, ValueGetter<LocalKey>>(
          song: () => throw ArgumentError(),
          album: () => ValueKey('${content.location}/${route.arguments!.id}_$i'),
          playlist: () => ValueKey('${content.location}/${route.arguments!.id}_$i'),
          artist: () => ValueKey('${content.location}/${route.arguments!.id}_$i'),
        )();
      }

      final route = _routes[i];
      if (route.hasSameLocation(HomeRoutes.tabs)) {
        pages.add(StackFadePage(
          key: HomeRoutes.tabs.key,
          child: TabsRoute(key: tabsRouteKey),
          transitionSettings: transitionSettings.grey,
        ));
      } else if (route.hasSameLocation(HomeRoutes.album)) {
        pages.add(StackFadePage(
          key: _buildContentKey<Album>(route),
          transitionSettings: transitionSettings.greyDismissible,
          child: PersistentQueueRoute(queue: (route as HomeRoutes<Album>).arguments!),
        ));
      } else if (route.hasSameLocation(HomeRoutes.playlist)) {
        pages.add(StackFadePage(
          key: _buildContentKey<Playlist>(route),
          transitionSettings: transitionSettings.greyDismissible,
          child: PersistentQueueRoute(queue: (route as HomeRoutes<Playlist>).arguments!),
        ));
      } else if (route.hasSameLocation(HomeRoutes.artist)) {
        pages.add(StackFadePage(
          key: _buildContentKey<Artist>(route),
          transitionSettings: transitionSettings.greyDismissible,
          child: ArtistRoute(artist: (route as HomeRoutes<Artist>).arguments!),
        ));
      } else if (route.hasSameLocation(HomeRoutes.artistContent)) {
        final arguments = route.arguments!;
        final ArtistContentRoute _route;
        if (arguments is ArtistContentArguments<Song>)
          _route = ArtistContentRoute<Song>(arguments: route.arguments!);
        else if (arguments is ArtistContentArguments<Album>)
          _route = ArtistContentRoute<Album>(arguments: route.arguments!);
        else
          throw ArgumentError();
        pages.add(StackFadePage(
          key: ValueKey('${HomeRoutes.artistContent}/$i'),
          transitionSettings: transitionSettings.greyDismissible,
          child: _route,
        ));
      } else if (route.hasSameLocation(HomeRoutes.search)) {
        pages.add(SearchPage(
          key: HomeRoutes.search.key,
          child: SearchRoute(delegate: (route as HomeRoutes<SearchArguments>).arguments!._delegate),
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
