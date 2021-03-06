/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/


export 'home_route/home_route.dart';
export 'settings_route/settings_route.dart';
export 'dev_route.dart';
export 'selection_route.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide LicensePage;
import 'package:equatable/equatable.dart';
import 'package:sweyer/routes/settings_route/theme_settings.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;

import 'home_route/home_route.dart';
import 'settings_route/settings_route.dart';
import 'settings_route/licenses_route.dart';
import 'dev_route.dart';
import 'selection_route.dart';

final RouteObserver<Route> routeObserver = RouteObserver();
final RouteObserver<Route> homeRouteObserver = RouteObserver();

abstract class _Routes<T> extends Equatable {
  const _Routes(this.location, [this.arguments]);

  final String location;
  final T? arguments;

  _Routes withArguments(T arguments);

  /// Returns a unique key to pass in to the [Page].
  /// This will disallow adding this route to stack multiple times.
  ///
  /// See also:
  ///  * [uniqueKey], which allows for multiple [Page]s for this route
  ValueKey<String> get uniqueKey => ValueKey(location);

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

  @override
  AppRoutes<T> withArguments(T arguments) {
    return AppRoutes<T>._(location, arguments);
  }

  static const initial = AppRoutes<void>._('/');
  static const settings = AppRoutes<void>._('/settings');
  static const themeSettings = AppRoutes<void>._('/settings/theme');
  static const licenses = AppRoutes<void>._('/settings/licenses');
  static const dev = AppRoutes<void>._('/dev');
  static const selection = AppRoutes<SelectionArguments>._('/selection');
}

class HomeRoutes<T> extends _Routes<T> {
  const HomeRoutes._(String location, [T? arguments]) : super(location, arguments);

  @override
  HomeRoutes<T> withArguments(T arguments) {
    return HomeRoutes<T>._(location, arguments);
  }

  static const tabs = HomeRoutes<void>._('/tabs');
  static const album = HomeRoutes<PersistentQueueArguments<Album>>._('/album');
  static const playlist = HomeRoutes<PersistentQueueArguments<Playlist>>._('/playlist');
  static const artist = HomeRoutes<Artist>._('/artist');
  static const artistContent = HomeRoutes<Artist>._('/artist/content');
  static const search = HomeRoutes<SearchArguments>._('/search');

  /// Returns a factory to create routes with arguments.
  static const factory = _HomeRoutesFactory();
}

class _HomeRoutesFactory {
  const _HomeRoutesFactory();

