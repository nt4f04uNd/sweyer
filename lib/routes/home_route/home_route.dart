/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/routes/home_route/tabs_route.dart';
import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as Constants;

export 'album_route.dart';
export 'player_route.dart';
export 'search_route.dart';
export 'tabs_route.dart';

class HomeRoute extends StatefulWidget {
  const HomeRoute({Key key}) : super(key: key);
  @override
  HomeRouteState createState() => HomeRouteState();
}

class HomeRouteState extends State<HomeRoute> with PlayerRouteControllerMixin {
  bool _onTop = true;

  void _animateNotMainUi() {
    if (_onTop && playerRouteController.value == 0.0) {
      SystemUiStyleController.animateSystemUiOverlay(
        to: Constants.UiTheme.black.auto,
        duration: const Duration(milliseconds: 550),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwareWidget(
      onPushNext: () {
        _onTop = false;
      },
      onPopNext: () {
        _onTop = true;
      },
      child: StreamBuilder(
        stream: ContentControl.state.onSongListChange,
        builder: (context, snapshot) {
          if (!ContentControl.playReady) {
            _animateNotMainUi();
            return Container(
              color: ThemeControl.theme.colorScheme.background,
            );
          }
          if (Permissions.notGranted) {
            _animateNotMainUi();
            return const _NoPermissionsScreen();
          }
          if (ContentControl.state.queues.all.isNotEmpty && !ContentControl.initFetching) {
            if (ThemeControl.ready && _onTop && playerRouteController.value == 0.0) {
              SystemUiStyleController.animateSystemUiOverlay(
                to: Constants.UiTheme.grey.auto,
              );
            }
            return StreamBuilder<bool>(
                stream: ThemeControl.onThemeChange,
                builder: (context, snapshot) {
                  if (snapshot.data == true)
                    return const SizedBox.shrink();
                  return const MainScreen();
                }
              );
          }
          _animateNotMainUi();
          if (ContentControl.initFetching) {
            return const _SearchingSongsScreen();
          }
          return const _SongsEmptyScreen();
        },
      ),
    );
  }
}

class SelectionControllers extends InheritedWidget {
  const SelectionControllers({
    Key key,
    @required this.child,
    @required this.map,
  })  : assert(child != null),
        assert(map != null),
        super(key: key, child: child);

  final Widget child;
  final Map<Type, SelectionController<SelectionEntry>> map;

  SelectionController<SongSelectionEntry> get song => map[Song];
  SelectionController<AlbumSelectionEntry> get album => map[Album];

  static SelectionControllers of(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<SelectionControllers>().widget;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

/// Main app route with song and album list tabs
class MainScreen extends StatefulWidget {
  const MainScreen({Key key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with
        TickerProviderStateMixin,
        DrawerControllerMixin,
        PlayerRouteControllerMixin {
  static const int _tabsLength = 2;

  Map<Type, SelectionController<SelectionEntry>> selectionControllersMap;
  TabController tabController;
  SlidableController playerRouteController;
  SlidableController drawerController;

  bool get drawerCanBeOpened =>
      playerRouteController.closed &&
      selectionControllersMap.values.every((el) => el.notInSelection) &&
      HomeRouter.instance.routes.last != HomeRoutes.album;

  /// Whether the drawer swipe is enabled.
  bool get drawerSwipe => tabController.animation.value == 0.0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      AppRouter.instance.mainScreenShown = true;
    });

    selectionControllersMap = {
      Song: SelectionController<SongSelectionEntry>(
        animationController: AnimationController(
          vsync: this,
          duration: kSelectionDuration,
        ),
      ),
      Album: SelectionController<AlbumSelectionEntry>(
        animationController: AnimationController(
          vsync: this,
          duration: kSelectionDuration,
        ),
      )
    };

    tabController = tabController = TabController(
      vsync: this,
      length: _tabsLength,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      AppRouter.instance.mainScreenShown = false;
    });
    for (final controller in selectionControllersMap.values) {
      controller.dispose();
    }
    tabController.dispose();
    super.dispose();
  }

  /// Handles pop before any other pops in the [HomeRouter].
  bool _handleNecessaryPop() {
    if (playerRouteController.opened) {
      playerRouteController.close();
      return true;
    } else if (drawerController.opened) {
      drawerController.close();
      return true;
    }
    return false;
  }

  // Var to show exit toast
  DateTime _lastBackPressTime;
  Future<bool> _handlePop(BuildContext context) async {
    final handled = _handleNecessaryPop();
    if (handled)
      return false;
    if (selectionControllersMap.values.any((el) => el.inSelection)) {
      for (final controller in selectionControllersMap.values) {
        controller.close();
      }
      return false;
    } else if (HomeRouter.instance.navigatorKey.currentState != null &&
               HomeRouter.instance.navigatorKey.currentState.canPop()) {
      HomeRouter.instance.navigatorKey.currentState.pop();
      return false;
    } else {
      DateTime now = DateTime.now();
      // Show toast when user presses back button on main route, that asks from user to press again to confirm that he wants to quit the app
      if (_lastBackPressTime == null ||
          now.difference(_lastBackPressTime) > Duration(seconds: 2)) {
        _lastBackPressTime = now;
        ShowFunctions.instance.showToast(
          msg: getl10n(context).pressOnceAgainToExit,
        );
        return false;
      }
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectionControllers(
      map: selectionControllersMap,
      child: Builder(
        builder: (context) {
          final selectionControllers = SelectionControllers.of(context);
          HomeRouter.instance.home = TabsRoute(tabController);
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: WillPopScope(
              onWillPop: () => _handlePop(context),
              child: Stack(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: kSongTileHeight),
                    child: Router<HomeRoutes>(
                      routerDelegate: HomeRouter.instance,
                      routeInformationParser: HomeRouteInformationParser(),
                      routeInformationProvider: HomeRouteInformationProvider(),
                      backButtonDispatcher: HomeRouteBackButtonDispatcher(
                        parent: Router.of(context).backButtonDispatcher,
                        necessaryPopHandler: _handleNecessaryPop,
                      ),
                    ),
                  ),
                  const PlayerRoute(),
                  SelectionBottomBar(
                    controller: selectionControllers.song,
                    left: [
                      ActionsSelectionTitle(
                        controller: selectionControllers.song,
                      )
                    ],
                    right: [
                      GoToAlbumSelectionAction(
                        controller: selectionControllers.song,
                      ),
                      PlayNextSelectionAction<Song>(
                        controller: selectionControllers.song,
                      ),
                      AddToQueueSelectionAction<Song>(
                        controller: selectionControllers.song,
                      ),
                    ],
                  ),
                  SelectionBottomBar(
                    controller: selectionControllers.album,
                    left: [
                      ActionsSelectionTitle(
                        controller: selectionControllers.album,
                      )
                    ],
                    right: [
                      PlayNextSelectionAction<Album>(
                        controller: selectionControllers.album,
                      ),
                      AddToQueueSelectionAction<Album>(
                        controller: selectionControllers.album,
                      ),
                    ],
                  ),
                  DrawerWidget(
                    canBeOpened: () => drawerCanBeOpened,
                    swipeGesture: () => drawerSwipe,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Screen displayed when songs array is empty and searching is being performed
class _SearchingSongsScreen extends StatelessWidget {
  const _SearchingSongsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return CenterContentScreen(
      text: l10n.searchingForTracks,
      widget: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(
          ThemeControl.theme.colorScheme.onBackground,
        ),
      ),
    );
  }
}

/// Screen displayed when no songs had been found
class _SongsEmptyScreen extends StatefulWidget {
  const _SongsEmptyScreen({Key key}) : super(key: key);

  @override
  _SongsEmptyScreenState createState() => _SongsEmptyScreenState();
}

class _SongsEmptyScreenState extends State<_SongsEmptyScreen> {
  bool _fetching = false;

  Future<void> _handleRefetch() async {
    setState(() {
      _fetching = true;
    });
    await ContentControl.refetchAll();
    if (mounted)
      setState(() {
        _fetching = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return CenterContentScreen(
      text: l10n.noMusic + ' :(',
      widget: ButtonTheme(
        minWidth: 130.0, // specific value
        height: 40.0,
        child: NFButton(
          variant: NFButtonVariant.raised,
          loading: _fetching,
          text: l10n.refresh,
          onPressed: _handleRefetch,
        ),
      ),
    );
  }
}

/// Screen displayed when there are not permissions
class _NoPermissionsScreen extends StatefulWidget {
  const _NoPermissionsScreen({Key key}) : super(key: key);

  @override
  _NoPermissionsScreenState createState() => _NoPermissionsScreenState();
}

class _NoPermissionsScreenState extends State<_NoPermissionsScreen> {
  bool _fetching = false;

  Future<void> _handlePermissionRequest() async {
    if (_fetching)
      return;
    setState(() {
      _fetching = true;
    });
    await Permissions.requestClick();
    if (mounted)
      setState(() {
        _fetching = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return CenterContentScreen(
      text: l10n.allowAccessToExternalStorage,
      widget: ButtonTheme(
        minWidth: 130.0, // specific value
        height: 40.0,
        child: NFButton(
          variant: NFButtonVariant.raised,
          loading: _fetching,
          text: l10n.grant,
          onPressed: _handlePermissionRequest,
        ),
      ),
    );
  }
}
