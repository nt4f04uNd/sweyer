/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as Constants;

class InitialRoute extends StatefulWidget {
  @override
  InitialRouteState createState() => InitialRouteState();
}

class InitialRouteState extends State<InitialRoute> {
  @override
  void initState() {
    super.initState();
    LaunchControl.init();
    // LaunchControl.afterAppMount();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ContentControl.state.onPlaylistListChange,
      builder: (context, snapshot) {
        return !ContentControl.playReady
            ? LoadingScreen()
            : Permissions.notGranted
                ? _NoPermissionsScreen()
                : ContentControl.state.getPlaylist(PlaylistType.global).isEmpty
                    ? ContentControl.initFetching
                        ? _SearchingSongsScreen()
                        : _SongsEmptyScreen()
                    : MainScreen();
      },
    );
  }
}

/// Main app route with song and album list tabs
class MainScreen extends StatefulWidget {
  MainScreen({Key key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  SelectionController selectionController;
  TabController _tabController;

  StreamSubscription<void> _playlistChangeSubscription;
  StreamSubscription<Song> _songChangeSubscription;

  // Var to show exit toast
  DateTime _lastBackPressTime;

  final _tabs = [
    SMMTab(text: "Песни"),
    SMMTab(text: "Альбомы"),
  ];

  @override
  void initState() {
    super.initState();

    selectionController = SelectionController<int>(
      selectionSet: {},
      switcher: IntSwitcher(),
      animationController:
          AnimationController(vsync: this, duration: kSMMSelectionDuration),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        setState(() {});
      });

    _tabController =
        _tabController = TabController(vsync: this, length: _tabs.length);

    _playlistChangeSubscription =
        ContentControl.state.onPlaylistListChange.listen((event) {
      // Update list on playlist changes
      selectionController.switcher.change();
      // Don't call set state because this screen shouldn't appear before songs list is empty
    });
    _songChangeSubscription = ContentControl.state.onSongChange.listen((event) {
      // Needed to update current track indicator
      setState(() {});
    });
  }

  @override
  void dispose() {
    _playlistChangeSubscription.cancel();
    _songChangeSubscription.cancel();
    selectionController.dispose();
    super.dispose();
  }

  void _handleDelete() {
    ShowFunctions.showDialog(
      context,
      title: const Text("Удаление"),
      content: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 15.0),
          children: [
            TextSpan(text: "Вы уверены, что хотите удалить "),
            TextSpan(
              text: selectionController.selectionSet.length == 1
                  ? ContentControl.state
                      .getPlaylist(PlaylistType.global)
                      .getSongById(selectionController.selectionSet.first)
                      .title
                  : "${selectionController.selectionSet.length} треков",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: " ?"),
          ],
        ),
      ),
      acceptButton: DialogRaisedButton(
        text: "Удалить",
        onPressed: () {
          selectionController.close();
          ContentControl.deleteSongs(selectionController.selectionSet);
        },
      ),
    );
  }

  Future<bool> _handlePop(BuildContext context) async {
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
      return Future.value(false);
    } else if (selectionController.inSelection) {
      selectionController.close();
      return Future.value(false);
    } else {
      DateTime now = DateTime.now();
      // Show toast when user presses back button on main route, that asks from user to press again to confirm that he wants to quit the app
      if (_lastBackPressTime == null ||
          now.difference(_lastBackPressTime) > Duration(seconds: 2)) {
        _lastBackPressTime = now;
        ShowFunctions.showToast(msg: "Нажмите еще раз для выхода");
        return Future.value(false);
      }
      return Future.value(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseAnimation = SMMDefaultAnimation(
      parent: selectionController.animationController,
    );
    // final tapBarSlideAnimation = Tween(
    //   begin: const Offset(0.0, 0.0),
    //   end: const Offset(0.0, -0.8),
    // ).animate(baseAnimation);

    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kSMMAppBarPreferredSize),
        child: SelectionAppBar(
          titleSpacing: 0.0,
          elevation: 0.0,
          elevationSelection: 0.0,
          selectionController: selectionController,
          actions: [
            SMMIconButton(
              color: Theme.of(context).colorScheme.onSurface,
              icon: const Icon(Icons.search),
              onPressed: () {
                ShowFunctions.showSongsSearch(context);
              },
            ),
            SMMIconButton(
              icon: const Icon(Icons.sort),
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () => ShowFunctions.showSongsSortModal(context),
            ),
          ],
          actionsSelection: [
            SizedBox.fromSize(
                size: const Size(kSMMIconButtonSize, kSMMIconButtonSize)),
            SMMIconButton(
              color: Theme.of(context).colorScheme.onSurface,
              icon: const Icon(Icons.delete_outline),
              onPressed: _handleDelete,
            ),
          ],
          // center: FakeSearchInputBox(),
          title: Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Text(
              Constants.Config.APPLICATION_TITLE,
              style:   TextStyle(
          fontWeight: FontWeight.w700,
          color:  Theme.of(context).textTheme.headline6.color,
          fontSize: 22.0,
        )
              
              // Theme.of(context).textTheme.headline5,
              // TextStyle(
              //   color:  Constants.AppTheme.menuItem.auto(context),
              //   // color: Theme.of(context).colorScheme.onBackground,
              //   // color: const Color(0xff343434),
              //   fontSize: 22.0,
              //   fontWeight: FontWeight.w700,
              // ),
            ),
          ),
          titleSelection: Transform.translate(
            offset: const Offset(0, -1.1),
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0, top: 4.1),
              child: CountSwitcher(
                // Not letting to go less 1 to not play animation from 1 to 0
                childKey: ValueKey(selectionController.selectionSet.length > 0
                    ? selectionController.selectionSet.length
                    : 1),
                valueIncreased: selectionController.lengthIncreased,
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text(
                    (selectionController.selectionSet.length > 0
                            ? selectionController.selectionSet.length
                            : 1)
                        .toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Builder(
        builder: (context) => WillPopScope(
          onWillPop: () => _handlePop(context),
          child: Stack(
            children: <Widget>[
              ScrollConfiguration(
                behavior: SMMScrollBehaviorGlowless(),
                child: AnimatedBuilder(
                  animation: baseAnimation,
                  child: TabBarView(
                    controller: _tabController,
                    physics: selectionController.inSelection
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    children: <Widget>[
                      SongsListTab(
                        selectionController: selectionController,
                      ),
                      AlbumListTab(),
                    ],
                  ),
                  builder: (BuildContext context, Widget child) => Padding(
                    padding: EdgeInsets.only(
                        top: 44.0
                        // * (1 - baseAnimation.value)
                        ,
                        bottom: 34.0),
                    child: child,
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: selectionController.inSelection,
                child:
                    // FadeTransition(
                    //   opacity: ReverseAnimation(baseAnimation),
                    //   child:
                    // SlideTransition(
                    //   position: tapBarSlideAnimation,
                    // child:
                    Theme(
                  data: Theme.of(context).copyWith(
                    splashFactory: ListTileInkRipple.splashFactory,
                  ),
                  child: Material(
                    elevation: 2.0,
                    color: Theme.of(context).appBarTheme.color,
                    child: SMMTabBar(
                      controller: _tabController,
                      indicatorWeight: 5.0,
                      indicator: BoxDecoration(
                        // color: Theme.of(context).textTheme.headline6.color,
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: const Radius.circular(3.0),
                          topRight: const Radius.circular(3.0),
                        ),
                      ),
                      labelColor: Theme.of(context).textTheme.headline6.color,
                      indicatorSize: TabBarIndicatorSize.label,
                      unselectedLabelColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      labelStyle: Theme.of(context)
                          .textTheme
                          .headline6
                          .copyWith(
                              fontSize: 15.0, fontWeight: FontWeight.w900),
                      tabs: _tabs,
                    ),
                  ),
                ),
              ),
              // ),
              // ),
              BottomTrackPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen displayed when songs array is empty and searching is being performed
class _SearchingSongsScreen extends StatelessWidget {
  const _SearchingSongsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Ищем треки...',
                textAlign: TextAlign.center,
              ),
            ),
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
            ),
          ],
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
  Future<void> _refetchHandler() async {
    return await ContentControl.refetchSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'На вашем устройстве нету музыки :( ',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: ButtonTheme(
              minWidth: 130.0, // specific value
              height: 40.0,
              child: PrimaryRaisedButton(
                loading: _fetching,
                text: "Обновить",
                onPressed: () async {
                  setState(() {
                    _fetching = true;
                  });
                  await _refetchHandler();
                  setState(() {
                    _fetching = false;
                  });
                },
              ),
            ),
          )
        ],
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
    if (mounted)
      setState(() {
        _fetching = true;
      });
    else
      _fetching = true;

    await Permissions.requestClick();

    if (mounted)
      setState(() {
        _fetching = false;
      });
    else
      _fetching = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Пожалуйста, предоставьте доступ к хранилищу',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: ButtonTheme(
              minWidth: 130.0, // specific value
              height: 40.0,
              child: PrimaryRaisedButton(
                loading: _fetching,
                text: "Предоставить",
                onPressed: _handlePermissionRequest,
              ),
            ),
          )
        ],
      ),
    );
  }
}
