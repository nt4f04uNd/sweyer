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
      NFSystemUiControl.animateSystemUiOverlay(
        to: Constants.UiTheme.black.auto,
        settings: NFAnimationControllerSettings(
          duration: const Duration(milliseconds: 550),
        ),
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
            return const LoadingScreen();
          }
          if (Permissions.notGranted) {
            _animateNotMainUi();
            return const _NoPermissionsScreen();
          }
          if (ContentControl.state.queues.all.isNotEmpty &&
              !ContentControl.initFetching) {
            if (ThemeControl.ready &&
                _onTop &&
                playerRouteController.value == 0.0) {
              NFSystemUiControl.animateSystemUiOverlay(
                to: Constants.UiTheme.grey.auto,
              );
            }
            return StreamBuilder<bool>(
                stream: ThemeControl.onThemeChange,
                builder: (context, snapshot) {
                  if (snapshot.data == true) return const SizedBox.shrink();
                  return const MainScreen();
                });
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
  final Map<Type, NFSelectionController<SelectionEntry>> map;

  NFSelectionController<SongSelectionEntry> get song => map[Song];
  NFSelectionController<AlbumSelectionEntry> get album => map[Album];

  static SelectionControllers of(BuildContext context) {
    return context
        .getElementForInheritedWidgetOfExactType<SelectionControllers>()
        .widget;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

/// Main app route with song and album list tabs
class MainScreen extends StatefulWidget {
  const MainScreen({Key key}) : super(key: key);
  static bool get shown =>
      ContentControl.playReady &&
      !Permissions.notGranted &&
      ContentControl.state.queues.all.isNotEmpty;

  static bool _albumRouteOpened = false;

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with
        TickerProviderStateMixin,
        DrawerControllerMixin,
        PlayerRouteControllerMixin {
  static const int _tabsLength = 2;

  Map<Type, NFSelectionController<SelectionEntry>> selectionControllersMap;
  TabController tabController;
  SlidableController playerRouteController;
  SlidableController drawerController;

  bool get drawerCanBeOpened =>
      playerRouteController.closed &&
      selectionControllersMap.values.every((el) => el.notInSelection) &&
      !MainScreen._albumRouteOpened;

  /// Whether the drawer swipe is enabled.
  bool get drawerSwipe => tabController.animation.value == 0.0;

  @override
  void initState() {
    super.initState();

    selectionControllersMap = {
      Song: NFSelectionController<SongSelectionEntry>(
        animationController: AnimationController(
          vsync: this,
          duration: kSelectionDuration,
        ),
      ),
      Album: NFSelectionController<AlbumSelectionEntry>(
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
    for (final controller in selectionControllersMap.values) {
      controller.dispose();
    }
    tabController.dispose();
    super.dispose();
  }

  // Var to show exit toast
  DateTime _lastBackPressTime;
  Future<bool> _handlePop(BuildContext context) async {
    if (playerRouteController.opened) {
      playerRouteController.close();
      return Future.value(false);
    } else if (drawerController.opened) {
      drawerController.close();
      return Future.value(false);
    } else if (selectionControllersMap.values.any((el) => el.inSelection)) {
      for (final controller in selectionControllersMap.values) {
        controller.close();
      }
      return Future.value(false);
    } else if (App.homeNavigatorKey.currentState != null &&
        App.homeNavigatorKey.currentState.canPop()) {
      App.homeNavigatorKey.currentState.pop();
      return Future.value(false);
    } else {
      DateTime now = DateTime.now();
      // Show toast when user presses back button on main route, that asks from user to press again to confirm that he wants to quit the app
      if (_lastBackPressTime == null ||
          now.difference(_lastBackPressTime) > Duration(seconds: 2)) {
        _lastBackPressTime = now;
        ShowFunctions.instance.showToast(
          msg: getl10n(context).pressOnceAgainToExit,
        );
        return Future.value(false);
      }
      return Future.value(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectionControllers(
      map: selectionControllersMap,
      child: Builder(
        builder: (context) {
          final selectionControllers = SelectionControllers.of(context);
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: WillPopScope(
              onWillPop: () => _handlePop(context),
              child: Stack(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: kSongTileHeight),
                    child: Navigator(
                      key: App.homeNavigatorKey,
                      observers: [homeRouteObserver],
                      initialRoute: Constants.HomeRoutes.tabs.value,
                      onGenerateInitialRoutes: (state, name) => [
                        StackFadeRouteTransition(
                          transitionSettings: StackFadeRouteTransitionSettings(
                            checkEntAnimationEnabled: () => false,
                            maintainState: true,
                            checkSystemUi: () => Constants.UiTheme.grey.auto,
                            settings: RouteSettings(
                              name: name,
                            ),
                          ),
                          route: TabsRoute(
                            tabController: tabController,
                          ),
                        ),
                      ],
                      onUnknownRoute: RouteControl.handleOnUnknownRoute,
                      onGenerateRoute: (settings) {
                        if (settings.name == Constants.HomeRoutes.album.value) {
                          return StackFadeRouteTransition(
                            transitionSettings:
                                StackFadeRouteTransitionSettings(
                              opaque: false,
                              dismissible: true,
                              checkSystemUi: () => Constants.UiTheme.grey.auto,
                              dismissBarrier: RouteControl.barrier,
                              settings: settings,
                            ),
                            route: RouteAwareWidget(
                              onPop: () {
                                MainScreen._albumRouteOpened = false;
                              },
                              onPush: () {
                                MainScreen._albumRouteOpened = true;
                              },
                              child: AlbumRoute(
                                album: settings.arguments,
                              ),
                            ),
                          );
                        }
                        if (settings.name ==
                            Constants.HomeRoutes.search.value) {
                          return (settings.arguments as Route);
                        }
                        return null;
                      },
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
                      PlayNextSelectionAction<SongSelectionEntry>(
                        controller: selectionControllers.song,
                      ),
                      AddToQueueSelectionAction<SongSelectionEntry>(
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
                      PlayNextSelectionAction<AlbumSelectionEntry>(
                        controller: selectionControllers.album,
                      ),
                      AddToQueueSelectionAction<AlbumSelectionEntry>(
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
