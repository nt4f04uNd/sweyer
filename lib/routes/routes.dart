export 'home_route/home_route.dart';
export 'settings_route/settings_route.dart';
export 'dev_route.dart';
export 'selection_route.dart';

import 'dart:async';

import 'package:flutter/material.dart' hide LicensePage;
import 'package:equatable/equatable.dart';
import 'package:sweyer/routes/settings_route/general_settings.dart';
import 'package:sweyer/routes/settings_route/theme_settings.dart';
import 'package:sweyer/sweyer.dart';

import 'settings_route/licenses_route.dart';

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

  /// The opposite of [hasSameLocation].
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
  static const generalSettings = AppRoutes<void>._('/settings/general');
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

  HomeRoutes content(Content content) {
    switch (content.type) {
      case ContentType.song:
        throw ArgumentError();
      case ContentType.album:
        return HomeRoutes._(HomeRoutes.album.location, PersistentQueueArguments(queue: content as Album));
      case ContentType.playlist:
        return HomeRoutes._(HomeRoutes.playlist.location, PersistentQueueArguments(queue: content as Playlist));
      case ContentType.artist:
        return HomeRoutes._(HomeRoutes.artist.location, content as Artist);
    }
  }

  HomeRoutes<ArtistContentArguments<T>> artistContent<T extends Content>(Artist artist, List<T> list) {
    assert(T == Song || T == Album);
    return HomeRoutes._(
      HomeRoutes.artistContent.location,
      ArtistContentArguments<T>(
        artist: artist,
        list: list,
      ),
    );
  }

  HomeRoutes persistentQueue<T extends PersistentQueue>(T persistentQueue) {
    if (persistentQueue is Album || persistentQueue is Playlist) {
      return content(persistentQueue);
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
  const PersistentQueueArguments({
    required this.queue,
    this.editing = false,
  }) : assert(
          !editing || queue is Playlist,
          "The `editing` is only valid with playlists",
        );

  /// The queue to be opened.
  final T queue;

  // Whether to open the playlist route in editing mode.
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
        assert(false, "Can't pop initial route");
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

  /// Used on theme settings route to disable dismissing while theme is changing.
  final StackFadeRouteTransitionSettings theme;
}

class AppRouter extends RouterDelegate<AppRoutes<Object?>>
    with ChangeNotifier, _DelegateMixin, PopNavigatorRouterDelegateMixin {
  static AppRouter instance = AppRouter();

  @override
  RouteObserver<Route> get observer => routeObserver;

  @override
  List<AppRoutes<Object?>> get _routes => __routes;
  final List<AppRoutes<Object?>> __routes = [AppRoutes.initial];

  @override
  Future<void> setNewRoutePath(AppRoutes configuration) async {}

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  final GlobalKey<OverlayState> artOverlayKey = GlobalKey();

  late final _TransitionSettings transitionSettings = _TransitionSettings(
    grey: StackFadeRouteTransitionSettings(uiStyle: staticTheme.systemUiThemeExtension.grey),
    greyDismissible: StackFadeRouteTransitionSettings(
      opaque: false,
      dismissible: true,
      dismissBarrier: _dismissBarrier,
      uiStyle: staticTheme.systemUiThemeExtension.grey,
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
        color: ThemeControl.instance.isDark ? Colors.black54 : Colors.black26,
      );

  bool _mainScreenShown = false;

  /// Controls the ui style that will be applied to home screen.
  set mainScreenShown(bool value) {
    _mainScreenShown = value;
    updateTransitionSettings();
  }

  VoidCallback? _setState;
  void updateTransitionSettings({bool themeChanged = false}) {
    final dismissBarrier = _dismissBarrier;
    transitionSettings.grey.uiStyle = staticTheme.systemUiThemeExtension.grey;
    transitionSettings.greyDismissible.uiStyle = staticTheme.systemUiThemeExtension.grey;
    transitionSettings.greyDismissible.dismissBarrier = dismissBarrier;
    transitionSettings.dismissible.dismissBarrier = dismissBarrier;
    transitionSettings.initial.uiStyle =
        _mainScreenShown ? staticTheme.systemUiThemeExtension.grey : staticTheme.systemUiThemeExtension.black;
    transitionSettings.theme.dismissBarrier = dismissBarrier;
    if (themeChanged) {
      _setState?.call();
      transitionSettings.theme.dismissible = false;
      Future.delayed(dilate(ThemeControl.instance.themeChangeDuration), () {
        _setState?.call();
        transitionSettings.theme.dismissible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.size.isEmpty) {
      return const SizedBox.shrink(); // Don't render the app if we are started in the background.
    }
    return _AppRouterBuilder(
      builder: (context) {
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
          } else if (route.hasSameLocation(AppRoutes.generalSettings)) {
            pages.add(StackFadePage(
              key: AppRoutes.generalSettings.uniqueKey,
              child: const GeneralSettingsRoute(),
              transitionSettings: transitionSettings.theme,
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

class _AppRouterBuilder extends StatefulWidget {
  const _AppRouterBuilder({Key? key, required this.builder}) : super(key: key);

  final WidgetBuilder builder;

  @override
  _AppRouterBuilderState createState() => _AppRouterBuilderState();
}

class _AppRouterBuilderState extends State<_AppRouterBuilder> {
  @override
  void initState() {
    super.initState();
    AppRouter.instance._setState = () => setState(() {});
  }

  @override
  void dispose() {
    AppRouter.instance._setState = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

class HomeRouter extends RouterDelegate<HomeRoutes<Object?>>
    with ChangeNotifier, _DelegateMixin, PopNavigatorRouterDelegateMixin {
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
    return RouterDelegateProvider.maybeOf<HomeRouter>(context)!;
  }

  static HomeRouter? maybeOf(BuildContext context) {
    return RouterDelegateProvider.maybeOf<HomeRouter>(context);
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
  final List<HomeRoutes<Object?>> __routes = [HomeRoutes.tabs];

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  final GlobalKey<OverlayState> overlayKey = GlobalKey();

  @override
  Future<void> setNewRoutePath(HomeRoutes configuration) async {}

  final tabsRouteKey = GlobalKey<TabsRouteState>();

  ContentSearchDelegate? get _currentSearchDelegate => _routes.last.hasSameLocation(HomeRoutes.search)
      ? (_routes.last as HomeRoutes<SearchArguments>).arguments!._delegate
      : null;

  /// Whether the drawer can be opened.
  bool get drawerCanBeOpened {
    final selectionController = ContentControl.instance.selectionNotifier.value;
    return playerRouteController.closed &&
        (selectionController?.notInSelection ?? true) &&
        (routes.last.hasSameLocation(HomeRoutes.tabs) || routes.last.hasSameLocation(HomeRoutes.search)) &&
        ((tabsRouteKey.currentState?.tabController.animation?.value ?? -1) == 0.0 || routes.length > 1) &&
        !(tabsRouteKey.currentState?.tabBarDragged ?? false) &&
        !(_currentSearchDelegate?.chipsBarDragged ?? false);
  }

  /// The [allowStackSimilar] parameter in this override is ignored and set automatically.
  @override
  void goto(HomeRoutes route) {
    playerRouteController.close();
    if (route.hasSameLocation(HomeRoutes.search) && _routes.last.hasSameLocation(HomeRoutes.search)) {
      final lastRoute = _routes.last as HomeRoutes<SearchArguments>;
      final newArguments = (route as HomeRoutes<SearchArguments>).arguments!;
      lastRoute.arguments!._delegate.query = newArguments.query;
      lastRoute.arguments!._delegate.autoKeyboard = newArguments.openKeyboard;
    } else {
      super.goto(route);
    }
  }

  Page<void> _buildPage(
    BuildContext context,
    LocalKey key,
    StackFadeRouteTransitionSettings transitionSettings,
    Widget child,
  ) =>
      StackFadePage(
        key: key,
        transitionSettings: transitionSettings,
        child: child,
      );

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
          context,
          HomeRoutes.tabs.uniqueKey,
          transitionSettings.grey,
          TabsRoute(key: tabsRouteKey),
        ));
      } else if (route.hasSameLocation(HomeRoutes.album)) {
        final arguments = route.arguments! as PersistentQueueArguments<Album>;
        pages.add(_buildPage(
          context,
          _buildContentKey(HomeRoutes.album, arguments.queue),
          transitionSettings.greyDismissible,
          PersistentQueueRoute(arguments: arguments),
        ));
      } else if (route.hasSameLocation(HomeRoutes.playlist)) {
        final arguments = route.arguments! as PersistentQueueArguments<Playlist>;
        pages.add(_buildPage(
          context,
          _buildContentKey(route, arguments.queue),
          transitionSettings.greyDismissible,
          PersistentQueueRoute(arguments: arguments),
        ));
      } else if (route.hasSameLocation(HomeRoutes.artist)) {
        final arguments = route.arguments! as Artist;
        pages.add(_buildPage(
          context,
          _buildContentKey(route, arguments),
          transitionSettings.greyDismissible,
          ArtistRoute(artist: arguments),
        ));
      } else if (route.hasSameLocation(HomeRoutes.artistContent)) {
        final arguments = route.arguments! as ArtistContentArguments;
        final ArtistContentRoute actualRoute;
        if (arguments is ArtistContentArguments<Song>) {
          actualRoute = ArtistContentRoute(contentType: ContentType.song, arguments: arguments);
        } else if (arguments is ArtistContentArguments<Album>) {
          actualRoute = ArtistContentRoute(contentType: ContentType.album, arguments: arguments);
        } else {
          throw ArgumentError();
        }
        pages.add(_buildPage(
          context,
          ValueKey('${HomeRoutes.artistContent.location}/${arguments.artist.id}_$i'),
          transitionSettings.greyDismissible,
          actualRoute,
        ));
      } else if (route.hasSameLocation(HomeRoutes.search)) {
        final arguments = route.arguments! as SearchArguments;
        pages.add(SearchPage(
          key: ValueKey('${HomeRoutes.search.location}/$i'),
          child: SearchRoute(delegate: arguments._delegate),
          transitionSettings: transitionSettings.grey,
        ));
      } else {
        throw UnimplementedError();
      }
    }
    return RouterDelegateProvider<HomeRouter>(
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

class RouterDelegateProvider<T extends RouterDelegate> extends InheritedWidget {
  const RouterDelegateProvider({
    Key? key,
    required this.delegate,
    required Widget child,
  }) : super(key: key, child: child);

  final T delegate;

  static T? maybeOf<T extends RouterDelegate>(BuildContext context) {
    return (context.getElementForInheritedWidgetOfExactType<RouterDelegateProvider<T>>()?.widget
            as RouterDelegateProvider<T>?)
        ?.delegate;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
