import 'dart:async';

import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as Constants;

export 'artist_content_route.dart';
export 'artist_route.dart';
export 'persistent_queue_route.dart';
export 'player_route.dart';
export 'search_route.dart';
export 'tabs_route.dart';

class InitialRoute extends StatefulWidget {
  const InitialRoute({Key? key}) : super(key: key);

  @override
  _InitialRouteState createState() => _InitialRouteState();
}

class _InitialRouteState extends State<InitialRoute> {
  bool _onTop = true;

  void _animateNotMainUi() {
    if (_onTop && playerRouteController.value == 0.0) {
      SystemUiStyleController.instance.animateSystemUiOverlay(
        to: Constants.UiTheme.black.auto,
        duration: const Duration(milliseconds: 550),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwareWidget(
      onPushNext: () => _onTop = false,
      onPopNext: () => _onTop = true,
      child: ValueListenableBuilder(
        valueListenable: ContentControl.instance.disposed,
        builder: (context, value, child) {
          if (ContentControl.instance.stateNullable == null) {
            _animateNotMainUi();
            return const _SongsEmptyScreen();
          } else {
            return StreamBuilder(
              stream: ContentControl.instance.onContentChange,
              builder: (context, snapshot) {
                if (Permissions.instance.notGranted) {
                  _animateNotMainUi();
                  return const _NoPermissionsScreen();
                }
                if (ContentControl.instance.initializing) {
                  _animateNotMainUi();
                  return const _SearchingSongsScreen();
                }
                if (ContentControl.instance.state.allSongs.isEmpty) {
                  _animateNotMainUi();
                  return const _SongsEmptyScreen();
                }
                if (ThemeControl.instance.ready && _onTop && playerRouteController.value == 0.0) {
                  SystemUiStyleController.instance.animateSystemUiOverlay(
                    to: Constants.UiTheme.grey.auto,
                  );
                }
                return StreamBuilder<bool>(
                  stream: ThemeControl.instance.themeChaning,
                  builder: (context, snapshot) {
                    if (snapshot.data == true)
                      return const SizedBox.shrink();
                    return const Home();
                  }
                );
              },
            );
          }
        },
      ),
    );
  }
}

/// Main app's content screen.
/// Displayed only there's some content.
class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  static GlobalKey<OverlayState> overlayKey = GlobalKey();
  final router = HomeRouter.main();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: kSongTileHeight),
            child: Router<HomeRoutes>(
              routerDelegate: router,
              routeInformationParser: HomeRouteInformationParser(),
              routeInformationProvider: HomeRouteInformationProvider(),
              backButtonDispatcher: HomeRouteBackButtonDispatcher(
                Router.of(context).backButtonDispatcher!,
              ),
            ),
          ),
          const PlayerRoute(),
          Overlay(key: overlayKey),
          const DrawerWidget(),
        ],
      ),
    );
  }
}

/// Screen displayed when songs array is empty and searching is being performed
class _SearchingSongsScreen extends StatelessWidget {
  const _SearchingSongsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return CenterContentScreen(
      text: l10n.searchingForTracks,
      widget: const Spinner(),
    );
  }
}

/// Screen displayed when no songs had been found
class _SongsEmptyScreen extends StatefulWidget {
  const _SongsEmptyScreen({Key? key}) : super(key: key);

  @override
  _SongsEmptyScreenState createState() => _SongsEmptyScreenState();
}

class _SongsEmptyScreenState extends State<_SongsEmptyScreen> {
  bool _fetching = false;

  Future<void> _handleRefetch() async {
    setState(() {
      _fetching = true;
    });
    await ContentControl.instance.init();
    if (mounted) {
      setState(() {
        _fetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return CenterContentScreen(
      text: l10n.noMusic + ' :(',
      widget: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 40.0,
          minWidth: 130.0,
        ),
        child: AppButton(
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
  const _NoPermissionsScreen({Key? key}) : super(key: key);

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
    await Permissions.instance.requestClick();
    if (mounted) {
      setState(() {
        _fetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = getl10n(context);
    return CenterContentScreen(
      text: l10n.allowAccessToExternalStorage,
      widget: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 40.0,
          minWidth: 130.0,
        ),
        child: AppButton(
          loading: _fetching,
          text: l10n.grant,
          onPressed: _handlePermissionRequest,
        ),
      ),
    );
  }
}