  HomeRoutes content<T extends Content>(T content) {
    return contentPick<T, ValueGetter<dynamic>>(
      song: () => throw ArgumentError(),
      album: () => HomeRoutes._(HomeRoutes.album.location, PersistentQueueArguments(queue: content as Album)),
      playlist: () => HomeRoutes._(HomeRoutes.playlist.location, PersistentQueueArguments(queue: content as Playlist)),
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

  HomeRoutes persistentQueue<T extends PersistentQueue>(T persistentQueue) {
    if (persistentQueue is Album || persistentQueue is Playlist) {
      return content<T>(persistentQueue);
    } else {
      throw ArgumentError();
    }
  }
}

class SelectionArguments {
  SelectionArguments({
    required this.title,
    required this.onSubmit,
    this.settingsPageBuilder,
  });

  /// Builder for title to display in the app bar.
  final String Function(BuildContext) title;

  /// Fired when user pressed a done button.
  final ValueSetter<Set<SelectionEntry>> onSubmit;

  /// If non-null, near submit button there will be shown a settings button,
  /// and if it's pressed, the new route is opened which shows the result of
  /// this function invocation.
  final WidgetBuilder? settingsPageBuilder;

  /// Created and set in [SelectionRoute].
  late ContentSelectionController selectionController;
}

class PersistentQueueArguments<T extends PersistentQueue> extends Equatable {
  PersistentQueueArguments({
    required this.queue,
    this.editing = false,
  }) : assert(
        !editing || queue is Playlist,
        "The `editing` is only valid with playlists"
      );

  /// The queue to be opened.
  final T queue;

  // Whether to open the playlist route in edtining mode.
  final bool editing;

  @override
  List<Object> get props => [queue, editing];
}

/// The artist `T` content.
///
/// Only [Song] and [Album] are valid.
class ArtistContentArguments<T extends Content> {
  ArtistContentArguments({
    required this.artist,
    required this.list,
  }) : assert(T == Song || T == Album);

  /// Artist the contents of which to view.
  final Artist artist;

  /// The list of artist content for initial render.
  ///
  /// Further this will be updated automatically on [ContentState.onContentChange].
  ///
  /// Because this is created in [ArtistRoute], there we already have a list
  /// of artist content.
  final List<T> list;
}

class SearchArguments {
  SearchArguments({
    this.query = '',
    this.openKeyboard = true,
  }) {
    _delegate.query = query;
    _delegate.autoKeyboard = openKeyboard;
  }

  final ContentSearchDelegate _delegate = ContentSearchDelegate();
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
  RouteObserver<Route> get observer;

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

  bool _handlePopPage(Route<Object?> route, Object? result) {
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

class AppRouter extends RouterDelegate<AppRoutes<Object?>>
  with ChangeNotifier,
       _DelegateMixin,
       PopNavigatorRouterDelegateMixin {

  AppRouter._();
  static final instance = AppRouter._();

  @override
  RouteObserver<Route> get observer => routeObserver;

  @override
  List<AppRoutes<Object?>> get _routes => __routes;
  final List<AppRoutes<Object?>> __routes = [AppRoutes.initial as AppRoutes<Object>];

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

        final pages = <Page<void>>[
          StackFadePage(
            key: AppRoutes.initial.uniqueKey,
            child: const InitialRoute(),
            transitionSettings: transitionSettings.initial,
          ),
        ];

        for (int i = 0; i < _routes.length; i++) {
          final route = _routes[i];
          if (route.hasSameLocation(AppRoutes.settings)) {
            pages.add(StackFadePage(
              key: AppRoutes.settings.uniqueKey,
              child: const SettingsRoute(),
              transitionSettings: transitionSettings.dismissible,
            ));
          } else if (route.hasSameLocation(AppRoutes.themeSettings)) {
            pages.add(StackFadePage(
              key: AppRoutes.themeSettings.uniqueKey,
              child: const ThemeSettingsRoute(),
              transitionSettings: transitionSettings.theme,
            ));
          } else if (route.hasSameLocation(AppRoutes.licenses)) {
            pages.add(StackFadePage(
              key: AppRoutes.licenses.uniqueKey,
              child: const LicensePage(),
              transitionSettings: transitionSettings.dismissible,
            ));
          } else if (route.hasSameLocation(AppRoutes.dev)) {
            pages.add(StackFadePage(
              key: AppRoutes.dev.uniqueKey,
              child: const DevRoute(),
              transitionSettings: transitionSettings.dismissible,
            ));
          } else if (route.hasSameLocation(AppRoutes.selection)) {
            pages.add(StackFadePage(
              key: AppRoutes.selection.uniqueKey,
              child: SelectionRoute(
                selectionArguments: (route as AppRoutes<SelectionArguments>).arguments!,
              ),
              transitionSettings: transitionSettings.greyDismissible,
            ));
          }
        }
        return Navigator(
          key: navigatorKey,
          observers: [routeObserver],
          onPopPage: _handlePopPage,
          pages: pages,
        );
      },
    );
  }
}

class HomeRouter extends RouterDelegate<HomeRoutes<Object?>>
  with ChangeNotifier,
       _DelegateMixin,
       PopNavigatorRouterDelegateMixin {

  HomeRouter.main() : selectionArguments = null {
    AppRouter.instance.mainScreenShown = true;
    _instance = this;
    // _quickActionsSub = ContentControl.quickAction.listen((action) {
    //   if (action == QuickAction.search) {
    //     ShowFunctions.instance.showSongsSearch();
    //   }
    // });
  }

  HomeRouter.selection(SelectionArguments this.selectionArguments);

  final SelectionArguments? selectionArguments;
  bool get selectionRoute => selectionArguments != null;

  static HomeRouter? _instance;
  static HomeRouter get instance => _instance!;

  static HomeRouter of(BuildContext context) {
    return _RouterDelegateProvider.maybeOf<HomeRouter>(context)!;
  }

  static HomeRouter? maybeOf(BuildContext context) {
    return _RouterDelegateProvider.maybeOf<HomeRouter>(context);
  }

  @override
  void dispose() {
    _instance = null;
    AppRouter.instance.mainScreenShown = false;
    // _quickActionsSub.cancel();
    super.dispose();
  }

  // late StreamSubscription<QuickAction> _quickActionsSub;

  @override
  RouteObserver<Route> get observer => selectionRoute ? _observer : homeRouteObserver;
  late final RouteObserver<Route> _observer = RouteObserver();

  @override
  List<HomeRoutes<Object?>> get _routes => __routes;
  final List<HomeRoutes<Object?>> __routes = [HomeRoutes.tabs as HomeRoutes<Object>];

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  Future<void> setNewRoutePath(HomeRoutes configuration) async { }

  final tabsRouteKey = GlobalKey<TabsRouteState>();

  ContentSearchDelegate? get _currentSearchDelegate => _routes.last.hasSameLocation(HomeRoutes.search) 
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
    // Don't try to close the alwaysInSelection controller, since it is not possible
    } else if (selectionController != null &&
              !selectionController.alwaysInSelection) {
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
    } else {
      super.goto(route);
    }
  }

  Page<void> _buildPage(
    LocalKey key,
    StackFadeRouteTransitionSettings transitionSettings,
    Widget child,
  ) {
    if (selectionRoute) {
      child = Padding(
        padding: const EdgeInsets.only(bottom: kSongTileHeight),
        child: child,
      );
    }
    return StackFadePage(
      key: key,
      transitionSettings: transitionSettings,
      child: child,
    );
  }

  Widget _buildChild(Widget child) {
    if (selectionRoute) {
      child = Padding(
        padding: const EdgeInsets.only(bottom: kSongTileHeight),
        child: child,
      );
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final transitionSettings = AppRouter.instance.transitionSettings;
    final pages = <Page<void>>[];

    for (int i = 0; i < _routes.length; i++) {
      LocalKey _buildContentKey(_Routes route, Content content) {
        return ValueKey('${route.location}/${content.id}_$i');
      }

      final route = _routes[i];
      if (route.hasSameLocation(HomeRoutes.tabs)) {
        pages.add(_buildPage(
          HomeRoutes.tabs.uniqueKey,
          transitionSettings.grey,
          TabsRoute(key: tabsRouteKey),
        ));

      } else if (route.hasSameLocation(HomeRoutes.album)) {
        final arguments = route.arguments! as PersistentQueueArguments<Album>;
        pages.add(_buildPage(
          _buildContentKey(HomeRoutes.album, arguments.queue),
          transitionSettings.greyDismissible,
          PersistentQueueRoute(arguments: arguments),
        ));

      } else if (route.hasSameLocation(HomeRoutes.playlist)) {
        final arguments = route.arguments! as PersistentQueueArguments<Playlist>;
        pages.add(_buildPage(
          _buildContentKey(route, arguments.queue),
          transitionSettings.greyDismissible,
          PersistentQueueRoute(arguments: arguments),
        ));

      } else if (route.hasSameLocation(HomeRoutes.artist)) {
        final arguments = route.arguments! as Artist;
        pages.add(_buildPage(
          _buildContentKey(route, arguments),
          transitionSettings.greyDismissible,
          ArtistRoute(artist: arguments),
        ));

      } else if (route.hasSameLocation(HomeRoutes.artistContent)) {
        final arguments = route.arguments! as ArtistContentArguments;
        final ArtistContentRoute _route;
        if (arguments is ArtistContentArguments<Song>)
          _route = ArtistContentRoute<Song>(arguments: arguments);
        else if (arguments is ArtistContentArguments<Album>)
          _route = ArtistContentRoute<Album>(arguments: arguments);
        else
          throw ArgumentError();
        pages.add(_buildPage(
          ValueKey('${HomeRoutes.artistContent.location}/${arguments.artist.id}_$i'),
          transitionSettings.greyDismissible,
          _route,
        ));

      } else if (route.hasSameLocation(HomeRoutes.search)) {
        final arguments = route.arguments! as SearchArguments;
        pages.add(SearchPage(
          key: ValueKey('${HomeRoutes.search.location}/$i'),
          child: _buildChild(SearchRoute(delegate: arguments._delegate)),
          transitionSettings: transitionSettings.grey,
        ));

      } else {
        throw UnimplementedError();
      }
    }
    return _RouterDelegateProvider<HomeRouter>(
      delegate: this,
      child: Navigator(
        key: navigatorKey,
        observers: [observer],
        onPopPage: _handlePopPage,
        pages: pages,
      ),
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

class _RouterDelegateProvider<T extends RouterDelegate> extends InheritedWidget {
  _RouterDelegateProvider({
    Key? key,
    required this.delegate,
    required Widget child,
  }) : super(key: key, child: child);

  final T delegate;

  static T? maybeOf<T extends RouterDelegate>(BuildContext context) {
    return (context.getElementForInheritedWidgetOfExactType<_RouterDelegateProvider<T>>()?.widget 
              as _RouterDelegateProvider<T>?)?.delegate;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}