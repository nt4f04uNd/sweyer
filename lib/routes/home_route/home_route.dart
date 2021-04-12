/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as Constants;

export 'album_route.dart';
export 'player_route.dart';
export 'search_route.dart';
export 'tabs_route.dart';

class InitialRoute extends StatefulWidget {
  const InitialRoute({Key key}) : super(key: key);

  @override
  _InitialRouteState createState() => _InitialRouteState();
}

class _InitialRouteState extends State<InitialRoute> {
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
      onPushNext: () => _onTop = false,
      onPopNext: () => _onTop = true,
      child: StreamBuilder(
        stream: ContentControl.onStateCreateRemove,
        builder: (context, snapshot) {
          if (ContentControl.stateNullable == null) {
            _animateNotMainUi();
            return const _SongsEmptyScreen();
          } else {
            return StreamBuilder(
              stream: ContentControl.state.onContentChange,
              builder: (context, snapshot) {
                if (Permissions.notGranted) {
                  _animateNotMainUi();
                  return const _NoPermissionsScreen();
                }
                if (ContentControl.initializing) {
                  _animateNotMainUi();
                  return const _SearchingSongsScreen();
                }
                if (ContentControl.state == null || ContentControl.state.queues.all.isEmpty) {
                  _animateNotMainUi();
                  return const _SongsEmptyScreen();
                }
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
  const Home({Key key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  static GlobalKey<OverlayState> overlayKey;
  final router = HomeRouter();

  @override
  void initState() { 
    super.initState();
    overlayKey = GlobalKey();
  }

  @override
  void dispose() { 
    overlayKey = null;
    super.dispose();
  }

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
                Router.of(context).backButtonDispatcher,
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
    await ContentControl.init();
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
